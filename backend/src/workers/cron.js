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
    // PRD §13.4 — Trust Index 0-100 formula
    // Factor weights: avg_rating 30%, recent_rating 20%, completed_jobs 15%,
    //                 repeat_customer_rate 15%, response_rate 10%,
    //                 profile_completeness 5%, verification_bonus +5,
    //                 complaint_penalty -15 per verified complaint
    const result = await query(`
      WITH
      -- Recent ratings (last 10 reviews)
      recent_ratings AS (
        SELECT professional_id,
               ROUND(AVG(rating)::numeric, 2) AS recent_avg
        FROM (
          SELECT professional_id, rating,
                 ROW_NUMBER() OVER (PARTITION BY professional_id ORDER BY created_at DESC) AS rn
          FROM reviews
          WHERE moderation_status = 'approved'
        ) ranked
        WHERE rn <= 10
        GROUP BY professional_id
      ),
      -- Overall ratings
      overall_ratings AS (
        SELECT professional_id,
               ROUND(AVG(rating)::numeric, 2) AS avg_r,
               COUNT(*) AS review_count
        FROM reviews
        WHERE moderation_status = 'approved'
        GROUP BY professional_id
      ),
      -- Repeat customer rate (customers who contacted same pro >= 2 times in last 90 days)
      repeat_customers AS (
        SELECT professional_id,
               CASE WHEN COUNT(DISTINCT customer_id) = 0 THEN 0
                    ELSE ROUND(
                      (COUNT(DISTINCT customer_id) FILTER (
                        WHERE customer_id IN (
                          SELECT customer_id FROM contacts c2
                          WHERE c2.professional_id = contacts.professional_id
                            AND c2.created_at >= NOW() - INTERVAL '90 days'
                          GROUP BY customer_id HAVING COUNT(*) >= 2
                        )
                      ))::numeric / NULLIF(COUNT(DISTINCT customer_id), 0) * 100, 2)
               END AS repeat_rate
        FROM contacts
        WHERE created_at >= NOW() - INTERVAL '90 days'
        GROUP BY professional_id
      ),
      -- Verified complaints in last 12 months
      complaint_counts AS (
        SELECT c_inner.reported_user_id,
               COUNT(*) AS verified_complaints
        FROM complaints c_inner
        WHERE c_inner.status IN ('warning_issued', 'suspended', 'banned')
          AND c_inner.created_at >= NOW() - INTERVAL '12 months'
        GROUP BY c_inner.reported_user_id
      ),
      -- Profile completeness (0-100)
      completeness AS (
        SELECT p.id,
          (CASE WHEN p.headline IS NOT NULL AND p.headline <> '' THEN 10 ELSE 0 END +
           CASE WHEN p.bio IS NOT NULL AND p.bio <> '' THEN 10 ELSE 0 END +
           CASE WHEN p.latitude IS NOT NULL THEN 10 ELSE 0 END +
           CASE WHEN p.cover_image_url IS NOT NULL THEN 5 ELSE 0 END +
           CASE WHEN u.avatar_url IS NOT NULL THEN 5 ELSE 0 END +
           CASE WHEN u.government_id_verified THEN 20 ELSE 0 END +
           CASE WHEN (SELECT COUNT(*) FROM portfolio_items pi WHERE pi.professional_id = p.id) >= 3 THEN 20 ELSE 10 END +
           CASE WHEN (SELECT COUNT(*) FROM certifications cert WHERE cert.professional_id = p.id) > 0 THEN 10 ELSE 0 END +
           CASE WHEN (SELECT COUNT(*) FROM professional_categories pc WHERE pc.professional_id = p.id) > 0 THEN 10 ELSE 0 END
          ) AS completeness_pct
        FROM professionals p
        JOIN users u ON u.id = p.user_id
      )
      UPDATE professionals SET
        avg_rating           = COALESCE(or_.avg_r, 0),
        recent_rating        = COALESCE(rr.recent_avg, COALESCE(or_.avg_r, 0)),
        repeat_customer_rate = COALESCE(rc.repeat_rate, 0),
        trust_index          = LEAST(100, GREATEST(0, ROUND(
          -- 30%: Average rating (0-5 → 0-30)
          (COALESCE(or_.avg_r, 0) / 5.0 * 30)
          -- 20%: Recent rating (0-5 → 0-20)
          + (COALESCE(rr.recent_avg, COALESCE(or_.avg_r, 0)) / 5.0 * 20)
          -- 15%: Completed jobs (logarithmic: 1=5, 10=15, 50=25, 100+=30)
          + LEAST(15, CASE WHEN professionals.completed_jobs <= 0 THEN 0
                           ELSE LOG(10, professionals.completed_jobs + 1) / LOG(10, 101) * 15
                      END)
          -- 15%: Repeat customer rate (0-100% → 0-15)
          + (COALESCE(rc.repeat_rate, 0) / 100.0 * 15)
          -- 10%: Response rate (0-100% → 0-10)
          + (COALESCE(professionals.response_rate, 0) / 100.0 * 10)
          -- 5%: Profile completeness (0-100 → 0-5)
          + (COALESCE(comp.completeness_pct, 0) / 100.0 * 5)
          -- +5: Verification bonus
          + CASE WHEN u.government_id_verified THEN 5 ELSE 0 END
          -- -15 per verified complaint in last 12 months
          - (COALESCE(cc.verified_complaints, 0) * 15)
        , 2))),
        -- Keep 0-5 avg_rating for backward compatibility
        reputation_score     = ROUND(LEAST(5.0, COALESCE(or_.avg_r, 0))::numeric, 2),
        updated_at           = NOW()
      FROM professionals p_inner
      JOIN users u ON u.id = p_inner.user_id
      LEFT JOIN overall_ratings or_  ON or_.professional_id = p_inner.id
      LEFT JOIN recent_ratings rr    ON rr.professional_id = p_inner.id
      LEFT JOIN repeat_customers rc  ON rc.professional_id = p_inner.id
      LEFT JOIN complaint_counts cc  ON cc.reported_user_id = u.id
      LEFT JOIN completeness comp    ON comp.id = p_inner.id
      WHERE professionals.id = p_inner.id
      RETURNING professionals.id
    `);
    logger.info({ updated: result.rowCount }, 'CRON: reputation_score_recalc (Trust Index 0-100) — done');
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
      // Use parameterized query to avoid SQL injection — days comes from a
      // controlled array but we still use proper parameterization as best practice
      const result = await query(
        `SELECT p.id, u.email, u.name, u.phone, p.subscription_plan, p.subscription_expires_at
         FROM professionals p
         JOIN users u ON u.id = p.user_id
         WHERE p.subscription_plan != 'basic'
           AND p.subscription_expires_at::date = (NOW() + ($1 * INTERVAL '1 day'))::date
           AND u.is_active = TRUE`,
        [days]
      );

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

  // Trust Index / Reputation recalc — nightly 02:00 IST = 20:30 UTC
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

  // Response rate updater — daily 03:00 IST = 21:30 UTC
  cron.schedule('30 21 * * *', updateResponseRates, { timezone: 'UTC' });

  // KYC document retention — weekly to purge old docs
  cron.schedule('0 0 * * 0', purgeExpiredKycDocuments, { timezone: 'UTC' });

  // Badge recalculation — weekly Sunday 04:00 IST = Saturday 22:30 UTC
  cron.schedule('30 22 * * 6', recalcBadges, { timezone: 'UTC' });

  logger.info('All 9 cron jobs scheduled');
}

// ─────────────────────────────────────────────────────────────────────────────
// 7. Response Rate Updater — daily 03:00 IST (21:30 UTC prev day)
// Calculates % of contact requests where professional sent a message within 24h
// ─────────────────────────────────────────────────────────────────────────────
async function updateResponseRates() {
  try {
    // For each professional, calculate response rate over last 30 days
    await query(`
      UPDATE professionals SET
        response_rate = COALESCE((
          SELECT ROUND(
            (COUNT(*) FILTER (WHERE c.status = 'accepted'))::numeric
            / NULLIF(COUNT(*), 0) * 100, 2
          )
          FROM contacts c
          WHERE c.professional_id = professionals.id
            AND c.created_at >= NOW() - INTERVAL '30 days'
        ), 0),
        updated_at = NOW()
    `);
    logger.info('CRON: response_rate_updater — done');
  } catch (err) {
    logger.error({ err }, 'CRON: response_rate_updater failed');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 8. KYC Document Retention — weekly Sunday midnight UTC
// Purges government ID documents from storage after 12 months post-verification
// (Logs deletion; actual S3 deletion requires storage service call)
// ─────────────────────────────────────────────────────────────────────────────
async function purgeExpiredKycDocuments() {
  try {
    // Mark documents for purge (actual S3 deletion done by storage service)
    const result = await query(`
      UPDATE verifications SET
        document_url = NULL,
        selfie_url = NULL
      WHERE status = 'verified'
        AND verified_at < NOW() - INTERVAL '12 months'
        AND document_url IS NOT NULL
      RETURNING id, user_id
    `);
    if (result.rowCount > 0) {
      logger.info({ purged: result.rowCount }, 'CRON: kyc_doc_retention — purged expired KYC docs');
    }
  } catch (err) {
    if (!err.message?.includes('does not exist')) {
      logger.error({ err }, 'CRON: kyc_doc_retention failed');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 9. Badge Recalculation — weekly Sunday 04:00 IST (22:30 UTC Saturday)
// Auto-awards / revokes professional badges based on current stats
// ─────────────────────────────────────────────────────────────────────────────
const BADGE_CRITERIA = {
  rising_pro: {
    check: (s) => s.government_id_verified && s.completed_jobs >= 5,
  },
  fast_responder: {
    check: (s) => s.response_time_hours != null && s.response_time_hours < 0.5,
  },
  customer_favorite: {
    check: (s) => s.average_rating >= 4.8 && s.review_count >= 20,
  },
  elite_professional: {
    check: (s) => s.completed_jobs >= 100 && s.average_rating >= 4.9 && s.repeat_customer_rate >= 50,
  },
};

async function recalcBadges() {
  logger.info('CRON: badge_recalculation — start');
  try {
    const pros = await query(`
      SELECT p.id, p.completed_jobs, p.response_time_hours, p.repeat_customer_rate,
             u.government_id_verified,
             COALESCE(AVG(r.rating), 0)::numeric as average_rating,
             COUNT(r.id)::int as review_count
      FROM professionals p
      JOIN users u ON p.user_id = u.id
      LEFT JOIN reviews r ON r.professional_id = p.id
      GROUP BY p.id, u.government_id_verified
    `);

    let awarded = 0;
    let revoked = 0;

    for (const pro of pros.rows) {
      const stats = {
        ...pro,
        average_rating: parseFloat(pro.average_rating),
        repeat_customer_rate: parseFloat(pro.repeat_customer_rate || 0),
      };

      for (const [badgeType, def] of Object.entries(BADGE_CRITERIA)) {
        const earned = def.check(stats);

        if (earned) {
          const result = await query(
            `INSERT INTO professional_badges (professional_id, badge_type, metadata)
             VALUES ($1, $2, $3)
             ON CONFLICT (professional_id, badge_type) DO NOTHING
             RETURNING id`,
            [pro.id, badgeType, JSON.stringify({ auto_recalc: true })]
          );
          if (result.rows.length > 0) awarded++;
        } else {
          const result = await query(
            'DELETE FROM professional_badges WHERE professional_id = $1 AND badge_type = $2 RETURNING id',
            [pro.id, badgeType]
          );
          if (result.rows.length > 0) revoked++;
        }
      }
    }

    logger.info({ professionals: pros.rowCount, awarded, revoked }, 'CRON: badge_recalculation — done');
  } catch (err) {
    if (!err.message?.includes('does not exist')) {
      logger.error({ err }, 'CRON: badge_recalculation failed');
    }
  }
}

module.exports = {
  startCronJobs,
  recalcReputationScores,
  checkSubscriptionExpiry,
  enforceSubscriptionGrace,
  checkInactiveProfiles,
  detectReviewVelocity,
  cleanStaleDeviceTokens,
  updateResponseRates,
  purgeExpiredKycDocuments,
  recalcBadges,
};
