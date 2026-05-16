/**
 * SMS/OTP Service — Twilio or MSG91 integration
 *
 * Required env vars:
 *   SMS_PROVIDER ('twilio' or 'msg91')
 *   For Twilio: TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_PHONE_NUMBER
 *   For MSG91: MSG91_AUTH_KEY, MSG91_SENDER_ID, MSG91_TEMPLATE_ID
 */

const crypto = require('crypto');
const logger = require('../config/logger');
const { withRetry } = require('../utils/retry');
const redis = require('../config/redis');

const SMS_PROVIDER = process.env.SMS_PROVIDER || 'none';

// In-memory OTP fallback (used when Redis is unavailable)
const otpStore = new Map();
const OTP_EXPIRY_SECONDS = 10 * 60; // 10 minutes
const OTP_EXPIRY_MS = OTP_EXPIRY_SECONDS * 1000;
const MAX_ATTEMPTS = 3;
const RESEND_COOLDOWN_SECONDS = 60; // 1 minute
const RESEND_COOLDOWN_MS = RESEND_COOLDOWN_SECONDS * 1000;

/** Redis key prefix for OTP records */
const OTP_PREFIX = 'otp:';

/**
 * Generate a numeric OTP
 */
function generateOTP() {
  return crypto.randomInt(100000, 999999).toString();
}

/**
 * Send SMS via Twilio
 */
async function sendViaTwilio(phone, message) {
  const accountSid = process.env.TWILIO_ACCOUNT_SID;
  const authToken = process.env.TWILIO_AUTH_TOKEN;
  const fromNumber = process.env.TWILIO_PHONE_NUMBER;

  const response = await fetch(
    `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`,
    {
      method: 'POST',
      headers: {
        'Authorization': 'Basic ' + Buffer.from(`${accountSid}:${authToken}`).toString('base64'),
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        To: phone,
        From: fromNumber,
        Body: message,
      }),
    }
  );

  if (!response.ok) {
    const err = await response.json();
    logger.error({ phone, err }, 'Twilio SMS failed');
    throw new Error(`SMS send failed: ${err.message}`);
  }

  return response.json();
}

/**
 * Send SMS via MSG91
 */
async function sendViaMSG91(phone, message) {
  const authKey = process.env.MSG91_AUTH_KEY;

  const response = await fetch('https://control.msg91.com/api/v5/flow/', {
    method: 'POST',
    headers: {
      'authkey': authKey,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      template_id: process.env.MSG91_TEMPLATE_ID,
      sender: process.env.MSG91_SENDER_ID || 'SKILCN',
      mobiles: phone.replace('+', ''),
      otp: message, // For OTP templates
    }),
  });

  if (!response.ok) {
    const err = await response.text();
    logger.error({ phone, err }, 'MSG91 SMS failed');
    throw new Error('SMS send failed via MSG91');
  }

  return response.json();
}

/**
 * Send SMS (dispatches to configured provider)
 */
async function sendSMS(phone, message) {
  if (SMS_PROVIDER === 'twilio') {
    return withRetry(() => sendViaTwilio(phone, message), { maxRetries: 2, baseDelay: 1000, serviceName: 'sms-twilio' });
  } else if (SMS_PROVIDER === 'msg91') {
    return withRetry(() => sendViaMSG91(phone, message), { maxRetries: 2, baseDelay: 1000, serviceName: 'sms-msg91' });
  } else {
    logger.warn({ phone, message: message.substring(0, 50) }, 'SMS not configured — logged only');
    return { success: true, simulated: true };
  }
}

/**
 * Send OTP to phone number.
 * Stores OTP in Redis when available; falls back to in-memory Map.
 *
 * @param {string} phone - Phone number with country code (e.g., +91XXXXXXXXXX)
 * @param {string} purpose - 'phone_verification' | 'login' | 'password_reset'
 */
async function sendOTP(phone, purpose = 'phone_verification') {
  const redisKey = `${OTP_PREFIX}${phone}:${purpose}`;
  const memKey = `${phone}:${purpose}`;

  if (redis.isAvailable()) {
    // ---- Redis path ----
    const existing = await redis.get(redisKey);
    if (existing) {
      const elapsed = Date.now() - existing.createdAt;
      if (elapsed < RESEND_COOLDOWN_MS) {
        const waitSeconds = Math.ceil((RESEND_COOLDOWN_MS - elapsed) / 1000);
        return { success: false, error: `Please wait ${waitSeconds}s before requesting a new OTP` };
      }
    }

    const otp = generateOTP();
    await redis.set(redisKey, { otp, createdAt: Date.now(), attempts: 0 }, OTP_EXPIRY_SECONDS);

    const message = `Your SkillConnect verification code is: ${otp}. Valid for 10 minutes. Do not share this code.`;
    await sendSMS(phone, message);

    logger.info({ phone, purpose }, 'OTP sent (Redis)');
    return { success: true, expiresIn: OTP_EXPIRY_SECONDS };
  }

  // ---- In-memory fallback ----
  const existing = otpStore.get(memKey);
  if (existing && Date.now() - existing.createdAt < RESEND_COOLDOWN_MS) {
    const waitSeconds = Math.ceil((RESEND_COOLDOWN_MS - (Date.now() - existing.createdAt)) / 1000);
    return { success: false, error: `Please wait ${waitSeconds}s before requesting a new OTP` };
  }

  const otp = generateOTP();
  otpStore.set(memKey, { otp, createdAt: Date.now(), attempts: 0, verified: false });
  setTimeout(() => otpStore.delete(memKey), OTP_EXPIRY_MS);

  const message = `Your SkillConnect verification code is: ${otp}. Valid for 10 minutes. Do not share this code.`;
  await sendSMS(phone, message);

  logger.info({ phone, purpose }, 'OTP sent (in-memory)');
  return { success: true, expiresIn: OTP_EXPIRY_SECONDS };
}

/**
 * Verify OTP.
 * Reads from Redis when available; falls back to in-memory Map.
 *
 * @param {string} phone
 * @param {string} otp
 * @param {string} purpose
 */
async function verifyOTP(phone, otp, purpose = 'phone_verification') {
  const redisKey = `${OTP_PREFIX}${phone}:${purpose}`;
  const memKey = `${phone}:${purpose}`;

  if (redis.isAvailable()) {
    // ---- Redis path ----
    const record = await redis.get(redisKey);

    if (!record) {
      return { success: false, error: 'OTP expired or not found. Please request a new one.' };
    }
    if (record.verified) {
      return { success: false, error: 'OTP already used.' };
    }
    if (record.attempts >= MAX_ATTEMPTS) {
      await redis.del(redisKey);
      return { success: false, error: 'Too many attempts. Please request a new OTP.' };
    }

    record.attempts++;

    if (record.otp !== otp) {
      await redis.set(redisKey, record, OTP_EXPIRY_SECONDS);
      return { success: false, error: `Invalid OTP. ${MAX_ATTEMPTS - record.attempts} attempts remaining.` };
    }

    // Mark as used and let it expire naturally (prevents replay)
    record.verified = true;
    await redis.set(redisKey, record, 300); // 5-minute grace window
    logger.info({ phone, purpose }, 'OTP verified (Redis)');
    return { success: true };
  }

  // ---- In-memory fallback ----
  const record = otpStore.get(memKey);

  if (!record) {
    return { success: false, error: 'OTP expired or not found. Please request a new one.' };
  }
  if (record.verified) {
    return { success: false, error: 'OTP already used.' };
  }
  if (record.attempts >= MAX_ATTEMPTS) {
    otpStore.delete(memKey);
    return { success: false, error: 'Too many attempts. Please request a new OTP.' };
  }

  record.attempts++;

  if (Date.now() - record.createdAt > OTP_EXPIRY_MS) {
    otpStore.delete(memKey);
    return { success: false, error: 'OTP has expired. Please request a new one.' };
  }

  if (record.otp !== otp) {
    otpStore.set(memKey, record);
    return { success: false, error: `Invalid OTP. ${MAX_ATTEMPTS - record.attempts} attempts remaining.` };
  }

  record.verified = true;
  otpStore.set(memKey, record);
  logger.info({ phone, purpose }, 'OTP verified (in-memory)');
  return { success: true };
}

module.exports = {
  sendSMS,
  sendOTP,
  verifyOTP,
  generateOTP,
};
