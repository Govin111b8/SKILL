const request = require('supertest');
const express = require('express');
const matchingRoutes = require('../src/routes/matching');
const errorHandler = require('../src/middleware/errorHandler');
const { query, pool } = require('../src/config/database');

jest.mock('../src/config/database', () => ({
  query: jest.fn(),
  pool: { end: jest.fn(), query: jest.fn() },
}));

const app = express();
app.use(express.json());
app.use('/api/match', matchingRoutes);
app.use(errorHandler);

process.env.JWT_SECRET = 'test-secret';

describe('Matching Endpoints', () => {
  beforeEach(() => {
    query.mockReset();
    pool.query.mockReset();
  });

  it('should return matched professionals', async () => {
    pool.query.mockResolvedValueOnce({
      rows: [{
        professional_id: 'prof-1',
        user_id: 'user-1',
        name: 'Nearby Pro',
        avatar_url: '/a.png',
        headline: 'Fast electrician',
        pricing_estimate: '₹500',
        availability_status: 'available',
        distance_km: 4.36,
        avg_rating: '4.8',
        review_count: '12',
        response_time_hours: 0.5,
        completed_jobs: 88,
        match_score: 92.4,
        provider_type: 'individual',
      }],
    });

    const res = await request(app)
      .get('/api/match')
      .query({ category_id: 2, latitude: 17.385, longitude: 78.4867, limit: 5, radius_km: 20 });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.matched_providers).toHaveLength(1);
    expect(res.body.matched_providers[0].distance_km).toBe(4.4);
    expect(res.body.matched_providers[0].avg_rating).toBe('4.8');
    expect(res.body.meta.total_matched).toBe(1);
  });

  it('should handle empty match results', async () => {
    pool.query.mockResolvedValueOnce({ rows: [] });

    const res = await request(app)
      .get('/api/match')
      .query({ category_id: 2, latitude: 17.385, longitude: 78.4867 });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.matched_providers).toEqual([]);
    expect(res.body.meta.total_matched).toBe(0);
  });

  it('should require latitude and longitude', async () => {
    const res = await request(app)
      .get('/api/match')
      .query({ category_id: 2 });

    expect(res.status).toBe(400);
    expect(res.body.error).toContain('Latitude and longitude are required');
  });

  it('should require a category id', async () => {
    const res = await request(app)
      .get('/api/match')
      .query({ latitude: 17.385, longitude: 78.4867 });

    expect(res.status).toBe(400);
    expect(res.body.error).toContain('Category ID is required');
  });

  it('should cap requested limit to 10 results', async () => {
    pool.query.mockResolvedValueOnce({ rows: [] });

    const res = await request(app)
      .get('/api/match')
      .query({ category_id: 2, latitude: 17.385, longitude: 78.4867, limit: 25, radius_km: 25 });

    expect(res.status).toBe(200);
    expect(res.body.meta.max_results).toBe(10);
    expect(pool.query).toHaveBeenCalledWith(expect.stringContaining('LIMIT $5'), [17.385, 78.4867, '2', 25, 10]);
  });
});
