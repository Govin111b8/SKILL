const request = require('supertest');
const express = require('express');
const jwt = require('jsonwebtoken');
const gamificationRoutes = require('../src/routes/gamification');
const errorHandler = require('../src/middleware/errorHandler');
const { query, pool } = require('../src/config/database');

jest.mock('../src/config/database', () => ({
  query: jest.fn(),
  pool: { end: jest.fn(), query: jest.fn() },
}));

const app = express();
app.use(express.json());
app.use('/api/gamification', gamificationRoutes);
app.use(errorHandler);

process.env.JWT_SECRET = 'test-secret';

const generateTestToken = (user) => jwt.sign(user, process.env.JWT_SECRET, { expiresIn: '1h' });
const authHeader = (token) => ['Bearer', token].join(' ');
const customerToken = generateTestToken({ id: 'cust-1', role: 'customer', email: 'cust@example.com' });
const professionalToken = generateTestToken({ id: 'pro-user-1', role: 'professional', email: 'pro@example.com' });

describe('Gamification Endpoints', () => {
  beforeEach(() => {
    query.mockReset();
    pool.query.mockReset();
  });

  it('should return the current user points summary', async () => {
    query.mockResolvedValueOnce({ rows: [] });
    query.mockResolvedValueOnce({ rows: [{ points_balance: '320', lifetime_points: '1200', level: '2' }] });
    query.mockResolvedValueOnce({ rows: [{ id: 'tx-1', type: 'earn', points: 50, reason: 'booking complete' }] });

    const res = await request(app)
      .get('/api/gamification/points')
      .set('Authorization', authHeader(customerToken));

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.points_balance).toBe(320);
    expect(res.body.data.level_name).toBe('Silver');
    expect(res.body.data.recent_transactions).toHaveLength(1);
  });

  it('should redeem points successfully', async () => {
    query.mockResolvedValueOnce({ rows: [{ points_balance: '500' }] });
    query.mockResolvedValueOnce({ rows: [] });
    query.mockResolvedValueOnce({ rows: [] });

    const res = await request(app)
      .post('/api/gamification/points/redeem')
      .set('Authorization', authHeader(customerToken))
      .send({ points: 200, booking_id: 'booking-1' });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.discount_applied).toBe(20);
    expect(res.body.data.new_balance).toBe(300);
  });

  it('should reject redemptions below the minimum threshold', async () => {
    const res = await request(app)
      .post('/api/gamification/points/redeem')
      .set('Authorization', authHeader(customerToken))
      .send({ points: 50, booking_id: 'booking-1' });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toContain('Minimum redemption');
  });

  it('should reject redemption when the user lacks enough points', async () => {
    query.mockResolvedValueOnce({ rows: [{ points_balance: '80' }] });

    const res = await request(app)
      .post('/api/gamification/points/redeem')
      .set('Authorization', authHeader(customerToken))
      .send({ points: 200, booking_id: 'booking-1' });

    expect(res.status).toBe(422);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toContain('Insufficient points');
  });

  it('should return the customer leaderboard', async () => {
    query.mockResolvedValueOnce({
      rows: [{ user_id: 'cust-1', name: 'Top User', lifetime_points: 1500, level: 3, rank: 1 }],
    });

    const res = await request(app)
      .get('/api/gamification/leaderboard')
      .set('Authorization', authHeader(customerToken));

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data[0].rank).toBe(1);
  });

  it('should return professional growth stats', async () => {
    query.mockResolvedValueOnce({
      rows: [{
        id: 'prof-1',
        average_rating: '4.6',
        completed_jobs: '24',
        response_time_hours: '0.75',
        availability_status: 'busy',
        trust_score: '88',
        kyc_level: '1',
        location: 'Hyderabad',
      }],
    });
    query.mockResolvedValueOnce({ rows: [{ streak_days: 7 }] });
    query.mockResolvedValueOnce({ rows: [{ rank: 2, total: 30 }] });
    query.mockResolvedValueOnce({ rows: [{ count: 5 }] });
    query.mockResolvedValueOnce({ rows: [{ count: 3 }] });

    const res = await request(app)
      .get('/api/gamification/professional/stats')
      .set('Authorization', authHeader(professionalToken));

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.professional_id).toBe('prof-1');
    expect(res.body.data.rank).toBe(2);
    expect(res.body.data.tips.length).toBeGreaterThan(0);
  });

  it('should return 404 when professional stats are requested without a profile', async () => {
    query.mockResolvedValueOnce({ rows: [] });

    const res = await request(app)
      .get('/api/gamification/professional/stats')
      .set('Authorization', authHeader(professionalToken));

    expect(res.status).toBe(404);
    expect(res.body.success).toBe(false);
  });
});
