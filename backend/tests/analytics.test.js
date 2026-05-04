/**
 * Analytics controller unit tests
 * Validates professional analytics dashboard and event ingestion.
 */
const { getAnalytics } = require('../src/controllers/analyticsController');
const { ingestEvents, getFunnelAnalytics } = require('../src/controllers/analyticsEventsController');

jest.mock('../src/config/database', () => ({
  query: jest.fn(),
  pool: { end: jest.fn() },
}));

const { query } = require('../src/config/database');

function mockReq(overrides = {}) {
  return { user: { id: 'user-1', role: 'customer' }, params: {}, body: {}, query: {}, ...overrides };
}

function mockRes() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

describe('Analytics Controller', () => {
  beforeEach(() => query.mockReset());

  describe('getAnalytics', () => {
    it('returns 403 for customer role', async () => {
      const req = mockReq({ user: { id: 'user-1', role: 'customer' } });
      const res = mockRes();
      await getAnalytics(req, res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(403);
    });

    it('returns 404 when professional profile not found', async () => {
      query.mockResolvedValueOnce({ rows: [] });
      const req = mockReq({ user: { id: 'user-pro-1', role: 'professional' } });
      const res = mockRes();
      await getAnalytics(req, res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(404);
    });

    it('returns full analytics data for professional', async () => {
      query.mockResolvedValueOnce({ rows: [{ id: 'p1' }] }); // professional lookup
      query.mockResolvedValueOnce({ rows: [{ month: '2024-01-01', earnings: 5000, bookings_completed: 10 }] }); // monthly
      query.mockResolvedValueOnce({ rows: [{ week: '2024-01-01', total: 5, completed: 4, cancelled: 1 }] }); // weekly
      query.mockResolvedValueOnce({ rows: [{ rating: 5, count: 8 }, { rating: 4, count: 2 }] }); // ratings
      query.mockResolvedValueOnce({ rows: [{ name: 'Alice', bookings: 5, total_spent: 2500 }] }); // top customers
      query.mockResolvedValueOnce({ rows: [{ bookings_7d: 3, bookings_30d: 12, completed_30d: 10 }] }); // recent activity
      const req = mockReq({ user: { id: 'user-pro-1', role: 'professional' } });
      const res = mockRes();
      await getAnalytics(req, res, jest.fn());
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
        success: true,
        data: expect.objectContaining({
          monthlyEarnings: expect.arrayContaining([expect.objectContaining({ earnings: 5000 })]),
          topCustomers: expect.arrayContaining([expect.objectContaining({ name: 'Alice' })]),
        }),
      }));
    });
  });

  describe('ingestEvents', () => {
    it('returns 400 when events array is missing', async () => {
      const req = mockReq({ user: null, body: {} });
      const res = mockRes();
      await ingestEvents(req, res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: false }));
    });

    it('returns 400 when events array is empty', async () => {
      const req = mockReq({ user: null, body: { events: [] } });
      const res = mockRes();
      await ingestEvents(req, res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(400);
    });

    it('ingests events successfully', async () => {
      query.mockResolvedValueOnce({ rows: [] }); // batch insert
      const req = mockReq({
        user: { id: 'user-1' },
        body: {
          events: [
            { event: 'searchCompleted', timestamp: new Date().toISOString(), properties: { query: 'plumber' } },
            { event: 'providerProfileViewed', timestamp: new Date().toISOString(), properties: { provider_id: 'p1' } },
          ],
          session_id: 'sess-abc',
        },
      });
      const res = mockRes();
      await ingestEvents(req, res, jest.fn());
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: true, ingested: 2 }));
    });

    it('caps events at 100 per batch', async () => {
      query.mockResolvedValueOnce({ rows: [] });
      const events = Array.from({ length: 150 }, (_, i) => ({ event: `event_${i}` }));
      const req = mockReq({ user: { id: 'user-1' }, body: { events } });
      const res = mockRes();
      await ingestEvents(req, res, jest.fn());
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: true, ingested: 100 }));
    });
  });

  describe('getFunnelAnalytics', () => {
    it('returns funnel and dropoff data', async () => {
      query.mockResolvedValueOnce({ rows: [
        { event_name: 'searchCompleted', unique_users: 100, total_events: 150 },
        { event_name: 'bookingConfirmed', unique_users: 20, total_events: 25 },
      ]});
      query.mockResolvedValueOnce({ rows: [] }); // dropoffs
      const req = mockReq({ user: { id: 'admin-1', role: 'admin' }, query: { days: '30' } });
      const res = mockRes();
      await getFunnelAnalytics(req, res, jest.fn());
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
        success: true,
        data: expect.objectContaining({
          funnel: expect.arrayContaining([expect.objectContaining({ event_name: 'searchCompleted' })]),
          period_days: 30,
        }),
      }));
    });
  });
});
