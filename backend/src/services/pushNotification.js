/**
 * Push Notification Service — Firebase Cloud Messaging (FCM)
 *
 * Required env vars:
 *   FCM_SERVER_KEY (legacy) or GOOGLE_APPLICATION_CREDENTIALS (service account JSON path)
 *   FCM_PROJECT_ID
 */

const logger = require('../config/logger');

const FCM_SERVER_KEY = process.env.FCM_SERVER_KEY || '';
const FCM_PROJECT_ID = process.env.FCM_PROJECT_ID || '';

/**
 * Send push notification via FCM HTTP v1 API
 * @param {string} deviceToken - FCM device token
 * @param {object} payload - { title, body, data, imageUrl }
 */
async function sendPushNotification(deviceToken, { title, body, data = {}, imageUrl }) {
  if (!FCM_SERVER_KEY && !FCM_PROJECT_ID) {
    logger.warn({ deviceToken: deviceToken?.substring(0, 20), title }, 'FCM not configured — push notification logged only');
    return { success: true, simulated: true };
  }

  // Use legacy FCM API (simpler, doesn't require OAuth2)
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
    logger.warn({ deviceToken: deviceToken?.substring(0, 20), result }, 'FCM delivery failure');
    return { success: false, error: result.results?.[0]?.error };
  }

  logger.info({ title }, 'Push notification sent');
  return { success: true, messageId: result.results?.[0]?.message_id };
}

/**
 * Send push notification to multiple devices
 * @param {string[]} deviceTokens - Array of FCM device tokens
 * @param {object} payload - { title, body, data }
 */
async function sendMulticastPush(deviceTokens, { title, body, data = {} }) {
  if (!FCM_SERVER_KEY) {
    logger.warn({ count: deviceTokens.length, title }, 'FCM not configured — multicast push logged only');
    return { success: true, simulated: true, count: deviceTokens.length };
  }

  const message = {
    registration_ids: deviceTokens.slice(0, 1000), // FCM limit
    notification: {
      title,
      body,
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
  logger.info({ title, success: result.success, failure: result.failure }, 'Multicast push sent');
  return { success: true, successCount: result.success, failureCount: result.failure };
}

/**
 * Send topic notification (e.g., to all professionals in a category)
 * @param {string} topic - FCM topic (e.g., 'category_plumbing')
 * @param {object} payload - { title, body, data }
 */
async function sendTopicPush(topic, { title, body, data = {} }) {
  if (!FCM_SERVER_KEY) {
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
  sendMulticastPush,
  sendTopicPush,
};
