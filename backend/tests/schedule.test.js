/**
 * Schedule controller unit tests
 * Validates worker schedule CRUD, slot availability, and blocked dates.
 */
const { getSchedule, setSchedule, getAvailableSlots, blockDates, getBlockedDates } = require('../src/controllers/scheduleController');

// Mock database
jest.mock('../src/config/database', () => ({
  pool: {
    query: jest.fn(),
  },
}));

const { pool } = require('../src/config/database');

function mockReq(overrides = {}) {
  return {
    user: { id: 'user-1', role: 'professional' },
    params: {},
    body: {},
    query: {},
    ...overrides,
  };
}

function mockRes() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

describe('Schedule Controller', () => {
  beforeEach(() => {
    pool.query.mockReset();
  });

  describe('getSchedule', () => {
    it('returns 404 when professional not found', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] });

      const req = mockReq();
      const res = mockRes();
      const next = jest.fn();

      await getSchedule(req, res, next);

      expect(res.status).toHaveBeenCalledWith(404);
      expect(res.json).toHaveBeenCalledWith({ error: 'Professional profile not found' });
    });

    it('returns schedule for valid professional', async () => {
      const fakeSlots = [
        { day_of_week: 1, start_time: '09:00', end_time: '17:00', is_active: true },
      ];
      pool.query
        .mockResolvedValueOnce({ rows: [{ id: 'pro-1' }] }) // pro lookup
        .mockResolvedValueOnce({ rows: fakeSlots }); // schedule query

      const req = mockReq();
      const res = mockRes();
      const next = jest.fn();

      await getSchedule(req, res, next);

      expect(res.json).toHaveBeenCalledWith({ schedule: fakeSlots });
    });
  });

  describe('setSchedule', () => {
    it('returns 404 when professional not found', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] });

      const req = mockReq({ body: { slots: [] } });
      const res = mockRes();
      const next = jest.fn();

      await setSchedule(req, res, next);

      expect(res.status).toHaveBeenCalledWith(404);
    });

    it('clears and inserts new schedule', async () => {
      pool.query
        .mockResolvedValueOnce({ rows: [{ id: 'pro-1' }] }) // pro lookup
        .mockResolvedValueOnce({ rows: [] }) // delete
        .mockResolvedValueOnce({ rows: [] }) // insert
        .mockResolvedValueOnce({ rows: [{ day_of_week: 1, start_time: '09:00', end_time: '12:00' }] }); // return new

      const req = mockReq({
        body: { slots: [{ day_of_week: 1, start_time: '09:00', end_time: '12:00' }] },
      });
      const res = mockRes();
      const next = jest.fn();

      await setSchedule(req, res, next);

      expect(res.json).toHaveBeenCalled();
    });
  });

  describe('getAvailableSlots', () => {
    it('returns 400 if missing required params', async () => {
      const req = mockReq({ query: {} });
      const res = mockRes();
      const next = jest.fn();

      await getAvailableSlots(req, res, next);

      expect(res.status).toHaveBeenCalledWith(400);
    });

    it('returns empty slots when date is blocked', async () => {
      pool.query.mockResolvedValueOnce({ rows: [{ '?column?': 1 }] }); // blocked

      const req = mockReq({ query: { professional_id: 'p1', date: '2025-06-15' } });
      const res = mockRes();
      const next = jest.fn();

      await getAvailableSlots(req, res, next);

      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ slots: [], blocked: true })
      );
    });
  });

  describe('error handling', () => {
    it('calls next on database error', async () => {
      pool.query.mockRejectedValueOnce(new Error('connection failed'));

      const req = mockReq();
      const res = mockRes();
      const next = jest.fn();

      await getSchedule(req, res, next);

      expect(next).toHaveBeenCalledWith(expect.any(Error));
    });
  });
});
