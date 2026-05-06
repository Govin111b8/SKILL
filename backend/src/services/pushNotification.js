/**
 * Push Notification Service — Firebase Cloud Messaging (FCM)
 *
 * Queries device_tokens table to deliver push notifications to all
 * active devices for a given user. Automatically marks tokens as
 * inactive when FCM reports them as unregistered/invalid.
 *
 * Required env vars:
 *   FCM_SERVER_KEY  — Firebase Legacy Server Key (Settings → Cloud Messaging)
 *   FCM_PROJECT_ID  — Firebase project ID (for future HTTP v2 migration)
 */

const logger = require('../config/logger');
const { query } = require('../config/database');

const FCM_SERVER_KEY = process.env.FCM_SERVER_KEY || '';
const FCM_PROJECT_ID = process.env.FCM_PROJECT_ID || '';
const FCM_CONFIGURED = !!(FCM_SERVER_KEY);

/**
 * Send push notification to a single device token.
 * @param {string} deviceToken - FCM device token
 * @param {object} payload - { title, body, data, imageUrl }
 */
async function sendPushNotification(deviceToken, { title, body, data = {}, imageUrl }) {
  if (!FCM_CONFIGURED) {
    logger.warn({ deviceToken: deviceToken?.substring(0, 20), title }, 'FCM not configured — push notification logged only');
    return { success: true, simulated: true };
  }

  const message = {
    to: deviceToken,
    notification: {
      title,
      body,
      ...(imageUrl && { image: imageUrl }),
      sound: 'default',
    },
    data: {
      ...data,
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
    priority: 'high',
  };

  const response = await fetch('https://fcm.googleapis.com/fcm/send', {
    method: 'POST',
    headers: {
      'Authorization': `key=${FCM_SERVER_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(message),
  });

  const result = await response.json();

  if (result.failure > 0) {
    const errorCode = result.results?.[0]?.error;
    logger.warn({ deviceToken: deviceToken?.substring(0, 20), errorCode }, 'FCM delivery failure');
    return { success: false, error: errorCode };
  }

  logger.info({ title }, 'Push notification sent');
  return { success: true, messageId: result.results?.[0]?.message_id };
}

/**
 * Send a push notification to ALL active devices for a user.
 * Reads device tokens from the device_tokens table.
 * Invalid tokens are automatically deactivated.
 *
 * @param {string} userId - UUID of the user to notify
 * @param {string} title
 * @param {string} body
 * @param {object} [data] - Extra key-value data for the notification
 * @param {string} [imageUrl]
 */
async function sendPush(userId, title, body, data = {}, imageUrl) {
  // Fetch all active tokens for the user
  let tokens = [];
  try {
    const rows = await query(
      `SELECT id, token FROM device_tokens WHERE user_id = $1 AND is_active = TRUE`,
      [userId]
    );
    tokens = rows.rows;
  } catch (_) {
    // device_tokens table may not exist yet in older environments — fall back to no-op
    logger.warn({ userId, title }, 'device_tokens table unavailable — push notification skipped');
    return;
  }

  if (tokens.length === 0) {
    logger.debug({ userId, title }, 'No active device tokens — push skipped');
    return;
  }

  const invalidTokenIds = [];

  for (const { id: tokenId, token } of tokens) {
    const result = await sendPushNotification(token, { title, body, data, imageUrl });

    if (!result.success && !result.simulated) {
      // Deactivate tokens that FCM reports as invalid
      const INVALID_ERRORS = ['InvalidRegistration', 'NotRegistered', 'MismatchSenderId'];
      if (INVALID_ERRORS.includes(result.error)) {
        invalidTokenIds.push(tokenId);
      }
    }
  }

  // Deactivate invalid tokens
  if (invalidTokenIds.length > 0) {
    await query(
      `UPDATE device_tokens SET is_active = FALSE WHERE id = ANY($1::uuid[])`,
      [invalidTokenIds]
    ).catch(() => {});
    logger.info({ count: invalidTokenIds.length }, 'Deactivated invalid device tokens');
  }
}

/**
 * Register or refresh a device token for a user.
 * Called from the notifications endpoint when the app sends its FCM token.
 *
 * @param {string} userId
 * @param {string} token - FCM device token
 * @param {'ios'|'android'|'web'} platform
 */
async function registerDeviceToken(userId, token, platform) {
  await query(
    `INSERT INTO device_tokens (user_id, token, platform, is_active, last_used_at)
     VALUES ($1, $2, $3::device_platform, TRUE, NOW())
     ON CONFLICT (user_id, token) DO UPDATE SET
       is_active = TRUE,
       platform = EXCLUDED.platform,
       last_used_at = NOW()`,
    [userId, token, platform || 'android']
  );
}

/**
 * Deregister a device token (called on logout).
 */
async function deregisterDeviceToken(userId, token) {
  await query(
    `UPDATE device_tokens SET is_active = FALSE WHERE user_id = $1 AND token = $2`,
    [userId, token]
  );
}

/**
 * Send push notification to multiple devices (multicast).
 * @param {string[]} deviceTokens - Array of FCM device tokens
 * @param {object} payload - { title, body, data }
 */
async function sendMulticastPush(deviceTokens, { title, body, data = {} }) {
  if (!FCM_CONFIGURED) {
    logger.warn({ count: deviceTokens.length, title }, 'FCM not configured — multicast push logged only');
    return { success: true, simulated: true, count: deviceTokens.length };
  }

  const message = {
    registration_ids: deviceTokens.slice(0, 1000),
    notification: { title, body, sound: 'default' },
    data: { ...data, click_action: 'FLUTTER_NOTIFICATION_CLICK' },
    priority: 'high',
  };

  const response = await fetch('https://fcm.googleapis.com/fcm/send', {
    method: 'POST',
    headers: {
      'Authorization': `key=${FCM_SERVER_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(message),
  });

  const result = await response.json();
  logger.info({ title, success: result.success, failure: result.failure }, 'Multicast push sent');
  return { success: true, successCount: result.success, failureCount: result.failure };
}

/**
 * Send topic notification (e.g., emergency broadcast)
 */
async function sendTopicPush(topic, { title, body, data = {} }) {
  if (!FCM_CONFIGURED) {
    logger.warn({ topic, title }, 'FCM not configured — topic push logged only');
    return { success: true, simulated: true };
  }

  const message = {
    to: `/topics/${topic}`,
    notification: { title, body, sound: 'default' },
    data: { ...data, click_action: 'FLUTTER_NOTIFICATION_CLICK' },
    priority: 'high',
  };

  const response = await fetch('https://fcm.googleapis.com/fcm/send', {
    method: 'POST',
    headers: {
      'Authorization': `key=${FCM_SERVER_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(message),
  });

  const result = await response.json();
  return { success: true, messageId: result.message_id };
}

module.exports = {
  sendPushNotification,
  sendPush,
  sendMulticastPush,
  sendTopicPush,
  registerDeviceToken,
  deregisterDeviceToken,
};

