const request = require('supertest');
const app = require('../src/app');
const { query } = require('../src/config/database');

// Mock the database module
jest.mock('../src/config/database', () => ({
  query: jest.fn(),
  pool: { end: jest.fn() },
}));

// Set env vars for testing
process.env.JWT_SECRET = 'test-secret';
process.env.JWT_EXPIRES_IN = '7d';

describe('Auth Endpoints', () => {
  beforeEach(() => {
    query.mockReset();
  });

  describe('POST /api/auth/register', () => {
    it('should register a new user successfully', async () => {
      query.mockResolvedValueOnce({ rows: [] }); // Check existing user
      query.mockResolvedValueOnce({
        rows: [
          {
            id: 'uuid-123',
            name: 'John Doe',
            email: 'john@example.com',
            phone: '1234567890',
            role: 'customer',
            location: 'New York',
            created_at: new Date().toISOString(),
          },
        ],
      });

      const res = await request(app).post('/api/auth/register').send({
        name: 'John Doe',
        email: 'john@example.com',
        password: 'Password123!',
        phone: '1234567890',
        role: 'customer',
        location: 'New York',
      });

      expect(res.statusCode).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.token).toBeDefined();
      expect(res.body.data.user.email).toBe('john@example.com');
    });

    it('should fail with validation errors for missing fields', async () => {
      const res = await request(app).post('/api/auth/register').send({
        email: 'invalid',
      });

      expect(res.statusCode).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.errors).toBeDefined();
    });

    it('should fail if user already exists', async () => {
      query.mockResolvedValueOnce({ rows: [{ id: 'existing-id' }] });

      const res = await request(app).post('/api/auth/register').send({
        name: 'John Doe',
        email: 'john@example.com',
        password: 'Password123!',
        phone: '1234567890',
        role: 'customer',
        location: 'New York',
      });

      expect(res.statusCode).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('already exists');
    });

    it('should reject invalid role', async () => {
      const res = await request(app).post('/api/auth/register').send({
        name: 'John Doe',
        email: 'john@example.com',
        password: 'password123',
        phone: '1234567890',
        role: 'invalid_role',
        location: 'New York',
      });

      expect(res.statusCode).toBe(400);
      expect(res.body.success).toBe(false);
    });
  });

  describe('POST /api/auth/login', () => {
    it('should login successfully with correct credentials', async () => {
      const bcrypt = require('bcryptjs');
      const hashedPassword = await bcrypt.hash('password123', 10);

      query.mockResolvedValueOnce({
        rows: [
          {
            id: 'uuid-123',
            name: 'John Doe',
            email: 'john@example.com',
            password_hash: hashedPassword,
            phone: '1234567890',
            role: 'customer',
            location: 'New York',
          },
        ],
      });
      // Ban check
      query.mockResolvedValueOnce({ rows: [{ count: '0' }] });

      const res = await request(app).post('/api/auth/login').send({
        email: 'john@example.com',
        password: 'password123',
      });

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.token).toBeDefined();
      expect(res.body.data.user.password_hash).toBeUndefined();
    });

    it('should fail with wrong password', async () => {
      const bcrypt = require('bcryptjs');
      const hashedPassword = await bcrypt.hash('password123', 10);

      query.mockResolvedValueOnce({
        rows: [
          {
            id: 'uuid-123',
            email: 'john@example.com',
            password_hash: hashedPassword,
          },
        ],
      });
      // Ban check
      query.mockResolvedValueOnce({ rows: [{ count: '0' }] });

      const res = await request(app).post('/api/auth/login').send({
        email: 'john@example.com',
        password: 'wrongpassword',
      });

      expect(res.statusCode).toBe(401);
      expect(res.body.success).toBe(false);
    });

    it('should fail with non-existent email', async () => {
      query.mockResolvedValueOnce({ rows: [] });

      const res = await request(app).post('/api/auth/login').send({
        email: 'nonexistent@example.com',
        password: 'password123',
      });

      expect(res.statusCode).toBe(401);
      expect(res.body.success).toBe(false);
    });

    it('should reject banned users', async () => {
      const bcrypt = require('bcryptjs');
      const hashedPassword = await bcrypt.hash('password123', 10);

      query.mockResolvedValueOnce({
        rows: [
          {
            id: 'uuid-123',
            email: 'john@example.com',
            password_hash: hashedPassword,
          },
        ],
      });
      // Ban check - user is banned
      query.mockResolvedValueOnce({ rows: [{ count: '1' }] });

      const res = await request(app).post('/api/auth/login').send({
        email: 'john@example.com',
        password: 'password123',
      });

      expect(res.statusCode).toBe(403);
      expect(res.body.message).toContain('banned');
    });
  });
});
