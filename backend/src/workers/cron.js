/**
 * Background Cron Jobs — SkillConnect
 *
 * Schedules:
 *   reputation_score_recalc     — nightly 02:00 IST
 *   subscription_expiry_checker — daily 09:00 IST
 *   subscription_grace_enforcer — daily 00:05 IST
 *   inactive_profile_checker    — weekly Sunday 03:00 IST
 *   review_velocity_detector    — every 5 minutes
 *   stale_device_token_cleaner  — weekly Monday 04:00 IST
 *
 * All times in IST (UTC+5:30 → subtract 5h30m from IST for UTC cron)
 * node-cron uses UTC by default; times below are in UTC.
 */

const cron = require('node-cron');
const { query } = require('../config/database');
const logger = require('../config/logger');
const emailService = require('../services/email');
const smsService = require('../services/sms');

// ─────────────────────────────────────────────────────────────────────────────
// 1. Reputation Score Recalculation — nightly 02:00 IST (20:30 UTC)
// ─────────────────────────────────────────────────────────────────────────────
async function recalcReputationScores() {
  logger.info('CRON: reputation_score_recalc — start');
  try {
    const result = await query(`
      WITH recent_activity AS (
        SELECT DISTINCT professional_id FROM reviews WHERE created_at >= NOW() - INTERVAL '24 hours'
        UNION
        SELECT p.id FROM professionals p
          JOIN users u ON p.user_id = u.id
          JOIN complaints c ON c.reported_user_id = u.id
         WHERE c.updated_at >= NOW() - INTERVAL '24 hours'
      ),
      scores AS (
        SELECT
          p.id,
          COALESCE(AVG(r.rating), 0)::numeric                                  AS avg_rating,
          p.completed_jobs,
          p.response_time_hours,
          COUNT(DISTINCT c.id) FILTER (WHERE c.status NOT IN ('resolved'))     AS open_complaints,
          COUNT(DISTINCT r.id) FILTER (WHERE r.created_at >= NOW() - INTERVAL '30 days') AS recent_reviews
        FROM professionals p
        JOIN recent_activity ra ON p.id = ra.professional_id
        LEFT JOIN reviews r ON r.professional_id = p.id
        LEFT JOIN users pu ON pu.id = p.user_id
        LEFT JOIN complaints c ON c.reported_user_id = pu.id
        GROUP BY p.id, p.completed_jobs, p.response_time_hours
      )
      UPDATE professionals SET
        avg_rating       = ROUND(scores.avg_rating, 2),
        reputation_score = ROUND(LEAST(5.0,
          (scores.avg_rating / 5.0) * 5.0 * 0.40
          + LEAST(scores.completed_jobs::numeric / 200.0, 1.0) * 5.0 * 0.20
          + CASE WHEN scores.response_time_hours IS NULL THEN 0
                 ELSE GREATEST(0, 1 - scores.response_time_hours / 48.0) * 5.0 * 0.15 END
          + CASE WHEN scores.open_complaints = 0 THEN 5.0 * 0.10
                 ELSE GREATEST(0, 0.10 - scores.open_complaints::numeric * 0.03) * 5.0 END
          + CASE WHEN scores.recent_reviews > 0 THEN 5.0 * 0.05 ELSE 0 END
        ), 2),
        updated_at = NOW()
      FROM scores
      WHERE professionals.id = scores.id
      RETURNING professionals.id
    `);
    logger.info({ updated: result.rowCount }, 'CRON: reputation_score_recalc — done');
  } catch (err) {
    logger.error({ err }, 'CRON: reputation_score_recalc failed');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Subscription Expiry Checker — daily 09:00 IST (03:30 UTC)
// ─────────────────────────────────────────────────────────────────────────────
async function checkSubscriptionExpiry() {
  logger.info('CRON: subscription_expiry_checker — start');
  try {
    const thresholds = [
      { days: 7, label: '7 days' },
      { days: 3, label: '3 days' },
      { days: 1, label: 'tomorrow' },
    ];

    for (const { days, label } of thresholds) {
      const result = await query(`
        SELECT p.id, u.email, u.name, u.phone, p.subscription_plan, p.subscription_expires_at
        FROM professionals p
        JOIN users u ON u.id = p.user_id
        WHERE p.subscription_plan != 'basic'
          AND p.subscription_expires_at::date = (NOW() + INTERVAL '${days} days')::date
          AND u.is_active = TRUE
      `);

      for (const row of result.rows) {
        const subject = `SkillConnect: Your ${row.subscription_plan} plan expires in ${label}`;
        const text = `Hi ${row.name},\n\nYour SkillConnect ${row.subscription_plan} subscription expires in ${label}.\n\nRenew now to keep your profile boost: https://app.skillconnect.in/payment\n\nThe SkillConnect Team`;

        await emailService.send({ to: row.email, subject, text }).catch((e) =>
          logger.error({ err: e, userId: row.id }, 'Renewal email failed')
        );

        if (row.phone) {
          await smsService.sendSMS(
            row.phone,
            `SkillConnect: Your ${row.subscription_plan} plan expires in ${label}. Renew: https://app.skillconnect.in/payment`
          ).catch(() => {});
        }
        logger.info({ professionalId: row.id, days }, 'Renewal reminder sent');
      }
    }
    logger.info('CRON: subscription_expiry_checker — done');
  } catch (err) {
    logger.error({ err }, 'CRON: subscription_expiry_checker failed');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Subscription Grace Enforcer — daily 00:05 IST (18:35 UTC)
// ─────────────────────────────────────────────────────────────────────────────
async function enforceSubscriptionGrace() {
  logger.info('CRON: subscription_grace_enforcer — start');
  try {
    const result = await query(`
      UPDATE professionals SET
        subscription_plan = 'basic',
        subscription_expires_at = NULL,
        updated_at = NOW()
      WHERE subscription_plan != 'basic'
        AND subscription_expires_at < NOW() - INTERVAL '3 days'
      RETURNING id, user_id
    `);

    for (const row of result.rows) {
      const userRow = await query('SELECT email, name FROM users WHERE id = $1', [row.user_id]);
      if (userRow.rows.length > 0) {
        const { email, name } = userRow.rows[0];
        await emailService.send({
          to: email,
          subject: 'SkillConnect: Your subscription has been downgraded',
          text: `Hi ${name},\n\nYour SkillConnect subscription grace period has ended. Your profile has been moved to Basic plan.\n\nRenew anytime to restore your ranking boost: https://app.skillconnect.in/payment\n\nThe SkillConnect Team`,
        }).catch(() => {});
      }
    }
    logger.info({ downgraded: result.rowCount }, 'CRON: subscription_grace_enforcer — done');
  } catch (err) {
    logger.error({ err }, 'CRON: subscription_grace_enforcer failed');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Inactive Profile Checker — weekly Sunday 03:00 IST (Sat 21:30 UTC)
// ─────────────────────────────────────────────────────────────────────────────
async function checkInactiveProfiles() {
  logger.info('CRON: inactive_profile_checker — start');
  try {
    // 60-day warning
    const warned = await query(`
      SELECT p.id, u.email, u.name, u.last_login_at
      FROM professionals p
      JOIN users u ON u.id = p.user_id
      WHERE u.last_login_at < NOW() - INTERVAL '60 days'
        AND u.last_login_at >= NOW() - INTERVAL '67 days'
        AND p.availability_status != 'offline'
        AND u.is_active = TRUE
    `);

    for (const row of warned.rows) {
      await emailService.send({
        to: row.email,
        subject: 'SkillConnect: Your profile will be paused soon',
        text: `Hi ${row.name},\n\nYou haven't logged into SkillConnect in 60 days. Log in within the next 30 days to keep your profile active in search results.\n\nLog in now: https://app.skillconnect.in\n\nThe SkillConnect Team`,
      }).catch(() => {});
    }

    // 90-day auto-deactivate
    const deactivated = await query(`
      UPDATE professionals SET availability_status = 'offline', updated_at = NOW()
      FROM users u
      WHERE professionals.user_id = u.id
        AND u.last_login_at < NOW() - INTERVAL '90 days'
        AND professionals.availability_status != 'offline'
        AND u.is_active = TRUE
      RETURNING professionals.id, professionals.user_id
    `);

    for (const row of deactivated.rows) {
      const userRow = await query('SELECT email, name FROM users WHERE id = $1', [row.user_id]);
      if (userRow.rows.length > 0) {
        await emailService.send({
          to: userRow.rows[0].email,
          subject: 'SkillConnect: Your profile has been paused due to inactivity',
          text: `Hi ${userRow.rows[0].name},\n\nYour profile was paused after 90 days of inactivity. Customers can no longer find you in search.\n\nLog in to reactivate instantly: https://app.skillconnect.in\n\nThe SkillConnect Team`,
        }).catch(() => {});
      }
    }

    logger.info({ warned: warned.rowCount, deactivated: deactivated.rowCount }, 'CRON: inactive_profile_checker — done');
  } catch (err) {
    logger.error({ err }, 'CRON: inactive_profile_checker failed');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. Review Velocity Detector — every 5 minutes
// ─────────────────────────────────────────────────────────────────────────────
async function detectReviewVelocity() {
  try {
    // Only run if moderation_status column exists (graceful degradation)
    const result = await query(`
      UPDATE reviews SET moderation_status = 'held_for_review'
      WHERE id IN (
        SELECT r.id FROM reviews r
        WHERE r.created_at >= NOW() - INTERVAL '24 hours'
          AND r.moderation_status = 'approved'
          AND (
            SELECT COUNT(*) FROM reviews r2
            WHERE r2.professional_id = r.professional_id
              AND r2.created_at >= NOW() - INTERVAL '24 hours'
          ) > 5
      )
      RETURNING id, professional_id
    `);
    if (result.rowCount > 0) {
      logger.warn({ held: result.rowCount }, 'CRON: review_velocity_detector — held burst reviews');
    }
  } catch (err) {
    if (!err.message?.includes('column') && !err.message?.includes('does not exist')) {
      logger.error({ err }, 'CRON: review_velocity_detector failed');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. Stale Device Token Cleaner — weekly Monday 04:00 IST (Sun 22:30 UTC)
// ─────────────────────────────────────────────────────────────────────────────
async function cleanStaleDeviceTokens() {
  logger.info('CRON: stale_device_token_cleaner — start');
  try {
    const result = await query(`
      DELETE FROM device_tokens
      WHERE last_used_at < NOW() - INTERVAL '90 days'
         OR is_active = FALSE
      RETURNING id
    `);
    logger.info({ deleted: result.rowCount }, 'CRON: stale_device_token_cleaner — done');
  } catch (err) {
    if (!err.message?.includes('does not exist')) {
      logger.error({ err }, 'CRON: stale_device_token_cleaner failed');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Register all cron jobs
// ─────────────────────────────────────────────────────────────────────────────
function startCronJobs() {
  logger.info('Starting background cron jobs...');

  // Reputation recalc — nightly 02:00 IST = 20:30 UTC
  cron.schedule('30 20 * * *', recalcReputationScores, { timezone: 'UTC' });

  // Subscription expiry checker — daily 09:00 IST = 03:30 UTC
  cron.schedule('30 3 * * *', checkSubscriptionExpiry, { timezone: 'UTC' });

  // Subscription grace enforcer — daily 00:05 IST = 18:35 UTC
  cron.schedule('35 18 * * *', enforceSubscriptionGrace, { timezone: 'UTC' });

  // Inactive profile checker — weekly Sunday 03:00 IST = Saturday 21:30 UTC
  cron.schedule('30 21 * * 6', checkInactiveProfiles, { timezone: 'UTC' });

  // Review velocity detector — every 5 minutes
  cron.schedule('*/5 * * * *', detectReviewVelocity, { timezone: 'UTC' });

  // Stale device token cleaner — weekly Monday 04:00 IST = Sunday 22:30 UTC
  cron.schedule('30 22 * * 0', cleanStaleDeviceTokens, { timezone: 'UTC' });

  logger.info('All 6 cron jobs scheduled');
}

module.exports = {
  startCronJobs,
  recalcReputationScores,
  checkSubscriptionExpiry,
  enforceSubscriptionGrace,
  checkInactiveProfiles,
  detectReviewVelocity,
  cleanStaleDeviceTokens,
};
