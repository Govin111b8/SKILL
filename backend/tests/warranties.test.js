/**
 * Warranty controller unit tests
 * Validates warranty creation, claim workflow, resolve, and professional view.
 */
const { createWarranty, claimWarranty, getWarranties, resolveWarranty, getProfessionalWarranties } = require('../src/controllers/warrantyController');

jest.mock('../src/config/database', () => ({
  pool: { query: jest.fn() },
  query: jest.fn(),
}));
jest.mock('../src/utils/notifier', () => ({ notify: jest.fn().mockResolvedValue({}) }));

const { pool } = require('../src/config/database');

function mockReq(overrides = {}) {
  return { user: { id: 'user-1', role: 'customer' }, params: {}, body: {}, query: {}, ...overrides };
}

function mockRes() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

describe('Warranty Controller', () => {
  beforeEach(() => pool.query.mockReset());

  describe('createWarranty', () => {
    it('returns 404 when completed booking not found', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] }); // booking lookup
      const req = mockReq({ body: { booking_id: 'b1' } });
      const res = mockRes();
      await createWarranty(req, res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(404);
    });

    it('returns 409 when warranty already exists', async () => {
      pool.query.mockResolvedValueOnce({
        rows: [{ id: 'b1', professional_id: 'p1', customer_id: 'c1', category_id: 1, default_warranty_days: 7, completed_at: new Date() }],
      });
      pool.query.mockResolvedValueOnce({ rows: [{ id: 'w1' }] }); // existing warranty
      const req = mockReq({ body: { booking_id: 'b1' } });
      const res = mockRes();
      await createWarranty(req, res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(409);
    });

    it('creates warranty successfully', async () => {
      pool.query.mockResolvedValueOnce({
        rows: [{ id: 'b1', professional_id: 'p1', customer_id: 'c1', category_id: 1, default_warranty_days: 14, completed_at: new Date() }],
      });
      pool.query.mockResolvedValueOnce({ rows: [] }); // no existing
      pool.query.mockResolvedValueOnce({ rows: [{ id: 'w1', status: 'active', warranty_days: 14 }] });
      const req = mockReq({ body: { booking_id: 'b1' } });
      const res = mockRes();
      await createWarranty(req, res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(201);
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ warranty: expect.objectContaining({ id: 'w1' }) }));
    });
  });

  describe('claimWarranty', () => {
    it('returns 404 when active warranty not found for customer', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] });
      const req = mockReq({ user: { id: 'cust-1' }, params: { id: 'w1' }, body: { reason: 'issue' } });
      const res = mockRes();
      await claimWarranty(req, res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(404);
    });

    it('returns 400 when reason is missing', async () => {
      const req = mockReq({ user: { id: 'cust-1' }, params: { id: 'w1' }, body: {} });
      const res = mockRes();
      await claimWarranty(req, res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(400);
    });

    it('claims warranty and creates re-service booking', async () => {
      pool.query.mockResolvedValueOnce({
        rows: [{ id: 'w1', professional_id: 'p1', category_id: 1, customer_id: 'cust-1' }],
      });
      pool.query.mockResolvedValueOnce({ rows: [{ id: 'nb1' }] }); // new booking
      pool.query.mockResolvedValueOnce({ rows: [{ user_id: 'pro-user-1' }] }); // pro user
      pool.query.mockResolvedValueOnce({ rows: [] }); // notification insert
      const req = mockReq({ user: { id: 'cust-1' }, params: { id: 'w1' }, body: { reason: 'Water still leaking' } });
      const res = mockRes();
      await claimWarranty(req, res, jest.fn());
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ new_booking: expect.objectContaining({ id: 'nb1' }) }));
    });
  });

  describe('getWarranties', () => {
    it('returns warranties for current customer', async () => {
      pool.query.mockResolvedValueOnce({ rows: [{ id: 'w1', status: 'active' }] });
      const req = mockReq({ user: { id: 'cust-1' }, query: {} });
      const res = mockRes();
      await getWarranties(req, res, jest.fn());
      expect(res.json).toHaveBeenCalledWith({ warranties: [{ id: 'w1', status: 'active' }] });
    });

    it('filters by status when query param provided', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] });
      const req = mockReq({ user: { id: 'cust-1' }, query: { status: 'claimed' } });
      const res = mockRes();
      await getWarranties(req, res, jest.fn());
      expect(res.json).toHaveBeenCalledWith({ warranties: [] });
    });
  });

  describe('resolveWarranty', () => {
    it('returns 404 when claimed warranty not found for professional', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] });
      const req = mockReq({ user: { id: 'pro-user-1', role: 'professional' }, params: { id: 'w1' } });
      const res = mockRes();
      await resolveWarranty(req, res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(404);
    });

    it('resolves warranty and notifies customer', async () => {
      pool.query.mockResolvedValueOnce({ rows: [{ id: 'w1', customer_id: 'cust-1', status: 'resolved' }] });
      const req = mockReq({ user: { id: 'pro-user-1', role: 'professional' }, params: { id: 'w1' } });
      const res = mockRes();
      await resolveWarranty(req, res, jest.fn());
      expect(res.json).toHaveBeenCalledWith({ warranty: expect.objectContaining({ id: 'w1' }) });
    });
  });

  describe('getProfessionalWarranties', () => {
    it('returns 403 when user has no professional profile', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] }); // no professional row
      const req = mockReq({ user: { id: 'user-1', role: 'professional' }, query: {} });
      const res = mockRes();
      await getProfessionalWarranties(req, res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(403);
    });

    it('returns warranty claims for professional', async () => {
      pool.query.mockResolvedValueOnce({ rows: [{ id: 'p1' }] }); // professional lookup
      pool.query.mockResolvedValueOnce({ rows: [{ id: 'w1', status: 'claimed' }] });
      const req = mockReq({ user: { id: 'pro-user-1', role: 'professional' }, query: {} });
      const res = mockRes();
      await getProfessionalWarranties(req, res, jest.fn());
      expect(res.json).toHaveBeenCalledWith({ warranties: [{ id: 'w1', status: 'claimed' }] });
    });
  });
});
