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

describe('Reviews Endpoints', () => {
  beforeEach(() => {
    query.mockReset();
  });

  describe('POST /api/reviews', () => {
    it('should create a review when user has a completed contact', async () => {
      const token = generateTestToken({
        id: 'user-1',
        email: 'john@example.com',
        role: 'customer',
      });

      // Contact check - found completed contact
      query.mockResolvedValueOnce({ rows: [{ id: 'contact-1', created_at: new Date(Date.now() - 2 * 3600000).toISOString() }] });
      // Check existing review
      query.mockResolvedValueOnce({ rows: [] });
      // Velocity check - no burst (< 5 reviews in 24h)
      query.mockResolvedValueOnce({ rows: [{ count: '1' }] });
      // Insert review
      query.mockResolvedValueOnce({
        rows: [
          {
            id: 'review-1',
            professional_id: 'prof-1',
            customer_id: 'user-1',
            contact_id: 'contact-1',
            rating: 5,
            comment: 'Excellent service!',
            created_at: new Date().toISOString(),
          },
        ],
      });

      const res = await request(app)
        .post('/api/reviews')
        .set('Authorization', `Bearer ${token}`)
        .send({
          professional_id: 'prof-1',
          contact_id: 'contact-1',
          rating: 5,
          comment: 'Excellent service!',
        });

      expect(res.statusCode).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.rating).toBe(5);
    });

    it('should fail if no completed contact exists', async () => {
      const token = generateTestToken({
        id: 'user-1',
        email: 'john@example.com',
        role: 'customer',
      });

      // Contact check - no completed contact
      query.mockResolvedValueOnce({ rows: [] });

      const res = await request(app)
        .post('/api/reviews')
        .set('Authorization', `Bearer ${token}`)
        .send({
          professional_id: 'prof-1',
          contact_id: 'contact-1',
          rating: 5,
          comment: 'Great work!',
        });

      expect(res.statusCode).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('contacted');
    });

    it('should reject rating outside 1-5 range', async () => {
      const token = generateTestToken({
        id: 'user-1',
        email: 'john@example.com',
        role: 'customer',
      });

      const res = await request(app)
        .post('/api/reviews')
        .set('Authorization', `Bearer ${token}`)
        .send({
          professional_id: 'prof-1',
          contact_id: 'contact-1',
          rating: 6,
          comment: 'Great!',
        });

      expect(res.statusCode).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it('should reject rating below 1', async () => {
      const token = generateTestToken({
        id: 'user-1',
        email: 'john@example.com',
        role: 'customer',
      });

      const res = await request(app)
        .post('/api/reviews')
        .set('Authorization', `Bearer ${token}`)
        .send({
          professional_id: 'prof-1',
          contact_id: 'contact-1',
          rating: 0,
          comment: 'Bad!',
        });

      expect(res.statusCode).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it('should require authentication', async () => {
      const res = await request(app).post('/api/reviews').send({
        professional_id: 'prof-1',
        contact_id: 'contact-1',
        rating: 5,
        comment: 'Great!',
      });

      expect(res.statusCode).toBe(401);
    });

    it('should prevent duplicate reviews for same contact', async () => {
      const token = generateTestToken({
        id: 'user-1',
        email: 'john@example.com',
        role: 'customer',
      });

      // Contact check - found
      query.mockResolvedValueOnce({ rows: [{ id: 'contact-1' }] });
      // Existing review found
      query.mockResolvedValueOnce({ rows: [{ id: 'existing-review' }] });

      const res = await request(app)
        .post('/api/reviews')
        .set('Authorization', `Bearer ${token}`)
        .send({
          professional_id: 'prof-1',
          contact_id: 'contact-1',
          rating: 4,
          comment: 'Another review',
        });

      expect(res.statusCode).toBe(400);
      expect(res.body.message).toContain('already reviewed');
    });
  });

  describe('GET /api/reviews/:professionalId', () => {
    it('should return paginated reviews for a professional', async () => {
      // New getReviews: list first, then count
      query.mockResolvedValueOnce({
        rows: [
          {
            id: 'review-1',
            rating: 5,
            comment: 'Excellent!',
            reviewer_name: 'John',
            created_at: new Date().toISOString(),
          },
          {
            id: 'review-2',
            rating: 4,
            comment: 'Good work',
            reviewer_name: 'Jane',
            created_at: new Date().toISOString(),
          },
        ],
      });
      query.mockResolvedValueOnce({ rows: [{ count: '2' }] });

      const res = await request(app).get('/api/reviews/prof-1').query({ page: 1, limit: 10 });

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveLength(2);
      expect(res.body.pagination.total).toBe(2);
    });
  });

  describe('POST /api/reviews (booking-based)', () => {
    it('should create a review via booking_id for a completed booking', async () => {
      const token = generateTestToken({
        id: 'user-1',
        email: 'john@example.com',
        role: 'customer',
      });

      // Booking check - found completed booking matching pro (with created_at for timing check)
      query.mockResolvedValueOnce({ rows: [{ id: 'booking-1', professional_id: 'prof-1', status: 'completed', created_at: new Date(Date.now() - 2 * 3600000).toISOString() }] });
      // Duplicate review check - none
      query.mockResolvedValueOnce({ rows: [] });
      // Velocity check - no burst
      query.mockResolvedValueOnce({ rows: [{ count: '1' }] });
      // Insert review
      query.mockResolvedValueOnce({
        rows: [
          {
            id: 'review-bk-1',
            professional_id: 'prof-1',
            customer_id: 'user-1',
            booking_id: 'booking-1',
            contact_id: null,
            rating: 5,
            comment: 'Amazing work on the booking!',
            created_at: new Date().toISOString(),
          },
        ],
      });
      // Notify pro user lookup
      query.mockResolvedValueOnce({ rows: [{ user_id: 'pro-user-1' }] });
      // Notify insert
      query.mockResolvedValueOnce({ rows: [] });

      const res = await request(app)
        .post('/api/reviews')
        .set('Authorization', `Bearer ${token}`)
        .send({
          professional_id: 'prof-1',
          booking_id: 'booking-1',
          rating: 5,
          comment: 'Amazing work on the booking!',
        });

      expect(res.statusCode).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.booking_id).toBe('booking-1');
    });

    it('should reject review for non-completed booking', async () => {
      const token = generateTestToken({
        id: 'user-1',
        email: 'john@example.com',
        role: 'customer',
      });

      // Booking check - found but not completed
      query.mockResolvedValueOnce({ rows: [{ id: 'booking-1', professional_id: 'prof-1', status: 'in_progress' }] });

      const res = await request(app)
        .post('/api/reviews')
        .set('Authorization', `Bearer ${token}`)
        .send({
          professional_id: 'prof-1',
          booking_id: 'booking-1',
          rating: 5,
          comment: 'Too early!',
        });

      expect(res.statusCode).toBe(400);
      expect(res.body.message).toContain('completed');
    });

    it('should prevent duplicate booking reviews', async () => {
      const token = generateTestToken({
        id: 'user-1',
        email: 'john@example.com',
        role: 'customer',
      });

      // Booking check - found and completed
      query.mockResolvedValueOnce({ rows: [{ id: 'booking-1', professional_id: 'prof-1', status: 'completed' }] });
      // Duplicate check - already reviewed
      query.mockResolvedValueOnce({ rows: [{ id: 'existing-review' }] });

      const res = await request(app)
        .post('/api/reviews')
        .set('Authorization', `Bearer ${token}`)
        .send({
          professional_id: 'prof-1',
          booking_id: 'booking-1',
          rating: 4,
        });

      expect(res.statusCode).toBe(400);
      expect(res.body.message).toContain('already reviewed');
    });

    it('should reject if booking professional_id does not match', async () => {
      const token = generateTestToken({
        id: 'user-1',
        email: 'john@example.com',
        role: 'customer',
      });

      // Booking found but for a different pro
      query.mockResolvedValueOnce({ rows: [{ id: 'booking-1', professional_id: 'prof-999', status: 'completed' }] });

      const res = await request(app)
        .post('/api/reviews')
        .set('Authorization', `Bearer ${token}`)
        .send({
          professional_id: 'prof-1',
          booking_id: 'booking-1',
          rating: 3,
        });

      expect(res.statusCode).toBe(400);
      expect(res.body.message).toContain('does not match');
    });

    it('should require either contact_id or booking_id', async () => {
      const token = generateTestToken({
        id: 'user-1',
        email: 'john@example.com',
        role: 'customer',
      });

      const res = await request(app)
        .post('/api/reviews')
        .set('Authorization', `Bearer ${token}`)
        .send({
          professional_id: 'prof-1',
          rating: 5,
        });

      expect(res.statusCode).toBe(400);
      expect(res.body.message).toContain('required');
    });
  });
});
