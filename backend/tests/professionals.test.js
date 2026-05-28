const request = require('supertest');
const express = require('express');
const jwt = require('jsonwebtoken');
const professionalRoutes = require('../src/routes/professionals');
const errorHandler = require('../src/middleware/errorHandler');
const { query, pool } = require('../src/config/database');

jest.mock('../src/config/database', () => ({
  query: jest.fn(),
  pool: { end: jest.fn(), query: jest.fn() },
}));

const app = express();
app.use(express.json());
app.use('/api/professionals', professionalRoutes);
app.use(errorHandler);

process.env.JWT_SECRET = 'test-secret';

const generateTestToken = (user) => jwt.sign(user, process.env.JWT_SECRET, { expiresIn: '1h' });
const authHeader = (token) => ['Bearer', token].join(' ');
const proToken = generateTestToken({ id: 'pro-user-1', role: 'professional', email: 'pro@example.com' });
const customerToken = generateTestToken({ id: 'cust-user-1', role: 'customer', email: 'cust@example.com' });

describe('Professional Endpoints', () => {
  beforeEach(() => {
    query.mockReset();
    pool.query.mockReset();
  });

  describe('GET /api/professionals/:id', () => {
    it('should return a professional profile', async () => {
      query.mockResolvedValueOnce({
        rows: [{ id: 'prof-1', user_id: 'pro-user-1', name: 'Pro Name', average_rating: '4.7', review_count: '9' }],
      });
      query.mockResolvedValueOnce({ rows: [{ id: 1, name: 'Plumbing' }] });

      const res = await request(app).get('/api/professionals/prof-1');

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.average_rating).toBe(4.7);
      expect(res.body.data.categories).toHaveLength(1);
    });

    it('should return 404 for a missing professional', async () => {
      query.mockResolvedValueOnce({ rows: [] });

      const res = await request(app).get('/api/professionals/missing-prof');

      expect(res.status).toBe(404);
      expect(res.body.success).toBe(false);
    });
  });

  describe('POST /api/professionals', () => {
    it('should create a professional profile', async () => {
      query.mockResolvedValueOnce({ rows: [] });
      query.mockResolvedValueOnce({
        rows: [{ id: 'prof-1', user_id: 'pro-user-1', headline: 'Expert Plumber', provider_type: 'individual' }],
      });
      query.mockResolvedValueOnce({ rows: [] });

      const res = await request(app)
        .post('/api/professionals')
        .set('Authorization', authHeader(proToken))
        .send({
          headline: 'Expert Plumber',
          bio: '10 years experience',
          years_of_experience: 10,
          pricing_estimate: 500,
          service_location_radius_km: 15,
          latitude: 17.385,
          longitude: 78.4867,
          category_ids: [1],
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.headline).toBe('Expert Plumber');
    });

    it('should reject invalid create profile payloads', async () => {
      const res = await request(app)
        .post('/api/professionals')
        .set('Authorization', authHeader(proToken))
        .send({
          headline: '',
          bio: '',
          years_of_experience: -1,
          pricing_estimate: -10,
          service_location_radius_km: -5,
          latitude: 999,
          longitude: 999,
          category_ids: [],
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toBe('Validation failed');
    });

    it('should reject customers creating professional profiles', async () => {
      const res = await request(app)
        .post('/api/professionals')
        .set('Authorization', authHeader(customerToken))
        .send({
          headline: 'Nope',
          bio: 'Nope',
          years_of_experience: 1,
          pricing_estimate: 100,
          service_location_radius_km: 5,
          latitude: 12,
          longitude: 77,
          category_ids: [1],
        });

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
    });
  });

  describe('PUT /api/professionals/profile', () => {
    it('should update the authenticated professional profile', async () => {
      query.mockResolvedValueOnce({ rows: [{ id: 'prof-1' }] });
      query.mockResolvedValueOnce({ rows: [{ id: 'prof-1' }] });
      query.mockResolvedValueOnce({ rows: [{ id: 'prof-1', headline: 'Updated headline', provider_type: 'organization' }] });
      query.mockResolvedValueOnce({ rows: [] });
      query.mockResolvedValueOnce({ rows: [] });

      const res = await request(app)
        .put('/api/professionals/profile')
        .set('Authorization', authHeader(proToken))
        .send({ headline: 'Updated headline', provider_type: 'organization', category_ids: [2] });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.headline).toBe('Updated headline');
    });

    it('should return 404 when updating without an existing profile', async () => {
      query.mockResolvedValueOnce({ rows: [] });

      const res = await request(app)
        .put('/api/professionals/profile')
        .set('Authorization', authHeader(proToken))
        .send({ headline: 'Updated headline' });

      expect(res.status).toBe(404);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('Please create one first');
    });
  });

  describe('PUT /api/professionals/me/availability', () => {
    it('should toggle availability for the authenticated professional', async () => {
      query.mockResolvedValueOnce({ rows: [{ id: 'prof-1', availability_status: 'busy' }] });

      const res = await request(app)
        .put('/api/professionals/me/availability')
        .set('Authorization', authHeader(proToken))
        .send({ availability_status: 'busy' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.availability_status).toBe('busy');
    });

    it('should validate availability status values', async () => {
      const res = await request(app)
        .put('/api/professionals/me/availability')
        .set('Authorization', authHeader(proToken))
        .send({ availability_status: 'sometimes' });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toBe('Validation failed');
    });
  });
});
