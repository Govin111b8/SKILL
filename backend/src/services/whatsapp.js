/**
 * WhatsApp Business API Service
 *
 * Sends WhatsApp messages via Meta Cloud API (preferred) or MSG91 WhatsApp gateway.
 * Falls back gracefully when not configured — logs the message instead.
 *
 * Required env vars (Meta Cloud API):
 *   WHATSAPP_PHONE_NUMBER_ID   — the WhatsApp Business phone number ID
 *   WHATSAPP_ACCESS_TOKEN      — permanent access token from Meta Developer Console
 *   WHATSAPP_API_VERSION       — e.g. 'v19.0' (default)
 *
 * Required env vars (MSG91 WhatsApp):
 *   WHATSAPP_PROVIDER=msg91
 *   MSG91_AUTH_KEY             — same MSG91 key as SMS
 *   MSG91_WHATSAPP_SENDER      — sender ID approved for WhatsApp
 */

const logger = require('../config/logger');

const PROVIDER = process.env.WHATSAPP_PROVIDER || 'meta'; // 'meta' | 'msg91' | 'none'
const META_PHONE_ID = process.env.WHATSAPP_PHONE_NUMBER_ID;
const META_TOKEN = process.env.WHATSAPP_ACCESS_TOKEN;
const META_VERSION = process.env.WHATSAPP_API_VERSION || 'v19.0';
const MSG91_KEY = process.env.MSG91_AUTH_KEY;
const MSG91_WA_SENDER = process.env.MSG91_WHATSAPP_SENDER;

/**
 * Normalise an Indian phone number to E.164 format (+91XXXXXXXXXX).
 * Accepts: 10-digit, 0-prefixed 11-digit, or already-prefixed.
 */
function normalisePhone(phone) {
  if (!phone) return null;
  const digits = phone.replace(/\D/g, '');
  if (digits.length === 10) return `+91${digits}`;
  if (digits.length === 11 && digits.startsWith('0')) return `+91${digits.slice(1)}`;
  if (digits.length === 12 && digits.startsWith('91')) return `+${digits}`;
  if (digits.length === 13 && digits.startsWith('91')) return `+${digits}`;
  return `+${digits}`;
}

/**
 * Send a plain-text WhatsApp message.
 *
 * @param {Object} opts
 * @param {string} opts.to      - recipient phone (any format)
 * @param {string} opts.message - text message body
 * @returns {Promise<{success: boolean, provider?: string, simulated?: boolean}>}
 */
async function sendWhatsApp({ to, message }) {
  const phone = normalisePhone(to);
  if (!phone) {
    logger.warn({ to }, 'WhatsApp: invalid phone number');
    return { success: false, error: 'Invalid phone number' };
  }

  if (PROVIDER === 'meta' && META_PHONE_ID && META_TOKEN) {
    return sendViaMeta(phone, message);
  }

  if (PROVIDER === 'msg91' && MSG91_KEY && MSG91_WA_SENDER) {
    return sendViaMsg91(phone, message);
  }

  // Not configured — log and simulate
  logger.warn({ to: phone, provider: PROVIDER }, 'WhatsApp not configured — message logged only');
  logger.info({ to: phone, message: message.substring(0, 200) }, 'WHATSAPP_CONTENT');
  return { success: true, simulated: true };
}

/**
 * Send via Meta Cloud API (official WhatsApp Business API)
 */
async function sendViaMeta(phone, message) {
  const url = `https://graph.facebook.com/${META_VERSION}/${META_PHONE_ID}/messages`;

  const body = {
    messaging_product: 'whatsapp',
    to: phone,
    type: 'text',
    text: { body: message },
  };

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer ' + META_TOKEN,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      const err = await response.json().catch(() => ({}));
      logger.error({ status: response.status, err, phone }, 'WhatsApp Meta API error');
      return { success: false, error: err.error?.message || 'Meta API error' };
    }

    const data = await response.json();
    logger.info({ messageId: data?.messages?.[0]?.id, phone }, 'WhatsApp sent via Meta');
    return { success: true, provider: 'meta', messageId: data?.messages?.[0]?.id };
  } catch (err) {
    logger.error({ err, phone }, 'WhatsApp Meta send exception');
    return { success: false, error: err.message };
  }
}

/**
 * Send via MSG91 WhatsApp gateway
 */
async function sendViaMsg91(phone, message) {
  try {
    const response = await fetch('https://api.msg91.com/api/v5/whatsapp/whatsapp-outbound-message/bulk/', {
      method: 'POST',
      headers: {
        'authkey': MSG91_KEY,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        integrated_number: MSG91_WA_SENDER,
        content_type: 'template',
        payload: {
          to: [{ user_whatsapp_number: phone }],
          type: 'text',
          text: { body: message },
        },
      }),
    });

    if (!response.ok) {
      const err = await response.json().catch(() => ({}));
      logger.error({ status: response.status, err, phone }, 'WhatsApp MSG91 error');
      return { success: false, error: err.message || 'MSG91 WhatsApp error' };
    }

    const data = await response.json();
    logger.info({ data, phone }, 'WhatsApp sent via MSG91');
    return { success: true, provider: 'msg91' };
  } catch (err) {
    logger.error({ err, phone }, 'WhatsApp MSG91 send exception');
    return { success: false, error: err.message };
  }
}

/**
 * Send a booking confirmation WhatsApp message to a customer.
 */
async function sendBookingConfirmation({ phone, customerName, bookingId, serviceName, scheduledAt, professionalName }) {
  const dateStr = scheduledAt ? new Date(scheduledAt).toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' }) : 'TBD';
  const message = [
    `✅ *Booking Confirmed!*`,
    ``,
    `Hi ${customerName || 'there'},`,
    `Your booking for *${serviceName}* has been confirmed.`,
    ``,
    `📅 *Date & Time:* ${dateStr}`,
    `👷 *Professional:* ${professionalName || 'Being assigned'}`,
    `🔖 *Booking ID:* ${bookingId}`,
    ``,
    `Track your professional live on the SkillConnect app.`,
    `For help, reply to this message or call 1800-XXX-XXXX.`,
  ].join('\n');

  return sendWhatsApp({ to: phone, message });
}

/**
 * Send OTP via WhatsApp (alternative to SMS OTP — preferred in India).
 */
async function sendOtpWhatsApp({ phone, otp, appName = 'SkillConnect' }) {
  const message = `*${otp}* is your ${appName} verification code. Valid for 10 minutes. Do not share with anyone.`;
  return sendWhatsApp({ to: phone, message });
}

/**
 * Send job assignment notification to professional.
 */
async function sendJobAssignedToPro({ phone, proName, serviceName, customerAddress, scheduledAt, bookingId }) {
  const dateStr = scheduledAt ? new Date(scheduledAt).toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' }) : 'TBD';
  const message = [
    `🔔 *New Job Assigned!*`,
    ``,
    `Hi ${proName || 'there'},`,
    `You have a new booking on *SkillConnect*.`,
    ``,
    `🛠️ *Service:* ${serviceName}`,
    `📅 *Date & Time:* ${dateStr}`,
    `📍 *Location:* ${customerAddress || 'See app for details'}`,
    `🔖 *Booking ID:* ${bookingId}`,
    ``,
    `Open the SkillConnect app to accept or view details.`,
  ].join('\n');

  return sendWhatsApp({ to: phone, message });
}

/**
 * Send quote bid notification to customer.
 */
async function sendQuoteBidNotification({ phone, customerName, categoryName, quoteId, bidAmount }) {
  const message = [
    `💰 *New Bid Received!*`,
    ``,
    `Hi ${customerName || 'there'},`,
    `A professional has submitted a bid of *₹${bidAmount}* for your *${categoryName}* quote request.`,
    ``,
    `Open the app to compare bids and accept the best one.`,
    `Quote ID: ${quoteId}`,
  ].join('\n');

  return sendWhatsApp({ to: phone, message });
}

module.exports = {
  sendWhatsApp,
  sendBookingConfirmation,
  sendOtpWhatsApp,
  sendJobAssignedToPro,
  sendQuoteBidNotification,
};
