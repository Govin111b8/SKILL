/**
 * Message controller unit tests
 * Validates thread listing and message sending logic.
 */
const messageController = require('../src/controllers/messageController');

// Mock database
jest.mock('../src/config/database', () => ({
  query: jest.fn(),
}));

// Mock realtime hub
jest.mock('../src/realtime/hub', () => ({
  emitToUser: jest.fn(),
}));

// Mock notifier
jest.mock('../src/utils/notifier', () => ({
  notify: jest.fn(),
}));

const { query } = require('../src/config/database');

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

describe('Message Controller', () => {
  beforeEach(() => {
    query.mockReset();
  });

  describe('listThreads', () => {
    it('returns empty data for professional with no profile', async () => {
      query.mockResolvedValueOnce({ rows: [] }); // no professional profile

      const req = mockReq({ user: { id: 'user-1', role: 'professional' } });
      const res = mockRes();
      const next = jest.fn();

      await messageController.listThreads(req, res, next);

      expect(res.json).toHaveBeenCalledWith({ success: true, data: [] });
    });

    it('returns threads for customer', async () => {
      const fakeThreads = [
        { id: 't1', other_name: 'Plumber Pro', last_message: 'Hi there' },
      ];
      query.mockResolvedValueOnce({ rows: fakeThreads });

      const req = mockReq({ user: { id: 'user-1', role: 'customer' } });
      const res = mockRes();
      const next = jest.fn();

      await messageController.listThreads(req, res, next);

      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: true }));
    });
  });

  describe('error handling', () => {
    it('calls next on database errors', async () => {
      query.mockRejectedValueOnce(new Error('db error'));

      const req = mockReq();
      const res = mockRes();
      const next = jest.fn();

      await messageController.listThreads(req, res, next);

      expect(next).toHaveBeenCalledWith(expect.any(Error));
    });
  });
});
