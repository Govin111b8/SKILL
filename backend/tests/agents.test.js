/**
 * Agent controller unit tests
 * Validates agent registration, dashboard, onboarding, wallet, leaderboard.
 */
const { becomeAgent, getAgentDashboard, onboardProvider, onboardCustomer, getWallet, getLeaderboard, getZones } = require('../src/controllers/agentController');

jest.mock('../src/config/database', () => ({
  pool: { query: jest.fn() },
}));

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

describe('Agent Controller', () => {
  beforeEach(() => pool.query.mockReset());

  describe('becomeAgent', () => {
    it('returns 400 when user is already an agent', async () => {
      pool.query.mockResolvedValueOnce({ rows: [{ id: 'ag1' }] });
      const req = mockReq({ body: { zone: 'Hyderabad' } });
      const res = mockRes();
      await becomeAgent(req, res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ error: 'You are already registered as an agent' }));
    });

    it('registers user as agent successfully', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] }); // no existing agent
      pool.query.mockResolvedValueOnce({ rows: [{ id: 'ag1', agent_code: 'AGTEST123', zone: 'Hyderabad' }] }); // insert
      pool.query.mockResolvedValueOnce({ rows: [] }); // update user role
      const req = mockReq({ body: { zone: 'Hyderabad' } });
      const res = mockRes();
      await becomeAgent(req, res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(201);
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
        success: true,
        agent: expect.objectContaining({ id: 'ag1' }),
      }));
    });
  });

  describe('getAgentDashboard', () => {
    it('returns 404 when agent profile not found', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] });
      const req = mockReq({ user: { id: 'user-1', role: 'agent' } });
      const res = mockRes();
      await getAgentDashboard(req, res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(404);
    });

    it('returns full dashboard data for agent', async () => {
      pool.query.mockResolvedValueOnce({ rows: [{ id: 'ag1', agent_code: 'AGTEST1', wallet_balance: 500, total_earned: 1000, providers_onboarded: 5, customers_onboarded: 10, level: 'silver', zone: 'Hyderabad', kyc_verified: true }] });
      pool.query.mockResolvedValueOnce({ rows: [] }); // onboarded users
      pool.query.mockResolvedValueOnce({ rows: [{ action: 'provider_onboarded', count: 5, total_amount: 500, total_points: 250 }] }); // reward summary
      pool.query.mockResolvedValueOnce({ rows: [{ status: 'pending', count: 2, total: 200 }] }); // reward status
      pool.query.mockResolvedValueOnce({ rows: [] }); // transactions
      const req = mockReq({ user: { id: 'user-1', role: 'agent' } });
      const res = mockRes();
      await getAgentDashboard(req, res, jest.fn());
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
        success: true,
        agent: expect.objectContaining({ id: 'ag1' }),
      }));
    });
  });

  describe('onboardProvider', () => {
    it('returns 403 if not an active agent', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] }); // no agent
      const req = mockReq({ body: { name: 'John', email: 'j@e.com', password: 'pass1234', phone: '9876543210' } });
      const res = mockRes();
      await onboardProvider(req, res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(403);
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ error: 'Not an active agent' }));
    });

    it('returns 403 when agent KYC not verified', async () => {
      pool.query.mockResolvedValueOnce({ rows: [{ id: 'ag1', kyc_verified: false }] });
      const req = mockReq({ body: { name: 'John', email: 'j@e.com', password: 'pass1234', phone: '9876543210' } });
      const res = mockRes();
      await onboardProvider(req, res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(403);
    });

    it('returns 400 when email already registered', async () => {
      pool.query.mockResolvedValueOnce({ rows: [{ id: 'ag1', kyc_verified: true, zone: 'HYD' }] });
      pool.query.mockResolvedValueOnce({ rows: [{ id: 'existing-user' }] }); // email exists
      const req = mockReq({ body: { name: 'John', email: 'exists@e.com', password: 'pass1234', phone: '9876543210' } });
      const res = mockRes();
      await onboardProvider(req, res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ error: 'Email already registered' }));
    });

    it('onboards provider successfully', async () => {
      pool.query.mockResolvedValueOnce({ rows: [{ id: 'ag1', kyc_verified: true, zone: 'HYD' }] });
      pool.query.mockResolvedValueOnce({ rows: [] }); // email check
      pool.query.mockResolvedValueOnce({ rows: [{ id: 'new-user-1', name: 'John', email: 'j@e.com', role: 'professional' }] }); // insert user
      pool.query.mockResolvedValueOnce({ rows: [] }); // insert professional
      pool.query.mockResolvedValueOnce({ rows: [] }); // agent_onboarded_users
      pool.query.mockResolvedValueOnce({ rows: [] }); // update agent stats
      pool.query.mockResolvedValueOnce({ rows: [{ id: 1, points: 50, amount: 100 }] }); // reward config
      pool.query.mockResolvedValueOnce({ rows: [] }); // insert reward
      const req = mockReq({
        body: { name: 'John', email: 'j@e.com', password: 'pass1234', phone: '9876543210', location: 'HYD' },
      });
      const res = mockRes();
      await onboardProvider(req, res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(201);
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
        success: true,
        user: expect.objectContaining({ id: 'new-user-1' }),
      }));
    });
  });

  describe('getWallet', () => {
    it('returns 404 when agent not found', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] });
      const req = mockReq({ user: { id: 'user-1', role: 'agent' } });
      const res = mockRes();
      await getWallet(req, res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(404);
    });

    it('returns wallet balance and transactions', async () => {
      pool.query.mockResolvedValueOnce({ rows: [{ id: 'ag1', wallet_balance: 500, total_earned: 1000 }] });
      pool.query.mockResolvedValueOnce({ rows: [
        { id: 't1', type: 'credit', amount: 100, balance_after: 500, description: 'Reward', created_at: new Date() },
      ]});
      const req = mockReq({ user: { id: 'user-1', role: 'agent' } });
      const res = mockRes();
      await getWallet(req, res, jest.fn());
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
        success: true,
        wallet: expect.objectContaining({ balance: 500, total_earned: 1000 }),
        transactions: expect.arrayContaining([expect.objectContaining({ id: 't1' })]),
      }));
    });
  });

  describe('getLeaderboard', () => {
    it('returns leaderboard sorted by total_earned', async () => {
      pool.query.mockResolvedValueOnce({ rows: [
        { agent_code: 'AG001', zone: 'Hyderabad', level: 'gold', providers_onboarded: 20, customers_onboarded: 50, total_earned: 5000, name: 'Alice' },
        { agent_code: 'AG002', zone: 'Bangalore', level: 'silver', providers_onboarded: 10, customers_onboarded: 25, total_earned: 2500, name: 'Bob' },
      ]});
      const req = mockReq({ query: {} });
      const res = mockRes();
      await getLeaderboard(req, res, jest.fn());
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
        success: true,
        leaderboard: expect.arrayContaining([expect.objectContaining({ agent_code: 'AG001' })]),
      }));
    });

    it('filters leaderboard by zone when provided', async () => {
      pool.query.mockResolvedValueOnce({ rows: [
        { agent_code: 'AG001', zone: 'Hyderabad', level: 'gold', providers_onboarded: 20, customers_onboarded: 50, total_earned: 5000, name: 'Alice' },
      ]});
      const req = mockReq({ query: { zone: 'Hyderabad' } });
      const res = mockRes();
      await getLeaderboard(req, res, jest.fn());
      const result = res.json.mock.calls[0][0];
      expect(result.leaderboard).toHaveLength(1);
    });
  });

  describe('getZones', () => {
    it('returns active zones', async () => {
      pool.query.mockResolvedValueOnce({ rows: [
        { id: 1, name: 'Hyderabad', state: 'Telangana', phase: 1 },
        { id: 2, name: 'Bangalore', state: 'Karnataka', phase: 1 },
      ]});
      const req = mockReq({ query: {} });
      const res = mockRes();
      await getZones(req, res, jest.fn());
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
        success: true,
        zones: expect.arrayContaining([expect.objectContaining({ name: 'Hyderabad' })]),
      }));
    });
  });
});
