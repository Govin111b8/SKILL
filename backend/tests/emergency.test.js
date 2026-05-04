/**
 * Emergency controller unit tests
 * Validates emergency request creation, acceptance, listing, SOS, and resolution.
 */
const { createEmergency, acceptEmergency, listEmergencies, triggerSOS, resolveEmergency } = require('../src/controllers/emergencyController');

jest.mock('../src/config/database', () => ({
  pool: { query: jest.fn() },
}));
jest.mock('../src/realtime/hub', () => ({
  sendTo: jest.fn(),
  broadcast: jest.fn(),
}));

const { pool } = require('../src/config/database');
const hub = require('../src/realtime/hub');

function mockReq(overrides = {}) {
  return { user: { id: 'user-1', role: 'customer' }, params: {}, body: {}, query: {}, ...overrides };
}

function mockRes() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

describe('Emergency Controller', () => {
  beforeEach(() => {
    pool.query.mockReset();
    hub.sendTo.mockReset();
  });

  describe('createEmergency', () => {
    it('creates emergency and returns notified professional count', async () => {
      pool.query.mockResolvedValueOnce({
        rows: [{ id: 'e1', customer_id: 'user-1', description: 'Water leak', status: 'active' }],
      });
      // No nearby pros (no location provided)
      pool.query.mockResolvedValueOnce({ rows: [] }); // customer name lookup (won't run without pros)
      const req = mockReq({
        body: { description: 'Water leak', category_id: 1 },
      });
      const res = mockRes();
      await createEmergency(req, res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(201);
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
        emergency: expect.objectContaining({ id: 'e1' }),
        notified_professionals: 0,
      }));
    });

    it('notifies nearby professionals via DB and WebSocket when location provided', async () => {
      pool.query.mockResolvedValueOnce({
        rows: [{ id: 'e2', customer_id: 'user-1', description: 'Gas leak', status: 'active' }],
      });
      pool.query.mockResolvedValueOnce({
        rows: [{ id: 'p1', user_id: 'pro-user-1', name: 'John', distance_km: 2.3 }],
      });
      pool.query.mockResolvedValueOnce({ rows: [] }); // notification insert
      pool.query.mockResolvedValueOnce({ rows: [{ name: 'Alice' }] }); // customer name
      const req = mockReq({
        body: { description: 'Gas leak', category_id: 2, location_lat: 17.38, location_lng: 78.48 },
      });
      const res = mockRes();
      await createEmergency(req, res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(201);
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ notified_professionals: 1 }));
      expect(hub.sendTo).toHaveBeenCalledWith('pro-user-1', expect.objectContaining({ type: 'emergency', action: 'new' }));
    });
  });

  describe('acceptEmergency', () => {
    it('returns 403 if non-professional tries to accept', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] }); // no professional row
      const req = mockReq({ user: { id: 'user-1', role: 'customer' }, params: { id: 'e1' } });
      const res = mockRes();
      await acceptEmergency(req, res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(403);
    });

    it('returns 404 when emergency not found or already assigned', async () => {
      pool.query.mockResolvedValueOnce({ rows: [{ id: 'p1' }] }); // professional found
      pool.query.mockResolvedValueOnce({ rows: [] }); // emergency not found
      const req = mockReq({ user: { id: 'pro-user-1', role: 'professional' }, params: { id: 'e99' } });
      const res = mockRes();
      await acceptEmergency(req, res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(404);
    });

    it('accepts emergency and notifies customer', async () => {
      pool.query.mockResolvedValueOnce({ rows: [{ id: 'p1' }] });
      pool.query.mockResolvedValueOnce({
        rows: [{ id: 'e1', customer_id: 'cust-1', status: 'assigned', assigned_professional_id: 'p1' }],
      });
      pool.query.mockResolvedValueOnce({ rows: [] }); // notification insert
      const req = mockReq({ user: { id: 'pro-user-1', role: 'professional' }, params: { id: 'e1' } });
      const res = mockRes();
      await acceptEmergency(req, res, jest.fn());
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
        emergency: expect.objectContaining({ status: 'assigned' }),
      }));
    });
  });

  describe('triggerSOS', () => {
    it('creates safety alert and notifies user', async () => {
      pool.query.mockResolvedValueOnce({ rows: [{ id: 'sa1' }] }); // alert insert
      pool.query.mockResolvedValueOnce({ rows: [] }); // notification
      const req = mockReq({
        body: { booking_id: 'b1', location_lat: 17.38, location_lng: 78.48 },
      });
      const res = mockRes();
      await triggerSOS(req, res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(201);
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
        alert: expect.objectContaining({ id: 'sa1' }),
      }));
    });
  });

  describe('resolveEmergency', () => {
    it('returns 403 if non-professional tries to resolve', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] });
      const req = mockReq({ user: { id: 'user-1', role: 'customer' }, params: { id: 'e1' } });
      const res = mockRes();
      await resolveEmergency(req, res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(403);
    });

    it('returns 404 when assigned emergency not found', async () => {
      pool.query.mockResolvedValueOnce({ rows: [{ id: 'p1' }] });
      pool.query.mockResolvedValueOnce({ rows: [] });
      const req = mockReq({ user: { id: 'pro-user-1', role: 'professional' }, params: { id: 'e99' } });
      const res = mockRes();
      await resolveEmergency(req, res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(404);
    });

    it('resolves emergency and notifies customer', async () => {
      pool.query.mockResolvedValueOnce({ rows: [{ id: 'p1' }] });
      pool.query.mockResolvedValueOnce({ rows: [{ id: 'e1', customer_id: 'cust-1', status: 'resolved' }] });
      pool.query.mockResolvedValueOnce({ rows: [] }); // notification
      const req = mockReq({ user: { id: 'pro-user-1', role: 'professional' }, params: { id: 'e1' } });
      const res = mockRes();
      await resolveEmergency(req, res, jest.fn());
      expect(res.json).toHaveBeenCalledWith({ emergency: expect.objectContaining({ id: 'e1' }) });
      expect(hub.sendTo).toHaveBeenCalledWith('cust-1', expect.objectContaining({ type: 'emergency', action: 'resolved' }));
    });
  });
});
