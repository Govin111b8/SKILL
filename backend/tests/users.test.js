const request = require('supertest');
const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const userRoutes = require('../src/routes/users');
const errorHandler = require('../src/middleware/errorHandler');
const { query, pool } = require('../src/config/database');

jest.mock('../src/config/database', () => ({
  query: jest.fn(),
  pool: { end: jest.fn(), query: jest.fn() },
}));

const app = express();
app.use(express.json());
app.use('/api/users', userRoutes);
app.use(errorHandler);

process.env.JWT_SECRET = 'test-secret';
process.env.JWT_EXPIRES_IN = '7d';

const generateTestToken = (user) => jwt.sign(user, process.env.JWT_SECRET, { expiresIn: '1h' });
const authHeader = (token) => ['Bearer', token].join(' ');
const token = generateTestToken({ id: 'user-uuid', role: 'customer', email: 'test@example.com' });

describe('User Endpoints', () => {
  beforeEach(() => {
    query.mockReset();
    pool.query.mockReset();
  });

  describe('GET /api/users/profile', () => {
    it('should return the authenticated user profile', async () => {
      query.mockResolvedValueOnce({
        rows: [{
          id: 'user-uuid',
          name: 'Test User',
          email: 'test@example.com',
          phone: '9999999999',
          role: 'customer',
          location: 'Hyderabad',
          avatar_url: '/avatar.png',
          phone_verified: true,
          government_id_verified: false,
          selfie_verified: false,
          created_at: new Date().toISOString(),
        }],
      });

      const res = await request(app)
        .get('/api/users/profile')
        .set('Authorization', authHeader(token));

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.email).toBe('test@example.com');
      expect(query).toHaveBeenCalledWith(expect.stringContaining('FROM users WHERE id = $1'), ['user-uuid']);
    });

    it('should return 404 when the user does not exist', async () => {
      query.mockResolvedValueOnce({ rows: [] });

      const res = await request(app)
        .get('/api/users/profile')
        .set('Authorization', authHeader(token));

      expect(res.status).toBe(404);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('User not found');
    });
  });

  describe('PUT /api/users/profile', () => {
    it('should update the user profile', async () => {
      query.mockResolvedValueOnce({
        rows: [{
          id: 'user-uuid',
          name: 'Updated User',
          email: 'test@example.com',
          phone: '8888888888',
          role: 'customer',
          location: 'Bengaluru',
          avatar_url: '/new.png',
          created_at: new Date().toISOString(),
        }],
      });

      const res = await request(app)
        .put('/api/users/profile')
        .set('Authorization', authHeader(token))
        .send({ name: 'Updated User', phone: '8888888888', location: 'Bengaluru', avatar_url: '/new.png' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.message).toContain('Profile updated');
      expect(res.body.data.name).toBe('Updated User');
    });

    it('should reject invalid profile input', async () => {
      const res = await request(app)
        .put('/api/users/profile')
        .set('Authorization', authHeader(token))
        .send({ name: '' });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toBe('Validation failed');
      expect(res.body.errors).toEqual(expect.arrayContaining([
        expect.objectContaining({ field: 'name' }),
      ]));
    });
  });

  describe('PUT /api/users/change-password', () => {
    it('should change the password with the correct current password', async () => {
      const passwordHash = await bcrypt.hash('CurrentPass1', 10);
      query.mockResolvedValueOnce({ rows: [{ password_hash: passwordHash }] });
      query.mockResolvedValueOnce({ rows: [] });

      const res = await request(app)
        .put('/api/users/change-password')
        .set('Authorization', authHeader(token))
        .send({ current_password: 'CurrentPass1', new_password: 'NewPassword1' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.message).toContain('Password changed successfully');
      expect(query).toHaveBeenNthCalledWith(
        2,
        'UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2',
        expect.arrayContaining(['user-uuid'])
      );
    });

    it('should reject a wrong current password', async () => {
      const passwordHash = await bcrypt.hash('CurrentPass1', 10);
      query.mockResolvedValueOnce({ rows: [{ password_hash: passwordHash }] });

      const res = await request(app)
        .put('/api/users/change-password')
        .set('Authorization', authHeader(token))
        .send({ current_password: 'WrongPass1', new_password: 'NewPassword1' });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('Current password is incorrect');
    });

    it('should reject a weak new password', async () => {
      const res = await request(app)
        .put('/api/users/change-password')
        .set('Authorization', authHeader(token))
        .send({ current_password: 'CurrentPass1', new_password: 'weakpass' });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('uppercase');
    });
  });

  describe('DELETE /api/users/account', () => {
    it('should delete the authenticated account', async () => {
      query.mockResolvedValueOnce({ rows: [] });

      const res = await request(app)
        .delete('/api/users/account')
        .set('Authorization', authHeader(token));

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.message).toContain('Account deleted successfully');
      expect(query).toHaveBeenCalledWith('DELETE FROM users WHERE id = $1', ['user-uuid']);
    });
  });
});
