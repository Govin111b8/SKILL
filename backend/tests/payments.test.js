const request = require('supertest');
const express = require('express');
const jwt = require('jsonwebtoken');
const paymentRoutes = require('../src/routes/payments');
const errorHandler = require('../src/middleware/errorHandler');
const { query, pool } = require('../src/config/database');

jest.mock('../src/config/database', () => ({
  query: jest.fn(),
  pool: { end: jest.fn(), query: jest.fn() },
}));

const app = express();
app.use(express.json());
app.use('/api/payments', paymentRoutes);
app.use(errorHandler);

process.env.JWT_SECRET = 'test-secret';

const generateTestToken = (user) => jwt.sign(user, process.env.JWT_SECRET, { expiresIn: '1h' });
const authHeader = (token) => ['Bearer', token].join(' ');
const customerToken = generateTestToken({ id: 'cust-uuid', role: 'customer', email: 'cust@example.com' });
const professionalToken = generateTestToken({ id: 'pro-user-uuid', role: 'professional', email: 'pro@example.com' });
const bookingId = '550e8400-e29b-41d4-a716-446655440000';

describe('Payments Endpoints', () => {
  beforeEach(() => {
    query.mockReset();
    pool.query.mockReset();
  });

  describe('POST /api/payments', () => {
    it('should create a COD payment', async () => {
      pool.query.mockResolvedValueOnce({
        rows: [{ id: bookingId, status: 'quoted', quoted_amount: 1500, final_amount: null, pro_user_id: 'pro-user-uuid' }],
      });
      pool.query.mockResolvedValueOnce({
        rows: [{ id: 'payment-1', booking_id: bookingId, method: 'cod', status: 'cod_pending', amount: 1500 }],
      });
      pool.query.mockResolvedValueOnce({ rows: [] });

      const res = await request(app)
        .post('/api/payments')
        .set('Authorization', authHeader(customerToken))
        .send({ booking_id: bookingId, method: 'cod' });

      expect(res.status).toBe(201);
      expect(res.body.payment_method).toBe('cod');
      expect(res.body.payment.status).toBe('cod_pending');
    });

    it('should reject an invalid booking id', async () => {
      const res = await request(app)
        .post('/api/payments')
        .set('Authorization', authHeader(customerToken))
        .send({ booking_id: 'bad-id', method: 'cod' });

      expect(res.status).toBe(400);
      expect(res.body.error).toContain('booking_id');
      expect(pool.query).not.toHaveBeenCalled();
    });

    it('should return 404 when the booking is not found', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] });

      const res = await request(app)
        .post('/api/payments')
        .set('Authorization', authHeader(customerToken))
        .send({ booking_id: bookingId, method: 'cod' });

      expect(res.status).toBe(404);
      expect(res.body.error).toContain('Booking not found');
    });

    it('should reject bookings that are not payable', async () => {
      pool.query.mockResolvedValueOnce({
        rows: [{ id: bookingId, status: 'requested', quoted_amount: 1500, pro_user_id: 'pro-user-uuid' }],
      });

      const res = await request(app)
        .post('/api/payments')
        .set('Authorization', authHeader(customerToken))
        .send({ booking_id: bookingId, method: 'cod' });

      expect(res.status).toBe(400);
      expect(res.body.error).toContain('payable state');
    });
  });

  describe('GET /api/payments', () => {
    it('should list payments with totals', async () => {
      pool.query.mockResolvedValueOnce({
        rows: [{ id: 'payment-1', booking_title: 'AC service', booking_status: 'completed', status: 'released' }],
      });
      pool.query.mockResolvedValueOnce({
        rows: [{ total_earned: '1000', pending_earnings: '500', total_spent: '2000' }],
      });

      const res = await request(app)
        .get('/api/payments')
        .query({ status: 'released', page: 2, limit: 1 })
        .set('Authorization', authHeader(customerToken));

      expect(res.status).toBe(200);
      expect(res.body.payments).toHaveLength(1);
      expect(res.body.totals.total_spent).toBe('2000');
      expect(res.body.page).toBe(2);
      expect(res.body.limit).toBe(1);
    });
  });

  describe('GET /api/payments/earnings', () => {
    it('should return professional earnings summary', async () => {
      pool.query.mockResolvedValueOnce({
        rows: [{ total_earned: '4500', pending: '1200', last_7_days: '800', this_month: '2300', completed_payments: '6' }],
      });
      pool.query.mockResolvedValueOnce({
        rows: [{ month: '2026-05-01T00:00:00.000Z', earned: '2300', jobs: '3' }],
      });

      const res = await request(app)
        .get('/api/payments/earnings')
        .set('Authorization', authHeader(professionalToken));

      expect(res.status).toBe(200);
      expect(res.body.summary.total_earned).toBe('4500');
      expect(res.body.monthly).toHaveLength(1);
    });
  });

  it('should require authentication for payment history', async () => {
    const res = await request(app).get('/api/payments');
    expect(res.status).toBe(401);
  });
});
