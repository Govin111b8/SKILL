const request = require('supertest');

jest.mock('../src/config/database', () => ({
  query: jest.fn(),
  pool: { end: jest.fn() },
}));

const { query } = require('../src/config/database');

describe('debug login', () => {
  it('login debug', async () => {
    const app = require('../src/app');
    const bcrypt = require('bcryptjs');
    const hashedPassword = await bcrypt.hash('password123', 10);

    query.mockResolvedValueOnce({ rows: [{ id: 'uuid-123', name: 'John Doe', email: 'john@example.com', password_hash: hashedPassword, phone: '1234567890', role: 'customer', location: 'New York' }] });
    query.mockResolvedValueOnce({ rows: [{ count: '0' }] });

    const res = await request(app).post('/api/auth/login').send({ email: 'john@example.com', password: 'password123' });
    console.log('STATUS:', res.statusCode);
    console.log('BODY:', JSON.stringify(res.body));
    console.log('QUERY calls:', query.mock.calls.length);
  });
});
