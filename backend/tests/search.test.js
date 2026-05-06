const request = require('supertest');
const app = require('../src/app');
const { query } = require('../src/config/database');

jest.mock('../src/config/database', () => ({
  query: jest.fn(),
  pool: { end: jest.fn() },
}));

process.env.JWT_SECRET = 'test-secret';

describe('Search Endpoints', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('GET /api/search', () => {
    it('should return paginated search results', async () => {
      query.mockResolvedValueOnce({ rows: [{ count: '2' }] }); // count query
      query.mockResolvedValueOnce({
        rows: [
          {
            id: 'prof-1',
            name: 'Jane Smith',
            headline: 'Plumber',
            average_rating: 4.5,
            review_count: '10',
          },
          {
            id: 'prof-2',
            name: 'Bob Builder',
            headline: 'Carpenter',
            average_rating: 4.0,
            review_count: '5',
          },
        ],
      });

      const res = await request(app).get('/api/search').query({ page: 1, limit: 10 });

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveLength(2);
      expect(res.body.pagination).toBeDefined();
      expect(res.body.pagination.total).toBe(2);
    });

    it('should filter by text query', async () => {
      query.mockResolvedValueOnce({ rows: [{ count: '1' }] });
      query.mockResolvedValueOnce({
        rows: [
          {
            id: 'prof-1',
            name: 'Jane Smith',
            headline: 'Expert Plumber',
            average_rating: 4.5,
            review_count: '10',
          },
        ],
      });

      const res = await request(app).get('/api/search').query({ q: 'plumber' });

      expect(res.statusCode).toBe(200);
      expect(res.body.data).toHaveLength(1);
      // Verify the query was called with a LIKE parameter
      expect(query).toHaveBeenCalledWith(
        expect.stringContaining('ILIKE'),
        expect.arrayContaining(['%plumber%'])
      );
    });

    it('should filter by category_id', async () => {
      query.mockResolvedValueOnce({ rows: [{ count: '1' }] });
      query.mockResolvedValueOnce({
        rows: [
          {
            id: 'prof-1',
            name: 'Jane Smith',
            headline: 'Plumber',
            average_rating: 4.5,
            review_count: '8',
          },
        ],
      });

      const res = await request(app).get('/api/search').query({ category_id: '1' });

      expect(res.statusCode).toBe(200);
      expect(query).toHaveBeenCalledWith(
        expect.stringContaining('pc.category_id'),
        expect.arrayContaining([1])
      );
    });

    it('should filter by max_price', async () => {
      query.mockResolvedValueOnce({ rows: [{ count: '1' }] });
      query.mockResolvedValueOnce({
        rows: [
          {
            id: 'prof-1',
            name: 'Jane',
            headline: 'Plumber',
            average_rating: 4.0,
            review_count: '3',
          },
        ],
      });

      const res = await request(app).get('/api/search').query({ max_price: 100 });

      expect(res.statusCode).toBe(200);
      expect(query).toHaveBeenCalledWith(
        expect.stringContaining('pricing_estimate'),
        expect.arrayContaining([100])
      );
    });

    it('should support distance-based search', async () => {
      query.mockResolvedValueOnce({ rows: [{ count: '1' }] });
      query.mockResolvedValueOnce({
        rows: [
          {
            id: 'prof-1',
            name: 'Jane',
            headline: 'Plumber',
            average_rating: 4.5,
            review_count: '10',
            distance: 5.2,
          },
        ],
      });

      const res = await request(app).get('/api/search').query({
        latitude: 40.7128,
        longitude: -74.006,
        radius_km: 10,
      });

      expect(res.statusCode).toBe(200);
      expect(query).toHaveBeenCalledWith(
        expect.stringContaining('acos'),
        expect.arrayContaining([40.7128, -74.006])
      );
    });

    it('should sort results by experience', async () => {
      query.mockResolvedValueOnce({ rows: [{ count: '2' }] });
      query.mockResolvedValueOnce({
        rows: [
          { id: 'prof-1', name: 'Senior Pro', average_rating: 3.5, review_count: '5' },
          { id: 'prof-2', name: 'Junior Pro', average_rating: 4.5, review_count: '2' },
        ],
      });

      const res = await request(app).get('/api/search').query({ sort_by: 'experience' });

      expect(res.statusCode).toBe(200);
      expect(query).toHaveBeenCalledWith(
        expect.stringContaining('years_of_experience DESC'),
        expect.any(Array)
      );
    });

    it('should filter by availability status', async () => {
      query.mockResolvedValueOnce({ rows: [{ count: '1' }] });
      query.mockResolvedValueOnce({
        rows: [
          { id: 'prof-1', name: 'Available Pro', average_rating: 4.5, review_count: '10' },
        ],
      });

      const res = await request(app).get('/api/search').query({ availability: 'available' });

      expect(res.statusCode).toBe(200);
      expect(query).toHaveBeenCalledWith(
        expect.stringContaining('availability_status'),
        expect.arrayContaining(['available'])
      );
    });

    it('should combine geo + availability filters', async () => {
      query.mockResolvedValueOnce({ rows: [{ count: '1' }] });
      query.mockResolvedValueOnce({
        rows: [
          { id: 'prof-1', name: 'Near & Available', average_rating: 4.0, review_count: '5', distance: 3.4 },
        ],
      });

      const res = await request(app).get('/api/search').query({
        latitude: 17.385,
        longitude: 78.4867,
        radius_km: 25,
        availability: 'available',
        sort_by: 'distance',
      });

      expect(res.statusCode).toBe(200);
      expect(res.body.data[0].distance).toBe(3.4);
      expect(query).toHaveBeenCalledWith(
        expect.stringContaining('availability_status'),
        expect.arrayContaining(['available'])
      );
      expect(query).toHaveBeenCalledWith(
        expect.stringContaining('distance ASC'),
        expect.any(Array)
      );
    });

    it('should sort by distance when coords provided', async () => {
      query.mockResolvedValueOnce({ rows: [{ count: '1' }] });
      query.mockResolvedValueOnce({
        rows: [
          { id: 'prof-1', name: 'Nearby', average_rating: 4.0, review_count: '3', distance: 1.2 },
        ],
      });

      const res = await request(app).get('/api/search').query({
        latitude: 17.385,
        longitude: 78.4867,
        sort_by: 'distance',
      });

      expect(res.statusCode).toBe(200);
      expect(query).toHaveBeenCalledWith(
        expect.stringContaining('distance ASC'),
        expect.any(Array)
      );
    });
  });
});
