const { pool } = require('../config/database');
const razorpay = require('../services/razorpay');
const emailService = require('../services/email');
const logger = require('../config/logger');

// Create a payment (Razorpay order + escrow hold)
async function createPayment(req, res, next) {
  try {
    const { booking_id, method } = req.body;
    const payer_id = req.user.id;

    const uuidV4Regex = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    if (!booking_id || !uuidV4Regex.test(booking_id)) {
      return res.status(400).json({ error: 'A valid booking_id (UUID v4) is required' });
    }
    const validMethods = ['card', 'upi', 'netbanking', 'wallet', 'cod', 'emi'];
    if (method && !validMethods.includes(method)) {
      return res.status(400).json({ error: `method must be one of: ${validMethods.join(', ')}` });
    }

    // Get booking details
    const bookingRes = await pool.query(
      `SELECT b.*, p.user_id as pro_user_id 
       FROM bookings b 
       JOIN professionals p ON b.professional_id = p.id 
       WHERE b.id = $1 AND b.customer_id = $2`,
      [booking_id, payer_id]
    );

    if (bookingRes.rows.length === 0) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    const booking = bookingRes.rows[0];

    if (!['quoted', 'accepted'].includes(booking.status)) {
      return res.status(400).json({ error: 'Booking is not in a payable state' });
    }

    const amount = booking.quoted_amount || booking.final_amount;
    if (!amount) {
      return res.status(400).json({ error: 'No amount set for this booking' });
    }

    const platformFee = Math.round(amount * 0.05 * 100) / 100; // 5% platform fee
    const taxAmount = Math.round(platformFee * 0.18 * 100) / 100; // 18% GST on fee
    const transactionRef = `TXN_${Date.now()}_${require('crypto').randomBytes(8).toString('hex')}`;

    // Cash-on-delivery: record payment without Razorpay order, collect at service time
    if (method === 'cod') {
      const result = await pool.query(
        `INSERT INTO payments (booking_id, payer_id, payee_id, amount, platform_fee, tax_amount, currency, method, status, transaction_ref, metadata)
         VALUES ($1, $2, $3, $4, $5, $6, 'INR', 'cod', 'cod_pending', $7, $8)
         RETURNING *`,
        [booking_id, payer_id, booking.pro_user_id, amount, platformFee, taxAmount, transactionRef,
         JSON.stringify({ cod_note: 'Customer will pay cash at service time' })]
      );
      await pool.query(
        `UPDATE bookings SET status = 'accepted', updated_at = NOW() WHERE id = $1 AND status = 'quoted'`,
        [booking_id]
      );
      logger.info({ paymentId: result.rows[0].id }, 'COD payment recorded');
      return res.status(201).json({ payment: result.rows[0], payment_method: 'cod' });
    }

    // EMI via Razorpay: create order with EMI options
    if (method === 'emi') {
      const { emi_duration } = req.body;
      const order = await razorpay.createEMIOrder({
        amount: parseFloat(amount),
        currency: 'INR',
        receipt: `booking_${booking_id}`,
        notes: { booking_id, payer_id },
      });
      const result = await pool.query(
        `INSERT INTO payments (booking_id, payer_id, payee_id, amount, platform_fee, tax_amount, currency, method, status, transaction_ref, metadata)
         VALUES ($1, $2, $3, $4, $5, $6, 'INR', 'emi', 'pending', $7, $8)
         RETURNING *`,
        [booking_id, payer_id, booking.pro_user_id, amount, platformFee, taxAmount, transactionRef,
         JSON.stringify({ razorpay_order_id: order.id, emi_duration: emi_duration || null })]
      );
      return res.status(201).json({
        payment: result.rows[0],
        razorpay_order: { id: order.id, amount: order.amount, currency: order.currency, key_id: razorpay.KEY_ID },
        emi_options: razorpay.EMI_DURATIONS,
      });
    }

    // Standard Razorpay payment (card, upi, netbanking, wallet)
    const order = await razorpay.createOrder({
      amount: parseFloat(amount),
      currency: 'INR',
      receipt: `booking_${booking_id}`,
      notes: { booking_id, payer_id },
    });

    const result = await pool.query(
      `INSERT INTO payments (booking_id, payer_id, payee_id, amount, platform_fee, tax_amount, currency, method, status, transaction_ref, metadata)
       VALUES ($1, $2, $3, $4, $5, $6, 'INR', $7, 'pending', $8, $9)
       RETURNING *`,
      [booking_id, payer_id, booking.pro_user_id, amount, platformFee, taxAmount, method, transactionRef,
       JSON.stringify({ razorpay_order_id: order.id })]
    );

    res.status(201).json({
      payment: result.rows[0],
      razorpay_order: {
        id: order.id,
        amount: order.amount,
        currency: order.currency,
        key_id: razorpay.KEY_ID,
      },
    });
  } catch (err) {
    next(err);
  }
}

// Verify and confirm payment after frontend capture
async function verifyPayment(req, res, next) {
  try {
    const { payment_id } = req.params;
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;

    // Verify signature
    const isValid = razorpay.verifyPaymentSignature({
      razorpay_order_id,
      razorpay_payment_id,
      razorpay_signature,
    });

    if (!isValid) {
      return res.status(400).json({ error: 'Payment verification failed — invalid signature' });
    }

    // Update payment status to escrow
    const result = await pool.query(
      `UPDATE payments SET status = 'held_in_escrow', transaction_ref = $2,
       metadata = metadata || $3::jsonb, updated_at = NOW()
       WHERE id = $1 RETURNING *`,
      [payment_id, razorpay_payment_id,
       JSON.stringify({ razorpay_payment_id, verified_at: new Date().toISOString() })]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Payment not found' });
    }

    const payment = result.rows[0];

    // Transition booking to accepted
    await pool.query(
      `UPDATE bookings SET status = 'accepted', updated_at = NOW() WHERE id = $1 AND status = 'quoted'`,
      [payment.booking_id]
    );
    await pool.query(
      `INSERT INTO booking_status_log (booking_id, from_status, to_status, actor_id, note) VALUES ($1, 'quoted', 'accepted', $2, 'Payment held in escrow')`,
      [payment.booking_id, req.user.id]
    );

    // Send receipt email
    const userRes = await pool.query('SELECT email FROM users WHERE id = $1', [req.user.id]);
    if (userRes.rows.length > 0) {
      emailService.sendPaymentReceipt(userRes.rows[0].email, payment).catch((err) => logger.error({ err, paymentId: payment.id }, 'Failed to send payment receipt email'));
    }

    logger.info({ paymentId: payment.id }, 'Payment verified and held in escrow');
    res.json({ payment: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

// Release escrow (when job is completed)
async function releaseEscrow(req, res, next) {
  try {
    const { payment_id } = req.params;

    const paymentRes = await pool.query(
      `SELECT p.*, b.customer_id, b.professional_id, b.status as booking_status,
              (SELECT COUNT(*) FROM disputes d WHERE d.booking_id = b.id AND d.status NOT IN ('resolved', 'closed', 'dismissed')) as active_disputes
       FROM payments p
       JOIN bookings b ON p.booking_id = b.id
       WHERE p.id = $1`,
      [payment_id]
    );

    if (paymentRes.rows.length === 0) {
      return res.status(404).json({ error: 'Payment not found' });
    }

    const payment = paymentRes.rows[0];

    if (payment.status !== 'held_in_escrow') {
      return res.status(400).json({ error: 'Payment is not in escrow' });
    }

    if (payment.booking_status !== 'completed') {
      return res.status(400).json({ error: 'Booking must be completed before releasing payment' });
    }

    if (parseInt(payment.active_disputes, 10) > 0) {
      return res.status(400).json({ error: 'Cannot release payment while there is an active dispute' });
    }

    const result = await pool.query(
      `UPDATE payments SET status = 'released', escrow_released_at = NOW(), updated_at = NOW() WHERE id = $1 RETURNING *`,
      [payment_id]
    );

    res.json({ payment: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

// Confirm COD payment (professional marks cash collected)
async function confirmCOD(req, res, next) {
  try {
    const { payment_id } = req.params;

    const paymentRes = await pool.query(
      `SELECT p.*, b.professional_id, pro.user_id as pro_user_id
       FROM payments p
       JOIN bookings b ON p.booking_id = b.id
       JOIN professionals pro ON b.professional_id = pro.id
       WHERE p.id = $1 AND p.method = 'cod' AND p.status = 'cod_pending'`,
      [payment_id]
    );

    if (paymentRes.rows.length === 0) {
      return res.status(404).json({ error: 'COD payment not found or already confirmed' });
    }

    const payment = paymentRes.rows[0];

    if (payment.pro_user_id !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Only the assigned professional can confirm cash collection' });
    }

    const result = await pool.query(
      `UPDATE payments SET status = 'released', escrow_released_at = NOW(),
       metadata = metadata || $2::jsonb, updated_at = NOW()
       WHERE id = $1 RETURNING *`,
      [payment_id, JSON.stringify({ cod_confirmed_at: new Date().toISOString(), confirmed_by: req.user.id })]
    );

    logger.info({ paymentId: payment_id }, 'COD payment confirmed by professional');
    res.json({ payment: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

// Refund payment
async function refundPayment(req, res, next) {
  try {
    const { payment_id } = req.params;
    const { reason } = req.body;

    const result = await pool.query(
      `UPDATE payments SET status = 'refunded', refund_reason = $2, updated_at = NOW() WHERE id = $1 AND status IN ('held_in_escrow', 'pending') RETURNING *`,
      [payment_id, reason]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Payment not found or not refundable' });
    }

    res.json({ payment: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

// Get payment history for current user
async function getPayments(req, res, next) {
  try {
    const userId = req.user.id;
    const { status, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    let query = `SELECT p.*, b.title as booking_title, b.status as booking_status
                 FROM payments p
                 JOIN bookings b ON p.booking_id = b.id
                 WHERE (p.payer_id = $1 OR p.payee_id = $1)`;
    const params = [userId];

    if (status) {
      params.push(status);
      query += ` AND p.status = $${params.length}`;
    }

    query += ` ORDER BY p.created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(limit, offset);

    const result = await pool.query(query, params);

    // Get totals
    const totalsRes = await pool.query(
      `SELECT 
        COALESCE(SUM(CASE WHEN status = 'released' AND payee_id = $1 THEN amount END), 0) as total_earned,
        COALESCE(SUM(CASE WHEN status = 'held_in_escrow' AND payee_id = $1 THEN amount END), 0) as pending_earnings,
        COALESCE(SUM(CASE WHEN status = 'released' AND payer_id = $1 THEN amount END), 0) as total_spent
       FROM payments WHERE payer_id = $1 OR payee_id = $1`,
      [userId]
    );

    res.json({
      payments: result.rows,
      totals: totalsRes.rows[0],
      page: Number(page),
      limit: Number(limit)
    });
  } catch (err) {
    next(err);
  }
}

// Get earnings summary for professional
async function getEarnings(req, res, next) {
  try {
    const userId = req.user.id;

    const earnings = await pool.query(
      `SELECT 
        COALESCE(SUM(CASE WHEN status = 'released' THEN amount - platform_fee END), 0) as total_earned,
        COALESCE(SUM(CASE WHEN status = 'held_in_escrow' THEN amount - platform_fee END), 0) as pending,
        COALESCE(SUM(CASE WHEN status = 'released' AND escrow_released_at >= NOW() - INTERVAL '7 days' THEN amount - platform_fee END), 0) as last_7_days,
        COALESCE(SUM(CASE WHEN status = 'released' AND escrow_released_at >= DATE_TRUNC('month', NOW()) THEN amount - platform_fee END), 0) as this_month,
        COUNT(CASE WHEN status = 'released' END) as completed_payments
       FROM payments WHERE payee_id = $1`,
      [userId]
    );

    // Monthly breakdown for last 6 months
    const monthly = await pool.query(
      `SELECT 
        DATE_TRUNC('month', escrow_released_at) as month,
        SUM(amount - platform_fee) as earned,
        COUNT(*) as jobs
       FROM payments 
       WHERE payee_id = $1 AND status = 'released' AND escrow_released_at >= NOW() - INTERVAL '6 months'
       GROUP BY DATE_TRUNC('month', escrow_released_at)
       ORDER BY month DESC`,
      [userId]
    );

    res.json({
      summary: earnings.rows[0],
      monthly: monthly.rows
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { createPayment, verifyPayment, releaseEscrow, confirmCOD, refundPayment, getPayments, getEarnings };
