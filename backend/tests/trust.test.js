const request = require('supertest');
const express = require('express');
const trustRoutes = require('../src/routes/trust');
const errorHandler = require('../src/middleware/errorHandler');
const { query, pool } = require('../src/config/database');

jest.mock('../src/config/database', () => ({
  query: jest.fn(),
  pool: { end: jest.fn(), query: jest.fn() },
}));

const app = express();
app.use(express.json());
app.use('/api/trust', trustRoutes);
app.use(errorHandler);

process.env.JWT_SECRET = 'test-secret';

describe('Trust Endpoints', () => {
  beforeEach(() => {
    query.mockReset();
    pool.query.mockReset();
  });

  it('should return badges and trust stats', async () => {
    query.mockResolvedValueOnce({
      rows: [{
        id: 'prof-1',
        completed_jobs: 120,
        response_time_hours: 0.25,
        repeat_customer_rate: '55',
        government_id_verified: true,
        average_rating: '4.9',
        review_count: 30,
      }],
    });
    query.mockResolvedValueOnce({ rows: [{ category_id: 1 }] });
    query.mockResolvedValueOnce({ rows: [{ percentile: 0.95 }] });
    query.mockResolvedValueOnce({ rows: [{ badge_type: 'fast_responder', earned_at: new Date().toISOString(), metadata: {} }] });

    const res = await request(app).get('/api/trust/prof-1/badges');

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.badges).toEqual(expect.arrayContaining([
      expect.objectContaining({ type: 'fast_responder', earned: true }),
      expect.objectContaining({ type: 'top_rated', qualifies: true }),
    ]));
    expect(res.body.data.stats.completed_jobs).toBe(120);
  });

  it('should return 404 when badges are requested for a missing professional', async () => {
    query.mockResolvedValueOnce({ rows: [] });

    const res = await request(app).get('/api/trust/missing-prof/badges');

    expect(res.status).toBe(404);
    expect(res.body.success).toBe(false);
  });

  it('should return a trust timeline', async () => {
    const now = new Date().toISOString();
    query.mockResolvedValueOnce({
      rows: [{
        id: 'prof-1',
        joined_at: now,
        completed_jobs: 25,
        response_time_hours: 0.5,
        repeat_customer_rate: '30',
        total_customers: 20,
        name: 'Pro Name',
        government_id_verified: true,
        average_rating: '4.6',
        review_count: 8,
      }],
    });
    query.mockResolvedValueOnce({ rows: [{ badge_type: 'rising_pro', earned_at: now }] });

    const res = await request(app).get('/api/trust/prof-1/timeline');

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.professional.name).toBe('Pro Name');
    expect(res.body.data.timeline).toEqual(expect.arrayContaining([
      expect.objectContaining({ type: 'joined' }),
      expect.objectContaining({ type: 'badge', label: expect.stringContaining('Rising Pro') }),
    ]));
  });

  it('should explain trust signals for a professional', async () => {
    query.mockResolvedValueOnce({
      rows: [{
        completed_jobs: 60,
        response_time_hours: 0.5,
        repeat_customer_rate: '45',
        total_customers: 40,
        reputation_score: '92',
        government_id_verified: true,
        phone_verified: true,
        selfie_verified: true,
        average_rating: '4.8',
        review_count: 22,
      }],
    });

    const res = await request(app).get('/api/trust/prof-1/explain');

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.trust_score).toBe(92);
    expect(res.body.data.signals.length).toBeGreaterThanOrEqual(4);
    expect(res.body.data.summary).toContain('Highly trusted');
  });

  it('should return 404 when explaining trust for a missing professional', async () => {
    query.mockResolvedValueOnce({ rows: [] });

    const res = await request(app).get('/api/trust/missing-prof/explain');

    expect(res.status).toBe(404);
    expect(res.body.success).toBe(false);
  });
});
