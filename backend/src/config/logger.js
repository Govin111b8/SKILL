/**
 * Structured logger using pino.
 * - JSON output in production for log aggregators
 * - Pretty-printed output in development
 * - Request correlation IDs via child loggers
 */

const pino = require('pino');
const { config } = require('./index');

const transport = config.isDevelopment
  ? { target: 'pino-pretty', options: { colorize: true, translateTime: 'SYS:HH:MM:ss', ignore: 'pid,hostname' } }
  : undefined;

const logger = pino({
  level: config.logging.level,
  ...(transport && { transport }),
  base: { service: 'skillconnect-api' },
  serializers: {
    err: pino.stdSerializers.err,
    req: (req) => ({
      method: req.method,
      url: req.url,
      remoteAddress: req.ip || req.remoteAddress,
    }),
    res: (res) => ({
      statusCode: res.statusCode,
    }),
  },
  redact: {
    // Mask sensitive fields at any nesting level — GDPR / DPDPA compliance
    paths: [
      'req.headers.authorization',
      'req.body.password',
      'req.body.password_hash',
      'req.body.phone',
      'req.body.email',
      'req.body.govt_id_number',
      'req.body.doc_number',
      '*.phone',
      '*.email',
      '*.govt_id_encrypted',
      '*.doc_number',
      '*.password',
      '*.password_hash',
    ],
    censor: '[MASKED]',
  },
});

module.exports = logger;
