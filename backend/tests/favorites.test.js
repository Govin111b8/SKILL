const request = require('supertest');
const express = require('express');
const jwt = require('jsonwebtoken');
const favoriteRoutes = require('../src/routes/favorites');
const errorHandler = require('../src/middleware/errorHandler');
const { query, pool } = require('../src/config/database');

jest.mock('../src/config/database', () => ({
  query: jest.fn(),
  pool: { end: jest.fn(), query: jest.fn() },
}));

const app = express();
app.use(express.json());
app.use('/api/favorites', favoriteRoutes);
app.use(errorHandler);

process.env.JWT_SECRET = 'test-secret';

const generateTestToken = (user) => jwt.sign(user, process.env.JWT_SECRET, { expiresIn: '1h' });
const authHeader = (token) => ['Bearer', token].join(' ');
const token = generateTestToken({ id: 'user-uuid', role: 'customer', email: 'test@example.com' });

describe('Favorites Endpoints', () => {
  beforeEach(() => {
    query.mockReset();
    pool.query.mockReset();
  });

  it('should list user favorites', async () => {
    query.mockResolvedValueOnce({
      rows: [{
        id: 'prof-1',
        name: 'Asha Pro',
        headline: 'Expert Electrician',
        favorited_at: new Date().toISOString(),
        avg_rating: 4.8,
        review_count: 12,
      }],
    });

    const res = await request(app)
      .get('/api/favorites')
      .set('Authorization', authHeader(token));

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].name).toBe('Asha Pro');
  });

  it('should add a professional to favorites', async () => {
    query.mockResolvedValueOnce({ rows: [] });
    query.mockResolvedValueOnce({ rows: [] });

    const res = await request(app)
      .post('/api/favorites/toggle')
      .set('Authorization', authHeader(token))
      .send({ professional_id: 'prof-1' });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.favorited).toBe(true);
    expect(res.body.message).toContain('Added');
  });

  it('should remove an existing favorite', async () => {
    query.mockResolvedValueOnce({ rows: [{ exists: 1 }] });
    query.mockResolvedValueOnce({ rows: [] });

    const res = await request(app)
      .post('/api/favorites/toggle')
      .set('Authorization', authHeader(token))
      .send({ professional_id: 'prof-1' });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.favorited).toBe(false);
    expect(res.body.message).toContain('Removed');
  });

  it('should reject toggle requests without professional_id', async () => {
    const res = await request(app)
      .post('/api/favorites/toggle')
      .set('Authorization', authHeader(token))
      .send({});

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toContain('professional_id is required');
  });

  it('should report a professional as favorited', async () => {
    query.mockResolvedValueOnce({ rows: [{ exists: 1 }] });

    const res = await request(app)
      .get('/api/favorites/check/prof-1')
      .set('Authorization', authHeader(token));

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.favorited).toBe(true);
  });

  it('should report a professional as not favorited', async () => {
    query.mockResolvedValueOnce({ rows: [] });

    const res = await request(app)
      .get('/api/favorites/check/prof-2')
      .set('Authorization', authHeader(token));

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.favorited).toBe(false);
  });
});
