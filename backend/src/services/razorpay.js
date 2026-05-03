/**
 * Razorpay Payment Gateway Integration
 * Handles order creation, payment verification, refunds, and webhooks.
 *
 * Required env vars:
 *   RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET, RAZORPAY_WEBHOOK_SECRET
 */

const crypto = require('crypto');
const logger = require('../config/logger');

const KEY_ID = process.env.RAZORPAY_KEY_ID || '';
const KEY_SECRET = process.env.RAZORPAY_KEY_SECRET || '';
const WEBHOOK_SECRET = process.env.RAZORPAY_WEBHOOK_SECRET || '';

// Base URL for Razorpay API
const BASE_URL = 'https://api.razorpay.com/v1';

function getAuthHeader() {
  return 'Basic ' + Buffer.from(`${KEY_ID}:${KEY_SECRET}`).toString('base64');
}

async function apiRequest(method, endpoint, body = null) {
  const url = `${BASE_URL}${endpoint}`;
  const options = {
    method,
    headers: {
      'Authorization': getAuthHeader(),
      'Content-Type': 'application/json',
    },
  };
  if (body) options.body = JSON.stringify(body);

  const response = await fetch(url, options);
  const data = await response.json();

  if (!response.ok) {
    logger.error({ status: response.status, data, endpoint }, 'Razorpay API error');
    const err = new Error(data.error?.description || 'Razorpay API error');
    err.statusCode = response.status;
    err.razorpayError = data.error;
    throw err;
  }
  return data;
}

/**
 * Create a Razorpay Order (used before payment capture on frontend)
 * @param {object} params - { amount (in paise), currency, receipt, notes }
 * @returns {object} Razorpay order object
 */
async function createOrder({ amount, currency = 'INR', receipt, notes = {} }) {
  if (!KEY_ID || !KEY_SECRET) {
    logger.warn('Razorpay keys not configured — returning simulated order');
    return {
      id: `order_sim_${Date.now()}`,
      amount,
      currency,
      receipt,
      status: 'created',
      simulated: true,
    };
  }

  return apiRequest('POST', '/orders', {
    amount: Math.round(amount * 100), // Convert rupees to paise
    currency,
    receipt,
    notes,
  });
}

/**
 * Verify payment signature after frontend captures payment
 * @param {object} params - { razorpay_order_id, razorpay_payment_id, razorpay_signature }
 * @returns {boolean}
 */
function verifyPaymentSignature({ razorpay_order_id, razorpay_payment_id, razorpay_signature }) {
  if (!KEY_SECRET) return true; // Simulated mode

  const expectedSignature = crypto
    .createHmac('sha256', KEY_SECRET)
    .update(`${razorpay_order_id}|${razorpay_payment_id}`)
    .digest('hex');

  return expectedSignature === razorpay_signature;
}

/**
 * Fetch payment details from Razorpay
 * @param {string} paymentId - Razorpay payment ID
 */
async function fetchPayment(paymentId) {
  return apiRequest('GET', `/payments/${paymentId}`);
}

/**
 * Initiate a refund
 * @param {string} paymentId - Razorpay payment ID
 * @param {object} params - { amount (paise), notes, speed }
 */
async function initiateRefund(paymentId, { amount, notes = {}, speed = 'normal' } = {}) {
  if (!KEY_ID || !KEY_SECRET) {
    logger.warn('Razorpay keys not configured — returning simulated refund');
    return {
      id: `rfnd_sim_${Date.now()}`,
      payment_id: paymentId,
      amount,
      status: 'processed',
      simulated: true,
    };
  }

  const body = { speed, notes };
  if (amount) body.amount = Math.round(amount * 100);
  return apiRequest('POST', `/payments/${paymentId}/refund`, body);
}

/**
 * Verify webhook signature
 * @param {string} rawBody - Raw request body string
 * @param {string} signature - X-Razorpay-Signature header
 * @returns {boolean}
 */
function verifyWebhookSignature(rawBody, signature) {
  if (!WEBHOOK_SECRET) return true; // Dev mode

  const expectedSignature = crypto
    .createHmac('sha256', WEBHOOK_SECRET)
    .update(rawBody)
    .digest('hex');

  return expectedSignature === signature;
}

/**
 * Create a transfer (for releasing payment to professional's account)
 * @param {string} paymentId
 * @param {object} params - { account (linked account ID), amount (paise) }
 */
async function createTransfer(paymentId, { account, amount }) {
  if (!KEY_ID || !KEY_SECRET) {
    return { id: `trf_sim_${Date.now()}`, simulated: true };
  }

  return apiRequest('POST', `/payments/${paymentId}/transfers`, {
    transfers: [{
      account,
      amount: Math.round(amount * 100),
      currency: 'INR',
    }],
  });
}

module.exports = {
  createOrder,
  verifyPaymentSignature,
  fetchPayment,
  initiateRefund,
  verifyWebhookSignature,
  createTransfer,
  KEY_ID, // Exported so frontend can use it for checkout
};
