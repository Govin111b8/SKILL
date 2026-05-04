const request = require('supertest');
const jwt = require('jsonwebtoken');
const app = require('../src/app');
const { query } = require('../src/config/database');

jest.mock('../src/config/database', () => ({
  query: jest.fn(),
  pool: { end: jest.fn() },
}));

process.env.JWT_SECRET = 'test-secret';

const generateTestToken = (user) => {
  return jwt.sign(user, process.env.JWT_SECRET, { expiresIn: '1h' });
};

const mockProfessional = {
  id: 'prof-1',
  user_id: 'user-1',
  name: 'Test Professional',
  email: 'pro@example.com',
  phone: '1234567890',
  location: 'Test City',
  headline: 'Expert Plumber',
  bio: 'I fix things.',
  years_of_experience: 5,
  pricing_estimate: '₹500/hr',
  availability_status: 'available',
  average_rating: '4.5',
  review_count: '10',
  completed_jobs: 50,
  announcement: 'Summer discount!',
  whatsapp_number: '+911234567890',
  instagram_handle: 'testpro',
  website_url: 'https://example.com',
  cover_image_url: null,
  accent_color: '#6366F1',
  show_rating: true,
  return_policy: 'Satisfaction guaranteed',
  operating_hours: '9 AM - 6 PM',
  operating_days: 'Mon - Sat',
};

describe('Storefront Endpoints', () => {
  beforeEach(() => {
    query.mockReset();
  });

  describe('GET /api/storefront/:id', () => {
    it('should return aggregated storefront data', async () => {
      // Profile query
      query.mockResolvedValueOnce({ rows: [mockProfessional] });
      // Categories
      query.mockResolvedValueOnce({ rows: [{ id: 1, name: 'Plumbing' }] });
      // Portfolio
      query.mockResolvedValueOnce({ rows: [{ id: 'p1', title: 'Work Sample', media_url: '/img.jpg' }] });
      // Reviews
      query.mockResolvedValueOnce({ rows: [{ id: 'r1', rating: 5, comment: 'Great!', reviewer_name: 'John' }] });
      // Rating distribution
      query.mockResolvedValueOnce({ rows: [{ rating: 5, count: 8 }, { rating: 4, count: 2 }] });

      const res = await request(app).get('/api/storefront/prof-1');

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.name).toBe('Test Professional');
      expect(res.body.data.announcement).toBe('Summer discount!');
      expect(res.body.data.portfolio).toHaveLength(1);
      expect(res.body.data.reviews).toHaveLength(1);
      expect(res.body.data.rating_distribution[5]).toBe(8);
      expect(res.body.data.categories).toHaveLength(1);
    });

    it('should return 404 for non-existent professional', async () => {
      query.mockResolvedValueOnce({ rows: [] });

      const res = await request(app).get('/api/storefront/nonexistent');

      expect(res.status).toBe(404);
      expect(res.body.success).toBe(false);
    });
  });

  describe('PUT /api/storefront/:id', () => {
    it('should update storefront fields for owner', async () => {
      const token = generateTestToken({ id: 'user-1', email: 'pro@example.com', role: 'professional' });

      // Ownership check
      query.mockResolvedValueOnce({ rows: [{ id: 'prof-1' }] });
      // Update
      query.mockResolvedValueOnce({ rows: [{ ...mockProfessional, announcement: 'New announcement' }] });

      const res = await request(app)
        .put('/api/storefront/prof-1')
        .set('Authorization', `Bearer ${token}`)
        .send({ announcement: 'New announcement', operating_hours: '10 AM - 5 PM' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.announcement).toBe('New announcement');
    });

    it('should return 403 for non-owner', async () => {
      const token = generateTestToken({ id: 'user-2', email: 'other@example.com', role: 'professional' });

      // Ownership check fails
      query.mockResolvedValueOnce({ rows: [] });

      const res = await request(app)
        .put('/api/storefront/prof-1')
        .set('Authorization', `Bearer ${token}`)
        .send({ announcement: 'Hacked!' });

      expect(res.status).toBe(403);
    });

    it('should return 401 without token', async () => {
      const res = await request(app)
        .put('/api/storefront/prof-1')
        .send({ announcement: 'Test' });

      expect(res.status).toBe(401);
    });

    it('should return 403 for customer role', async () => {
      const token = generateTestToken({ id: 'user-3', email: 'cust@example.com', role: 'customer' });

      const res = await request(app)
        .put('/api/storefront/prof-1')
        .set('Authorization', `Bearer ${token}`)
        .send({ announcement: 'Test' });

      expect(res.status).toBe(403);
    });

    it('should validate accent_color format', async () => {
      const token = generateTestToken({ id: 'user-1', email: 'pro@example.com', role: 'professional' });

      const res = await request(app)
        .put('/api/storefront/prof-1')
        .set('Authorization', `Bearer ${token}`)
        .send({ accent_color: 'not-a-hex' });

      expect(res.status).toBe(400);
    });
  });
});
