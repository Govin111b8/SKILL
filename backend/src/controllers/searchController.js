const { query } = require('../config/database');
const logger = require('../config/logger');

/**
 * Search ranking — 6-factor weighted Trust Score (PRD §6.4.2)
 *
 * Factor                    Weight  Description
 * ──────────────────────────────────────────────────────────────────
 * Reputation Score          30%     professionals.reputation_score (0–5 → 0–1)
 * Profile Completeness      20%     portfolio, bio, location, verified badge
 * Proximity                 20%     Haversine distance from customer GPS
 * Activity Level            15%     last_login_at recency (90-day window)
 * Subscription Tier Boost   10%     basic=0, premium=0.5, featured=1.0
 * Review Recency            5%      whether there are reviews in last 30 days
 * ──────────────────────────────────────────────────────────────────
 * Default filter: only show verified profiles (government_id_verified = TRUE)
 */

const search = async (req, res, next) => {
  try {
    const {
      q,
      category_id,
      category_ids,          // multi-select sub-categories (comma-separated)
      min_rating,
      max_price,
      latitude,
      longitude,
      radius_km,
      availability,
      provider_type,
      verified_only = 'true', // PRD default: show only verified profiles
      sort_by = 'reputation',
      page = 1,
      limit = 20,
    } = req.query;

    // Save search to history when authenticated
    if (req.user && q && q.trim()) {
      query(
        `INSERT INTO search_history (user_id, query_text, filters_json) VALUES ($1, $2, $3)`,
        [req.user.id, q.trim().substring(0, 255), JSON.stringify({ category_id, category_ids, availability, sort_by })]
      ).catch((err) => logger.error({ err, userId: req.user.id }, 'Failed to save search history'));
    }

    const pageNum = Math.max(1, parseInt(page));
    const limitNum = Math.min(100, Math.max(1, parseInt(limit)));
    const offset = (pageNum - 1) * limitNum;
    const params = [];
    const conditions = [];
    let paramIndex = 1;

    // ── Distance expression (Haversine) ──────────────────────────────
    let distanceExpr = 'NULL::float';
    let distanceWeight = '0';
    if (latitude && longitude) {
      distanceExpr = `(6371 * acos(LEAST(1.0, cos(radians($${paramIndex})) * cos(radians(p.latitude))
        * cos(radians(p.longitude) - radians($${paramIndex + 1}))
        + sin(radians($${paramIndex})) * sin(radians(p.latitude)))))`;
      params.push(parseFloat(latitude), parseFloat(longitude));
      paramIndex += 2;
      distanceWeight = `GREATEST(0, 1 - (${distanceExpr} / COALESCE(NULLIF($${paramIndex}, 0), 50)))`;
      params.push(parseFloat(radius_km || 50));
      paramIndex++;
    }

    // ── Subscription tier boost ───────────────────────────────────────
    const tierScore = `CASE p.subscription_plan
      WHEN 'featured' THEN 1.0
      WHEN 'premium'  THEN 0.5
      ELSE 0.0
    END`;

    // ── Profile completeness score (0–1) ─────────────────────────────
    const completenessScore = `(
      CASE WHEN p.bio IS NOT NULL AND p.bio <> '' THEN 0.15 ELSE 0 END
      + CASE WHEN p.headline IS NOT NULL AND p.headline <> '' THEN 0.10 ELSE 0 END
      + CASE WHEN p.latitude IS NOT NULL THEN 0.15 ELSE 0 END
      + CASE WHEN u.government_id_verified THEN 0.25 ELSE 0 END
      + CASE WHEN (SELECT COUNT(*) FROM portfolio_items pi WHERE pi.professional_id = p.id) > 0 THEN 0.20 ELSE 0 END
      + CASE WHEN (SELECT COUNT(*) FROM certifications cc WHERE cc.professional_id = p.id) > 0 THEN 0.05 ELSE 0 END
      + CASE WHEN p.cover_image_url IS NOT NULL THEN 0.05 ELSE 0 END
      + CASE WHEN u.avatar_url IS NOT NULL THEN 0.05 ELSE 0 END
    )`;

    // ── Activity score (last login within 90 days → 1.0, older → 0) ──
    const activityScore = `GREATEST(0, 1.0 - EXTRACT(EPOCH FROM (NOW() - COALESCE(u.last_login_at, u.created_at))) / (90 * 86400))`;

    // ── Review recency (any review in last 30 days) ───────────────────
    const reviewRecencyScore = `CASE WHEN EXISTS (
      SELECT 1 FROM reviews rr
      WHERE rr.professional_id = p.id AND rr.created_at >= NOW() - INTERVAL '30 days'
    ) THEN 1.0 ELSE 0.0 END`;

    // ── Composite ranking score ───────────────────────────────────────
    const rankingScore = latitude && longitude
      ? `(
          (COALESCE(AVG(r.rating), 0) / 5.0)          * 0.30   -- reputation
          + (${completenessScore})                      * 0.20   -- profile completeness
          + (${distanceWeight})                         * 0.20   -- proximity
          + (${activityScore})                          * 0.15   -- activity
          + (${tierScore})                              * 0.10   -- subscription tier
          + (${reviewRecencyScore})                     * 0.05   -- review recency
        )`
      : `(
          (COALESCE(AVG(r.rating), 0) / 5.0)          * 0.375  -- reputation (redistributed)
          + (${completenessScore})                      * 0.25   -- profile completeness
          + (${activityScore})                          * 0.1875 -- activity
          + (${tierScore})                              * 0.125  -- subscription tier
          + (${reviewRecencyScore})                     * 0.0625 -- review recency
        )`;

    // ── SELECT ───────────────────────────────────────────────────────
    const selectClause = `
      SELECT
        p.*,
        u.name, u.location, u.email, u.avatar_url, u.government_id_verified,
        u.last_login_at,
        COALESCE(AVG(r.rating), 0)::numeric(3,2)  AS average_rating,
        COUNT(DISTINCT r.id)::int                   AS review_count,
        ${latitude && longitude ? `${distanceExpr}::numeric(8,2) AS distance,` : ''}
        (${rankingScore})::numeric(5,4)             AS ranking_score,
        (${completenessScore})::numeric(3,2)        AS profile_completeness_score
    `;

    // ── FROM ─────────────────────────────────────────────────────────
    let fromClause = `
      FROM professionals p
      JOIN users u ON p.user_id = u.id
      LEFT JOIN reviews r ON p.id = r.professional_id
    `;

    // ── WHERE conditions ─────────────────────────────────────────────

    // Verified-only filter (default ON per PRD)
    if (verified_only !== 'false') {
      conditions.push(`u.government_id_verified = TRUE`);
    }

    // Active users only
    conditions.push(`u.is_active = TRUE`);

    // Single category filter
    if (category_id) {
      fromClause += ` JOIN professional_categories pc ON p.id = pc.professional_id`;
      conditions.push(`pc.category_id = $${paramIndex}`);
      params.push(parseInt(category_id));
      paramIndex++;
    }

    // Multi-select sub-category filter (comma-separated IDs)
    if (category_ids && !category_id) {
      const ids = String(category_ids).split(',').map((s) => parseInt(s.trim())).filter(Number.isFinite);
      if (ids.length > 0) {
        fromClause += ` JOIN professional_categories pc ON p.id = pc.professional_id`;
        conditions.push(`pc.category_id = ANY($${paramIndex}::int[])`);
        params.push(ids);
        paramIndex++;
      }
    }

    // Full-text search across name, headline, bio
    if (q) {
      const escapedQ = q.replace(/[%_\\]/g, '\\$&');
      conditions.push(
        `(u.name ILIKE $${paramIndex} OR p.headline ILIKE $${paramIndex} OR p.bio ILIKE $${paramIndex})`
      );
      params.push(`%${escapedQ}%`);
      paramIndex++;
    }

    // Max price filter
    if (max_price) {
      conditions.push(`p.pricing_estimate <= $${paramIndex}`);
      params.push(parseFloat(max_price));
      paramIndex++;
    }

    // Availability filter
    if (availability) {
      conditions.push(`p.availability_status = $${paramIndex}`);
      params.push(availability);
      paramIndex++;
    }

    // Provider type filter
    if (provider_type) {
      conditions.push(`p.provider_type = $${paramIndex}`);
      params.push(provider_type);
      paramIndex++;
    }

    // Geo-radius filter (Haversine)
    if (latitude && longitude && radius_km) {
      conditions.push(`
        (6371 * acos(LEAST(1.0, cos(radians($${paramIndex})) * cos(radians(p.latitude))
        * cos(radians(p.longitude) - radians($${paramIndex + 1}))
        + sin(radians($${paramIndex})) * sin(radians(p.latitude))))) <= $${paramIndex + 2}
      `);
      params.push(parseFloat(latitude), parseFloat(longitude), parseFloat(radius_km));
      paramIndex += 3;
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const groupByClause = `GROUP BY p.id, u.name, u.location, u.email, u.avatar_url,
      u.government_id_verified, u.last_login_at`;

    // Min rating filter (applied after aggregation)
    let havingClause = '';
    if (min_rating) {
      havingClause = `HAVING COALESCE(AVG(r.rating), 0) >= $${paramIndex}`;
      params.push(parseFloat(min_rating));
      paramIndex++;
    }

    // ── ORDER BY ─────────────────────────────────────────────────────
    let orderClause;
    switch (sort_by) {
      case 'distance':
        orderClause = latitude && longitude ? 'ORDER BY distance ASC NULLS LAST' : 'ORDER BY ranking_score DESC';
        break;
      case 'experience':
        orderClause = 'ORDER BY p.years_of_experience DESC NULLS LAST';
        break;
      case 'rating':
        orderClause = 'ORDER BY average_rating DESC, review_count DESC';
        break;
      case 'response_time':
        orderClause = 'ORDER BY p.response_time_hours ASC NULLS LAST';
        break;
      case 'reputation':
      default:
        orderClause = 'ORDER BY ranking_score DESC, average_rating DESC';
        break;
    }

    // ── Execute ───────────────────────────────────────────────────────
    const innerQuery = `${selectClause} ${fromClause} ${whereClause} ${groupByClause} ${havingClause}`;
    const countQuery = `SELECT COUNT(*) FROM (${innerQuery}) AS filtered`;
    const countResult = await query(countQuery, params);
    const total = parseInt(countResult.rows[0].count);

    params.push(limitNum, offset);
    const mainQuery = `${innerQuery} ${orderClause} LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    const result = await query(mainQuery, params);

    res.status(200).json({
      success: true,
      data: result.rows.map((row) => ({
        ...row,
        average_rating: parseFloat(row.average_rating),
        ranking_score: parseFloat(row.ranking_score),
        profile_completeness_score: parseFloat(row.profile_completeness_score),
        distance: row.distance != null ? parseFloat(row.distance) : undefined,
      })),
      pagination: {
        page: pageNum,
        limit: limitNum,
        total,
        pages: Math.ceil(total / limitNum),
      },
    });
  } catch (error) {
    next(error);
  }
};

// Get recent search history for autocomplete
const searchHistory = async (req, res, next) => {
  try {
    const r = await query(
      `SELECT DISTINCT ON (query_text) query_text, created_at
       FROM search_history WHERE user_id = $1
       ORDER BY query_text, created_at DESC
       LIMIT 10`,
      [req.user.id]
    );
    res.json({ success: true, data: r.rows.map(row => row.query_text) });
  } catch (e) { next(e); }
};

// Clear search history
const clearHistory = async (req, res, next) => {
  try {
    await query('DELETE FROM search_history WHERE user_id = $1', [req.user.id]);
    res.json({ success: true });
  } catch (e) { next(e); }
};

module.exports = { search, searchHistory, clearHistory };
