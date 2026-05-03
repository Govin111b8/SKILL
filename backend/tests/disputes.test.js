/**
 * Dispute controller unit tests
 * Validates dispute creation logic, access control, and evidence handling.
 */
const { createDispute, listDisputes, getDispute, addEvidence } = require('../src/controllers/disputeController');

// Mock database
jest.mock('../src/config/database', () => ({
  pool: {
    query: jest.fn(),
  },
}));

const { pool } = require('../src/config/database');

function mockReq(overrides = {}) {
  return {
    user: { id: 'user-1', role: 'customer' },
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

describe('Dispute Controller', () => {
  beforeEach(() => {
    pool.query.mockReset();
  });

  describe('createDispute', () => {
    it('returns 404 when booking not found', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] });

      const req = mockReq({
        body: { booking_id: 'b1', reason: 'bad service', description: 'broken' },
      });
      const res = mockRes();
      const next = jest.fn();

      await createDispute(req, res, next);

      expect(res.status).toHaveBeenCalledWith(404);
      expect(res.json).toHaveBeenCalledWith({ error: 'Booking not found' });
    });

    it('returns 403 when user is not part of booking', async () => {
      pool.query.mockResolvedValueOnce({
        rows: [{ customer_id: 'other-user', pro_user_id: 'pro-user' }],
      });

      const req = mockReq({
        body: { booking_id: 'b1', reason: 'bad', description: 'issue' },
      });
      const res = mockRes();
      const next = jest.fn();

      await createDispute(req, res, next);

      expect(res.status).toHaveBeenCalledWith(403);
      expect(res.json).toHaveBeenCalledWith({ error: 'You are not part of this booking' });
    });

    it('creates dispute and returns 201 on success', async () => {
      const fakeBooking = { id: 'b1', customer_id: 'user-1', pro_user_id: 'pro-1', title: 'Plumbing' };
      const fakeDispute = { id: 'd1', booking_id: 'b1', reason: 'bad' };

      pool.query
        .mockResolvedValueOnce({ rows: [fakeBooking] }) // booking lookup
        .mockResolvedValueOnce({ rows: [fakeDispute] }) // insert dispute
        .mockResolvedValueOnce({ rows: [] }) // update booking
        .mockResolvedValueOnce({ rows: [] }); // notification

      const req = mockReq({
        body: { booking_id: 'b1', reason: 'bad', description: 'issue' },
      });
      const res = mockRes();
      const next = jest.fn();

      await createDispute(req, res, next);

      expect(res.status).toHaveBeenCalledWith(201);
      expect(res.json).toHaveBeenCalledWith({ dispute: fakeDispute });
    });

    it('calls next on database errors', async () => {
      pool.query.mockRejectedValueOnce(new Error('db fail'));

      const req = mockReq({ body: { booking_id: 'b1', reason: 'x', description: 'y' } });
      const res = mockRes();
      const next = jest.fn();

      await createDispute(req, res, next);

      expect(next).toHaveBeenCalledWith(expect.any(Error));
    });
  });
});
