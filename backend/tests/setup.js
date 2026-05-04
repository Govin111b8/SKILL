// Jest setup file — runs before any test module is loaded.
// Sets environment variables so that config/index.js picks them up at module
// load time (config values are evaluated once when the module is first required).
process.env.JWT_SECRET = 'test-secret';
process.env.NODE_ENV = 'test';
