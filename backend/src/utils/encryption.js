/**
 * AES-256-GCM encryption utilities for sensitive PII (government ID numbers).
 *
 * Each record gets its own random IV and authentication tag, making
 * ciphertext unique even for identical plaintext values.
 *
 * Key management:
 *   Set ENCRYPTION_KEY to a 64-character hex string (32 bytes / 256 bits).
 *   Generate one with: node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
 *
 *   In production use AWS KMS or HashiCorp Vault to store the key — set
 *   ENCRYPTION_KEY to the plaintext key value retrieved at startup from the
 *   secrets manager, never commit it to source control.
 *
 * Output format: base64(iv:authTag:ciphertext)  (all concatenated, colon-delimited)
 */

const crypto = require('crypto');
const logger = require('../config/logger');

const ALGORITHM = 'aes-256-gcm';
const IV_LENGTH = 12;  // 96-bit IV — recommended for GCM
const TAG_LENGTH = 16; // 128-bit authentication tag
const ENCODING = 'base64';

// Derive the 32-byte key from the environment variable.
// Falls back to a deterministic dev key so local development still works.
function getKey() {
  const envKey = process.env.ENCRYPTION_KEY || '';
  if (envKey && envKey.length >= 64) {
    return Buffer.from(envKey.slice(0, 64), 'hex');
  }
  if (process.env.NODE_ENV === 'production') {
    throw new Error('ENCRYPTION_KEY (64 hex chars) must be set in production');
  }
  // Dev fallback — never expose real data under this key
  logger.warn('ENCRYPTION_KEY not set — using insecure dev key. Never use in production!');
  return Buffer.from('0000000000000000000000000000000000000000000000000000000000000000', 'hex');
}

/**
 * Encrypt a plaintext string.
 * @param {string} plaintext
 * @returns {string} Encrypted payload: base64(iv + authTag + ciphertext)
 */
function encrypt(plaintext) {
  if (!plaintext) return '';
  const key = getKey();
  const iv = crypto.randomBytes(IV_LENGTH);
  const cipher = crypto.createCipheriv(ALGORITHM, key, iv);
  const encrypted = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final()]);
  const authTag = cipher.getAuthTag();
  // Pack: iv (12 bytes) + authTag (16 bytes) + ciphertext (variable)
  const combined = Buffer.concat([iv, authTag, encrypted]);
  return combined.toString(ENCODING);
}

/**
 * Decrypt a previously encrypted payload.
 * @param {string} ciphertext Base64 payload produced by encrypt()
 * @returns {string} Original plaintext, or empty string on failure
 */
function decrypt(ciphertext) {
  if (!ciphertext) return '';
  try {
    const key = getKey();
    const combined = Buffer.from(ciphertext, ENCODING);
    const iv = combined.subarray(0, IV_LENGTH);
    const authTag = combined.subarray(IV_LENGTH, IV_LENGTH + TAG_LENGTH);
    const encrypted = combined.subarray(IV_LENGTH + TAG_LENGTH);
    const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);
    decipher.setAuthTag(authTag);
    return decipher.update(encrypted) + decipher.final('utf8');
  } catch (err) {
    logger.error({ err }, 'Decryption failed — possible key mismatch or data corruption');
    return '';
  }
}

/**
 * SHA-256 hash of a value (for de-duplication lookups without storing plaintext).
 * @param {string} value
 * @returns {string} hex digest
 */
function hash(value) {
  return crypto.createHash('sha256').update(String(value)).digest('hex');
}

module.exports = { encrypt, decrypt, hash };
