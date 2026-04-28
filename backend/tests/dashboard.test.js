const request = require('supertest');
const jwt = require('jsonwebtoken');
const app = require('../src/app');
const { query } = require('../src/config/database');

jest.mock('../src/config/database', () => ({
  query: jest.fn(),
  pool: { end: jest.fn() },
}));

process.env.JWT_SECRET = 'test-secret';
process.env.JWT_EXPIRES_IN = '7d';

const proToken = jwt.sign({ id: 'pro-user-1', email: 'p@x.com', role: 'professional' }, 'test-secret');
const custToken = jwt.sign({ id: 'cust-user-1', email: 'c@x.com', role: 'customer' }, 'test-secret');

describe('Dashboard analytics', () => {
  beforeEach(() => jest.clearAllMocks());

  it('professional dashboard returns earnings + funnel', async () => {
    // 1. profile lookup
    query.mockResolvedValueOnce({
      rows: [{
        id: 10, user_id: 'pro-user-1', name: 'Pro', headline: 'h', bio: 'b',
        years_of_experience: 3, pricing_estimate: '500', latitude: 17.4,
        completed_jobs: 5, response_time_hours: 2, trust_score: 80,
        availability_status: 'available',
      }]
    });
    // 2. review stats
    query.mockResolvedValueOnce({ rows: [{ avg_rating: 4.5, review_count: 12 }] });
    // 3. contact count
    query.mockResolvedValueOnce({ rows: [{ count: '7' }] });
    // 4. recent requests
    query.mockResolvedValueOnce({ rows: [] });
    // 5. portfolio
    query.mockResolvedValueOnce({ rows: [] });
    // 6. categories
    query.mockResolvedValueOnce({ rows: [{ id: 1, name: 'Plumbing' }] });
    // 7. funnel rows
    query.mockResolvedValueOnce({
      rows: [
        { status: 'requested', count: 4, revenue: 0 },
        { status: 'completed', count: 6, revenue: 30000 },
        { status: 'cancelled', count: 2, revenue: 0 },
      ]
    });
    // 8. earnings windows
    query.mockResolvedValueOnce({
      rows: [{ lifetime: 30000, this_month: 12000, last_7d: 4500, pipeline: 8000 }]
    });
    // 9. unread notifications
    query.mockResolvedValueOnce({ rows: [{ c: 3 }] });

    const res = await request(app).get('/api/dashboard').set('Authorization', `Bearer ${proToken}`);
    expect(res.status).toBe(200);
    expect(res.body.data.earnings).toEqual({
      lifetime: 30000, thisMonth: 12000, last7d: 4500, pipeline: 8000, currency: 'INR',
    });
    expect(res.body.data.funnel.requested).toBe(4);
    expect(res.body.data.funnel.completed).toBe(6);
    expect(res.body.data.funnel.cancelled).toBe(2);
    expect(res.body.data.funnel.totalBookings).toBe(12);
    // 6 / 12 = 50.0
    expect(res.body.data.funnel.conversionPct).toBe(50);
    expect(res.body.data.stats.unreadNotifications).toBe(3);
  });

  it('professional with no bookings has 0 conversion', async () => {
    query.mockResolvedValueOnce({
      rows: [{
        id: 11, user_id: 'pro-user-1', name: 'Pro', headline: 'h', bio: 'b',
        years_of_experience: 1, pricing_estimate: '300', latitude: null,
        completed_jobs: 0, trust_score: 0,
      }]
    });
    query.mockResolvedValueOnce({ rows: [{ avg_rating: 0, review_count: 0 }] });
    query.mockResolvedValueOnce({ rows: [{ count: '0' }] });
    query.mockResolvedValueOnce({ rows: [] });
    query.mockResolvedValueOnce({ rows: [] });
    query.mockResolvedValueOnce({ rows: [] });
    query.mockResolvedValueOnce({ rows: [] }); // empty funnel
    query.mockResolvedValueOnce({ rows: [{ lifetime: 0, this_month: 0, last_7d: 0, pipeline: 0 }] });
    query.mockResolvedValueOnce({ rows: [{ c: 0 }] });

    const res = await request(app).get('/api/dashboard').set('Authorization', `Bearer ${proToken}`);
    expect(res.status).toBe(200);
    expect(res.body.data.funnel.totalBookings).toBe(0);
    expect(res.body.data.funnel.conversionPct).toBe(0);
    expect(res.body.data.earnings.lifetime).toBe(0);
  });

  it('customer dashboard returns booking stats + favorites + unread', async () => {
    // contacts
    query.mockResolvedValueOnce({ rows: [] });
    // reviews given
    query.mockResolvedValueOnce({ rows: [] });
    // contact count
    query.mockResolvedValueOnce({ rows: [{ count: '4' }] });
    // review count
    query.mockResolvedValueOnce({ rows: [{ count: '2' }] });
    // booking stats
    query.mockResolvedValueOnce({
      rows: [{ total: 5, completed: 3, active: 2, total_spent: 15000 }]
    });
    // recent bookings
    query.mockResolvedValueOnce({ rows: [] });
    // favorites count
    query.mockResolvedValueOnce({ rows: [{ c: 6 }] });
    // unread
    query.mockResolvedValueOnce({ rows: [{ c: 1 }] });

    const res = await request(app).get('/api/dashboard').set('Authorization', `Bearer ${custToken}`);
    expect(res.status).toBe(200);
    const stats = res.body.data.stats;
    expect(stats.totalBookings).toBe(5);
    expect(stats.activeBookings).toBe(2);
    expect(stats.completedBookings).toBe(3);
    expect(stats.totalSpent).toBe(15000);
    expect(stats.favorites).toBe(6);
    expect(stats.unreadNotifications).toBe(1);
    expect(stats.totalContacts).toBe(4);
  });

  it('professional without profile gets needsProfile flag', async () => {
    query.mockResolvedValueOnce({ rows: [] }); // no profile
    const res = await request(app).get('/api/dashboard').set('Authorization', `Bearer ${proToken}`);
    expect(res.status).toBe(200);
    expect(res.body.data.needsProfile).toBe(true);
  });

  it('rejects unauthenticated request', async () => {
    const res = await request(app).get('/api/dashboard');
    expect(res.status).toBe(401);
  });
});
