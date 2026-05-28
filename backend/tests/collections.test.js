const request = require('supertest');
const express = require('express');
const jwt = require('jsonwebtoken');
const collectionRoutes = require('../src/routes/collections');
const errorHandler = require('../src/middleware/errorHandler');
const { query, pool } = require('../src/config/database');

jest.mock('../src/config/database', () => ({
  query: jest.fn(),
  pool: { end: jest.fn(), query: jest.fn() },
}));

const app = express();
app.use(express.json());
app.use('/api/collections', collectionRoutes);
app.use(errorHandler);

process.env.JWT_SECRET = 'test-secret';

const generateTestToken = (user) => jwt.sign(user, process.env.JWT_SECRET, { expiresIn: '1h' });
const authHeader = (token) => ['Bearer', token].join(' ');
const token = generateTestToken({ id: 'user-uuid', role: 'customer', email: 'test@example.com' });
const itemId = '550e8400-e29b-41d4-a716-446655440001';

describe('Collections Endpoints', () => {
  beforeEach(() => {
    query.mockReset();
    pool.query.mockReset();
  });

  it('should list the current user collections', async () => {
    query.mockResolvedValueOnce({
      rows: [{ id: 'col-1', name: 'Favorites', is_public: false, item_count: 3 }],
    });

    const res = await request(app)
      .get('/api/collections')
      .set('Authorization', authHeader(token));

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].item_count).toBe(3);
  });

  it('should create a new collection', async () => {
    query.mockResolvedValueOnce({
      rows: [{ id: 'col-1', user_id: 'user-uuid', name: 'Weekend Pros', is_public: true }],
    });

    const res = await request(app)
      .post('/api/collections')
      .set('Authorization', authHeader(token))
      .send({ name: 'Weekend Pros', is_public: true });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.name).toBe('Weekend Pros');
  });

  it('should validate collection creation payload', async () => {
    const res = await request(app)
      .post('/api/collections')
      .set('Authorization', authHeader(token))
      .send({ name: '' });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toBe('Validation failed');
  });

  it('should add an item to a collection', async () => {
    query.mockResolvedValueOnce({ rows: [{ id: 'col-1' }] });
    query.mockResolvedValueOnce({ rows: [{ id: 'item-row-1', collection_id: 'col-1', item_type: 'professional', item_id: itemId }] });
    query.mockResolvedValueOnce({ rows: [] });

    const res = await request(app)
      .post('/api/collections/col-1/items')
      .set('Authorization', authHeader(token))
      .send({ item_type: 'professional', item_id: itemId });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.item_id).toBe(itemId);
  });

  it('should reject adding items to a collection the user does not own', async () => {
    query.mockResolvedValueOnce({ rows: [] });

    const res = await request(app)
      .post('/api/collections/col-1/items')
      .set('Authorization', authHeader(token))
      .send({ item_type: 'professional', item_id: itemId });

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toContain('Not your collection');
  });

  it('should validate collection item payloads', async () => {
    const res = await request(app)
      .post('/api/collections/col-1/items')
      .set('Authorization', authHeader(token))
      .send({ item_type: 'professional', item_id: 'not-a-uuid' });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.errors).toEqual(expect.arrayContaining([
      expect.objectContaining({ field: 'item_id' }),
    ]));
  });
});
