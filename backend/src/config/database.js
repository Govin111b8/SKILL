const { Pool } = require('pg');
const { config } = require('./index');
const logger = require('./logger');

const pool = new Pool({
  host: config.db.host,
  port: config.db.port,
  database: config.db.name,
  user: config.db.user,
  password: config.db.password,
  max: config.db.maxConnections,
  idleTimeoutMillis: config.db.idleTimeout,
  connectionTimeoutMillis: config.db.connectionTimeout,
});

pool.on('error', (err) => {
  logger.error({ err }, 'Unexpected PostgreSQL pool error');
});

pool.on('connect', () => {
  logger.debug('New PostgreSQL client connected');
});

const query = (text, params) => pool.query(text, params);

module.exports = { pool, query };
