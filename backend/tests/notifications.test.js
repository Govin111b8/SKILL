const request = require('supertest');
const express = require('express');
const jwt = require('jsonwebtoken');
const notificationRoutes = require('../src/routes/notifications');
const errorHandler = require('../src/middleware/errorHandler');
const { query, pool } = require('../src/config/database');

jest.mock('../src/config/database', () => ({
  query: jest.fn(),
  pool: { end: jest.fn(), query: jest.fn() },
}));

const app = express();
app.use(express.json());
app.use('/api/notifications', notificationRoutes);
app.use(errorHandler);

process.env.JWT_SECRET = 'test-secret';

const generateTestToken = (user) => jwt.sign(user, process.env.JWT_SECRET, { expiresIn: '1h' });
const authHeader = (token) => ['Bearer', token].join(' ');
const token = generateTestToken({ id: 'user-uuid', role: 'customer', email: 'test@example.com' });

describe('Notification Endpoints', () => {
  beforeEach(() => {
    query.mockReset();
    pool.query.mockReset();
  });

  it('should list notifications with unread count', async () => {
    query.mockResolvedValueOnce({
      rows: [
        { id: 'n1', title: 'Booking confirmed', read_at: null },
        { id: 'n2', title: 'New message', read_at: new Date().toISOString() },
      ],
    });
    query.mockResolvedValueOnce({ rows: [{ count: '1' }] });

    const res = await request(app)
      .get('/api/notifications')
      .set('Authorization', authHeader(token));

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveLength(2);
    expect(res.body.unread_count).toBe(1);
  });

  it('should support the unread_only filter', async () => {
    query.mockResolvedValueOnce({ rows: [{ id: 'n1', title: 'Unread only', read_at: null }] });
    query.mockResolvedValueOnce({ rows: [{ count: '2' }] });

    const res = await request(app)
      .get('/api/notifications')
      .query({ unread_only: 'true' })
      .set('Authorization', authHeader(token));

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(query.mock.calls[0][0]).toContain('read_at IS NULL');
  });

  it('should mark a single notification as read', async () => {
    query.mockResolvedValueOnce({ rows: [] });

    const res = await request(app)
      .put('/api/notifications/notif-1/read')
      .set('Authorization', authHeader(token));

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(query).toHaveBeenCalledWith(
      expect.stringContaining('UPDATE notifications SET read_at = NOW()'),
      ['user-uuid', 'notif-1']
    );
  });

  it('should mark all notifications as read', async () => {
    query.mockResolvedValueOnce({ rows: [] });

    const res = await request(app)
      .put('/api/notifications/read-all')
      .set('Authorization', authHeader(token));

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(query).toHaveBeenCalledWith(
      expect.stringContaining('WHERE user_id = $1 AND read_at IS NULL'),
      ['user-uuid']
    );
  });

  it('should require authentication', async () => {
    const res = await request(app).get('/api/notifications');
    expect(res.status).toBe(401);
  });
});
