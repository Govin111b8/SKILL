const request = require('supertest');
const express = require('express');
const jwt = require('jsonwebtoken');
const serviceRoutes = require('../src/routes/services');
const errorHandler = require('../src/middleware/errorHandler');
const { query, pool } = require('../src/config/database');

jest.mock('../src/config/database', () => ({
  query: jest.fn(),
  pool: { end: jest.fn(), query: jest.fn() },
}));

const app = express();
app.use(express.json());
app.use('/api/services', serviceRoutes);
app.use(errorHandler);

process.env.JWT_SECRET = 'test-secret';

const generateTestToken = (user) => jwt.sign(user, process.env.JWT_SECRET, { expiresIn: '1h' });
const authHeader = (token) => ['Bearer', token].join(' ');
const proToken = generateTestToken({ id: 'pro-user-1', role: 'professional', email: 'pro@example.com' });

describe('Service Endpoints', () => {
  beforeEach(() => {
    query.mockReset();
    pool.query.mockReset();
  });

  it('should list active services for a professional', async () => {
    query.mockResolvedValueOnce({
      rows: [{ id: 'service-1', professional_id: 'prof-1', name: 'AC Repair', category_name: 'Home Services' }],
    });

    const res = await request(app).get('/api/services/prof-1');

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].name).toBe('AC Repair');
  });

  it('should add a service for the authenticated professional via /me', async () => {
    query.mockResolvedValueOnce({ rows: [{ id: 'prof-1' }] });
    query.mockResolvedValueOnce({ rows: [{ id: 'prof-1' }] });
    query.mockResolvedValueOnce({
      rows: [{ id: 'service-1', professional_id: 'prof-1', name: 'Deep Cleaning', pricing_type: 'fixed' }],
    });

    const res = await request(app)
      .post('/api/services/me')
      .set('Authorization', authHeader(proToken))
      .send({ name: 'Deep Cleaning', price_min: 800, duration_minutes: 90, pricing_type: 'fixed' });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.name).toBe('Deep Cleaning');
  });

  it('should return 404 when adding a service without a professional profile', async () => {
    query.mockResolvedValueOnce({ rows: [] });

    const res = await request(app)
      .post('/api/services/me')
      .set('Authorization', authHeader(proToken))
      .send({ name: 'Deep Cleaning' });

    expect(res.status).toBe(404);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toContain('Professional profile not found');
  });

  it('should validate service details before insert', async () => {
    query.mockResolvedValueOnce({ rows: [{ id: 'prof-1' }] });
    query.mockResolvedValueOnce({ rows: [{ id: 'prof-1' }] });

    const res = await request(app)
      .post('/api/services/me')
      .set('Authorization', authHeader(proToken))
      .send({ name: 'Bad Service', price_min: -10 });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toContain('price_min must be >= 0');
  });

  it('should search services with pagination', async () => {
    query.mockResolvedValueOnce({ rows: [{ total: 2 }] });
    query.mockResolvedValueOnce({
      rows: [
        { id: 'service-1', name: 'AC Repair', price_display: 'From ₹500' },
        { id: 'service-2', name: 'AC Install', price_display: '₹1200 – ₹2000' },
      ],
    });

    const res = await request(app)
      .get('/api/services/search')
      .query({ q: 'ac', page: 1, limit: 2 });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveLength(2);
    expect(res.body.pagination.total_count).toBe(2);
  });

  it('should support category filters in service search', async () => {
    query.mockResolvedValueOnce({ rows: [{ total: 1 }] });
    query.mockResolvedValueOnce({ rows: [{ id: 'service-1', name: 'Plumbing inspection' }] });

    const res = await request(app)
      .get('/api/services/search')
      .query({ category: 'Plumbing' });

    expect(res.status).toBe(200);
    expect(query.mock.calls[0][0]).toContain('c.name ILIKE');
  });
});
