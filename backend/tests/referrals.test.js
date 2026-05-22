/**
 * Referral controller unit tests
 * Validates code generation, code application, referral stats, and reward logic.
 */
const { generateCode, applyCode, getReferralStats, getLoyaltyHistory } = require('../src/controllers/referralController');

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

describe('Referral Controller', () => {
  beforeEach(() => pool.query.mockReset());

  describe('generateCode', () => {
    it('returns existing code if user already has one', async () => {
      pool.query.mockResolvedValueOnce({ rows: [{ id: 'rc1', code: 'SKABCD1234', reward_amount: 200 }] });
      const req = mockReq();
      const res = mockRes();
      await generateCode(req, res, jest.fn());
      expect(res.json).toHaveBeenCalledWith({ referral_code: expect.objectContaining({ code: 'SKABCD1234' }) });
    });

    it('creates a new referral code when none exists', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] }); // no existing code
      pool.query.mockResolvedValueOnce({ rows: [{ id: 'rc2', code: 'SKNEW1234', reward_amount: 200 }] }); // insert
      pool.query.mockResolvedValueOnce({ rows: [] }); // update users.referral_code
      const req = mockReq();
      const res = mockRes();
      await generateCode(req, res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(201);
      expect(res.json).toHaveBeenCalledWith({ referral_code: expect.objectContaining({ id: 'rc2' }) });
    });
  });

  describe('applyCode', () => {
    it('returns 400 if user already used a referral code', async () => {
      pool.query.mockResolvedValueOnce({ rows: [{ id: 'r1' }] }); // existing referral
      const req = mockReq({ body: { code: 'SKTEST001' } });
      const res = mockRes();
      await applyCode(req, res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ error: 'You have already used a referral code' }));
    });

    it('returns 404 for invalid or expired code', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] }); // no existing referral
      pool.query.mockResolvedValueOnce({ rows: [] }); // code lookup fails
      const req = mockReq({ body: { code: 'BADINVALID' } });
      const res = mockRes();
      await applyCode(req, res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(404);
    });

    it('returns 400 when user tries to use own code', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] }); // no existing referral
      pool.query.mockResolvedValueOnce({ rows: [{ id: 'rc1', user_id: 'user-1', reward_amount: 200 }] }); // own code
      const req = mockReq({ body: { code: 'SKOWN0001' } });
      const res = mockRes();
      await applyCode(req, res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ error: 'Cannot use your own referral code' }));
    });

    it('applies code successfully and creates referral record', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] }); // no existing referral for this user
      pool.query.mockResolvedValueOnce({ rows: [{ id: 'rc1', user_id: 'referrer-1', reward_amount: 200 }] }); // valid code
      pool.query.mockResolvedValueOnce({ rows: [] }); // no duplicate pair
      pool.query.mockResolvedValueOnce({ rows: [{ id: 'ref1', referrer_id: 'referrer-1', referred_id: 'user-1' }] }); // insert referral
      pool.query.mockResolvedValueOnce({ rows: [] }); // update uses_count
      pool.query.mockResolvedValueOnce({ rows: [] }); // update users.referred_by
      const req = mockReq({ body: { code: 'SKOTHER1' } });
      const res = mockRes();
      await applyCode(req, res, jest.fn());
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
        referral: expect.objectContaining({ id: 'ref1' }),
        message: expect.stringContaining('Referral code applied'),
      }));
    });
  });

  describe('getReferralStats', () => {
    it('returns complete referral stats for user', async () => {
      pool.query.mockResolvedValueOnce({ rows: [{ id: 'rc1', code: 'SKTEST', reward_amount: 200, uses_count: 3 }] });
      pool.query.mockResolvedValueOnce({ rows: [
        { id: 'r1', referred_name: 'Alice', status: 'completed' },
        { id: 'r2', referred_name: 'Bob', status: 'pending' },
      ]});
      pool.query.mockResolvedValueOnce({ rows: [{ loyalty_balance: 400 }] });
      const req = mockReq();
      const res = mockRes();
      await getReferralStats(req, res, jest.fn());
      const result = res.json.mock.calls[0][0];
      expect(result.total_referrals).toBe(2);
      expect(result.completed_referrals).toBe(1);
      expect(result.loyalty_balance).toBe(400);
    });

    it('returns zeros when user has no referrals', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] }); // no referral code
      pool.query.mockResolvedValueOnce({ rows: [] }); // no referrals
      pool.query.mockResolvedValueOnce({ rows: [{ loyalty_balance: 0 }] });
      const req = mockReq();
      const res = mockRes();
      await getReferralStats(req, res, jest.fn());
      const result = res.json.mock.calls[0][0];
      expect(result.referral_code).toBeNull();
      expect(result.total_referrals).toBe(0);
    });
  });

  describe('getLoyaltyHistory', () => {
    it('returns points history with balance', async () => {
      pool.query.mockResolvedValueOnce({ rows: [
        { id: 'lp1', points: 200, reason: 'Referral reward', created_at: new Date() },
      ]});
      pool.query.mockResolvedValueOnce({ rows: [{ loyalty_balance: 200 }] });
      const req = mockReq({ query: {} });
      const res = mockRes();
      await getLoyaltyHistory(req, res, jest.fn());
      const result = res.json.mock.calls[0][0];
      expect(result.points).toHaveLength(1);
      expect(result.balance).toBe(200);
    });
  });
});
