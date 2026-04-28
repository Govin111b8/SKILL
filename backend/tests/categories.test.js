const request = require('supertest');
const jwt = require('jsonwebtoken');
const app = require('../src/app');
const { query } = require('../src/config/database');

jest.mock('../src/config/database', () => ({
  query: jest.fn(),
  pool: { end: jest.fn() },
}));

process.env.JWT_SECRET = 'test-secret';

const custToken = jwt.sign({ id: 'cust-1', email: 'c@x.com', role: 'customer' }, 'test-secret');

// ─── Category endpoints ──────────────────────────────────────────────────────

describe('GET /api/categories', () => {
  beforeEach(() => jest.clearAllMocks());

  it('returns nested category tree with pro_count', async () => {
    query.mockResolvedValueOnce({
      rows: [
        { id: 1, name: 'Home Services', parent_id: null, description: 'desc', icon: 'home', pro_count: 0 },
        { id: 2, name: 'Plumbing', parent_id: 1, description: 'pipes', icon: 'plumbing', pro_count: 5 },
        { id: 3, name: 'Electrical', parent_id: 1, description: 'wiring', icon: 'electrical', pro_count: 3 },
      ]
    });

    const res = await request(app).get('/api/categories');
    expect(res.status).toBe(200);
    const roots = res.body.data;
    expect(roots).toHaveLength(1);
    expect(roots[0].name).toBe('Home Services');
    expect(roots[0].children).toHaveLength(2);
    // parent pro_count should be rolled up
    expect(roots[0].pro_count).toBeGreaterThanOrEqual(8);
  });
});

describe('GET /api/categories/:id', () => {
  beforeEach(() => jest.clearAllMocks());

  it('returns category with subcategories and parent', async () => {
    query.mockResolvedValueOnce({ rows: [{ id: 1, name: 'Home Services', parent_id: null, description: 'd', icon: null, pro_count: 15 }] });
    query.mockResolvedValueOnce({ rows: [
      { id: 2, name: 'Plumbing', description: 'pipes', icon: null, pro_count: 5 },
      { id: 3, name: 'Electrical', description: 'wires', icon: null, pro_count: 10 },
    ]});

    const res = await request(app).get('/api/categories/1');
    expect(res.status).toBe(200);
    expect(res.body.data.name).toBe('Home Services');
    expect(res.body.data.subcategories).toHaveLength(2);
    expect(res.body.data.parent).toBeNull(); // no parent (root)
  });

  it('returns 404 for non-existent category', async () => {
    query.mockResolvedValueOnce({ rows: [] });
    const res = await request(app).get('/api/categories/9999');
    expect(res.status).toBe(404);
  });
});

describe('GET /api/categories/:id/professionals', () => {
  beforeEach(() => jest.clearAllMocks());

  it('returns professionals sorted by rating with pagination', async () => {
    query.mockResolvedValueOnce({ rows: [
      { id: 'pro-1', name: 'Alice', average_rating: 4.8, review_count: 12, completed_jobs: 40 },
      { id: 'pro-2', name: 'Bob', average_rating: 4.2, review_count: 5, completed_jobs: 15 },
    ]});
    query.mockResolvedValueOnce({ rows: [{ total: 2 }] });

    const res = await request(app).get('/api/categories/1/professionals?sort_by=rating');
    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(2);
    expect(res.body.pagination.total).toBe(2);
  });

  it('filters by availability', async () => {
    query.mockResolvedValueOnce({ rows: [{ id: 'pro-3', name: 'Carol', average_rating: 4.9 }] });
    query.mockResolvedValueOnce({ rows: [{ total: 1 }] });

    const res = await request(app).get('/api/categories/1/professionals?availability=available');
    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
  });

  it('returns empty list for category with no professionals', async () => {
    query.mockResolvedValueOnce({ rows: [] });
    query.mockResolvedValueOnce({ rows: [{ total: 0 }] });

    const res = await request(app).get('/api/categories/99/professionals');
    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(0);
    expect(res.body.pagination.total).toBe(0);
  });
});

// ─── Pending reviews endpoint ─────────────────────────────────────────────────

describe('GET /api/reviews/pending', () => {
  beforeEach(() => jest.clearAllMocks());

  it('returns completed bookings without reviews for the customer', async () => {
    query.mockResolvedValueOnce({ rows: [
      {
        booking_id: 'booking-1',
        title: 'Fix sink',
        completed_at: new Date().toISOString(),
        professional_id: 'pro-1',
        professional_name: 'Alice',
        professional_avatar: null,
      },
    ]});

    const res = await request(app).get('/api/reviews/pending').set('Authorization', `Bearer ${custToken}`);
    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].booking_id).toBe('booking-1');
    expect(res.body.data[0].professional_name).toBe('Alice');
  });

  it('returns empty when all bookings are reviewed', async () => {
    query.mockResolvedValueOnce({ rows: [] });
    const res = await request(app).get('/api/reviews/pending').set('Authorization', `Bearer ${custToken}`);
    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(0);
  });

  it('rejects unauthenticated request', async () => {
    const res = await request(app).get('/api/reviews/pending');
    expect(res.status).toBe(401);
  });
});
