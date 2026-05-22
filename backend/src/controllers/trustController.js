const { query } = require('../config/database');
const logger = require('../config/logger');

// Badge definitions with criteria
const BADGE_DEFINITIONS = {
  rising_pro: {
    emoji: '🌱',
    label: 'Rising Pro',
    description: 'Verified professional with 5+ completed jobs',
    check: (stats) => stats.government_id_verified && stats.completed_jobs >= 5,
  },
  fast_responder: {
    emoji: '⚡',
    label: 'Fast Responder',
    description: 'Average response time under 30 minutes',
    check: (stats) => stats.response_time_hours != null && stats.response_time_hours < 0.5,
  },
  customer_favorite: {
    emoji: '⭐',
    label: 'Customer Favorite',
    description: '4.8+ rating with 20+ reviews',
    check: (stats) => stats.average_rating >= 4.8 && stats.review_count >= 20,
  },
  top_rated: {
    emoji: '🏆',
    label: 'Top Rated',
    description: 'Top 10% in their category',
    check: (stats) => stats.is_top_rated,
  },
  elite_professional: {
    emoji: '💎',
    label: 'Elite Professional',
    description: '100+ jobs, 4.9+ rating, 50%+ repeat customers',
    check: (stats) => stats.completed_jobs >= 100 && stats.average_rating >= 4.9 && stats.repeat_customer_rate >= 50,
  },
};

/**
 * GET /api/trust/:professionalId/badges
 * Public — get earned badges with progress toward next ones.
 */
const getBadges = async (req, res, next) => {
  try {
    const { professionalId } = req.params;

    // Get professional stats
    const statsResult = await query(
      `SELECT p.*, u.government_id_verified,
              COALESCE(AVG(r.rating), 0) as average_rating,
              COUNT(r.id)::int as review_count
       FROM professionals p
       JOIN users u ON p.user_id = u.id
       LEFT JOIN reviews r ON r.professional_id = p.id
       WHERE p.id = $1
       GROUP BY p.id, u.government_id_verified`,
      [professionalId]
    );

    if (statsResult.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Professional not found.' });
    }

    const stats = statsResult.rows[0];
    stats.average_rating = parseFloat(stats.average_rating);

    // Category-level percentile calculation for top_rated badge
    try {
      const categoryRow = await query(
        'SELECT category_id FROM professional_categories WHERE professional_id = $1 LIMIT 1',
        [professionalId]
      );
      if (categoryRow.rows.length > 0) {
        const catId = categoryRow.rows[0].category_id;
        const percentileResult = await query(
          `SELECT COUNT(*) FILTER (WHERE avg_rating <= $2)::float / NULLIF(COUNT(*), 0) AS percentile
           FROM (
             SELECT pc.professional_id, COALESCE(AVG(r.rating), 0) as avg_rating
             FROM professional_categories pc
             LEFT JOIN reviews r ON r.professional_id = pc.professional_id
             WHERE pc.category_id = $1
             GROUP BY pc.professional_id
           ) sub`,
          [catId, stats.average_rating]
        );
        stats.is_top_rated = percentileResult.rows[0]?.percentile >= 0.9;
      } else {
        stats.is_top_rated = false;
      }
    } catch (err) {
      logger.warn({ err: err.message, professionalId }, 'Top rated percentile calculation failed');
      stats.is_top_rated = false;
    }

    // Get earned badges from DB
    let earnedBadges = [];
    try {
      const badgeResult = await query(
        'SELECT badge_type, earned_at, metadata FROM professional_badges WHERE professional_id = $1',
        [professionalId]
      );
      earnedBadges = badgeResult.rows;
    } catch (err) { logger.warn({ err: err.message, professionalId }, 'Badge query failed (table may not exist yet)'); }

    const earnedTypes = new Set(earnedBadges.map((b) => b.badge_type));

    // Build badge list with earned status and progress
    const badges = Object.entries(BADGE_DEFINITIONS).map(([type, def]) => {
      const earned = earnedTypes.has(type);
      const qualifies = def.check(stats);
      const earnedRecord = earnedBadges.find((b) => b.badge_type === type);

      return {
        type,
        emoji: def.emoji,
        label: def.label,
        description: def.description,
        earned,
        qualifies,
        earned_at: earnedRecord?.earned_at || null,
      };
    });

    res.status(200).json({
      success: true,
      data: {
        badges,
        stats: {
          completed_jobs: stats.completed_jobs,
          average_rating: stats.average_rating,
          review_count: stats.review_count,
          response_time_hours: stats.response_time_hours,
          repeat_customer_rate: parseFloat(stats.repeat_customer_rate || 0),
          government_id_verified: stats.government_id_verified,
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/trust/:professionalId/timeline
 * Public — trust timeline showing milestones.
 */
const getTimeline = async (req, res, next) => {
  try {
    const { professionalId } = req.params;

    const proResult = await query(
      `SELECT p.id, p.created_at as joined_at, p.completed_jobs, p.response_time_hours,
              p.repeat_customer_rate, p.total_customers,
              u.name, u.government_id_verified,
              COALESCE(AVG(r.rating), 0) as average_rating,
              COUNT(r.id)::int as review_count
       FROM professionals p
       JOIN users u ON p.user_id = u.id
       LEFT JOIN reviews r ON r.professional_id = p.id
       WHERE p.id = $1
       GROUP BY p.id, u.name, u.government_id_verified`,
      [professionalId]
    );

    if (proResult.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Professional not found.' });
    }

    const pro = proResult.rows[0];

    // Build timeline events
    const timeline = [];

    timeline.push({
      type: 'joined',
      icon: '🚀',
      label: 'Joined SkillConnect',
      date: pro.joined_at,
    });

    if (pro.government_id_verified) {
      timeline.push({
        type: 'verified',
        icon: '🛡️',
        label: 'Identity Verified',
        date: pro.joined_at, // approximate
      });
    }

    // Job milestones
    const jobMilestones = [5, 10, 25, 50, 100, 250, 500];
    for (const m of jobMilestones) {
      if (pro.completed_jobs >= m) {
        timeline.push({
          type: 'milestone',
          icon: '🎯',
          label: `${m} Jobs Completed`,
          value: m,
        });
      }
    }

    // Rating milestones
    const avgRating = parseFloat(pro.average_rating);
    if (pro.review_count >= 5 && avgRating >= 4.0) {
      timeline.push({ type: 'rating', icon: '⭐', label: `${avgRating.toFixed(1)} Average Rating (${pro.review_count} reviews)` });
    }

    // Badges earned
    let earnedBadges = [];
    try {
      const badgeResult = await query(
        'SELECT badge_type, earned_at FROM professional_badges WHERE professional_id = $1 ORDER BY earned_at ASC',
        [professionalId]
      );
      earnedBadges = badgeResult.rows;
    } catch (err) { logger.warn({ err: err.message, professionalId }, 'Timeline badge query failed (table may not exist yet)'); }

    for (const badge of earnedBadges) {
      const def = BADGE_DEFINITIONS[badge.badge_type];
      if (def) {
        timeline.push({
          type: 'badge',
          icon: def.emoji,
          label: `Earned "${def.label}" badge`,
          date: badge.earned_at,
        });
      }
    }

    // Sort by date (most recent first), put undated items at end
    timeline.sort((a, b) => {
      if (!a.date && !b.date) return 0;
      if (!a.date) return 1;
      if (!b.date) return -1;
      return new Date(b.date) - new Date(a.date);
    });

    res.status(200).json({
      success: true,
      data: {
        professional: { name: pro.name, id: pro.id },
        timeline,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/trust/:professionalId/explain
 * Public — explain why this professional is trusted.
 */
const explainTrust = async (req, res, next) => {
  try {
    const { professionalId } = req.params;

    const result = await query(
      `SELECT p.completed_jobs, p.response_time_hours, p.repeat_customer_rate,
              p.total_customers, p.reputation_score,
              u.government_id_verified, u.phone_verified, u.selfie_verified,
              COALESCE(AVG(r.rating), 0) as average_rating,
              COUNT(r.id)::int as review_count
       FROM professionals p
       JOIN users u ON p.user_id = u.id
       LEFT JOIN reviews r ON r.professional_id = p.id
       WHERE p.id = $1
       GROUP BY p.id, u.government_id_verified, u.phone_verified, u.selfie_verified`,
      [professionalId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Professional not found.' });
    }

    const pro = result.rows[0];
    const signals = [];

    if (pro.government_id_verified) {
      signals.push({ icon: '🛡️', label: 'Government ID Verified', strength: 'strong' });
    }
    if (pro.phone_verified) {
      signals.push({ icon: '📱', label: 'Phone Number Verified', strength: 'strong' });
    }
    if (pro.selfie_verified) {
      signals.push({ icon: '📸', label: 'Selfie Verified', strength: 'strong' });
    }
    if (pro.completed_jobs >= 10) {
      signals.push({ icon: '✅', label: `${pro.completed_jobs} Jobs Completed`, strength: pro.completed_jobs >= 50 ? 'strong' : 'moderate' });
    }
    if (pro.response_time_hours && pro.response_time_hours < 1) {
      signals.push({ icon: '⚡', label: `Responds in under ${Math.round(pro.response_time_hours * 60)} minutes`, strength: 'strong' });
    } else if (pro.response_time_hours && pro.response_time_hours < 4) {
      signals.push({ icon: '⏱️', label: `Responds in under ${Math.round(pro.response_time_hours)} hours`, strength: 'moderate' });
    }

    const avgRating = parseFloat(pro.average_rating);
    if (pro.review_count >= 5) {
      signals.push({
        icon: '⭐',
        label: `${avgRating.toFixed(1)} rating from ${pro.review_count} reviews`,
        strength: avgRating >= 4.5 ? 'strong' : avgRating >= 4.0 ? 'moderate' : 'weak',
      });
    }

    const repeatRate = parseFloat(pro.repeat_customer_rate || 0);
    if (repeatRate > 0) {
      signals.push({
        icon: '🔄',
        label: `${repeatRate.toFixed(0)}% repeat customers`,
        strength: repeatRate >= 40 ? 'strong' : 'moderate',
      });
    }

    res.status(200).json({
      success: true,
      data: {
        trust_score: parseFloat(pro.reputation_score),
        signals,
        summary: signals.filter((s) => s.strength === 'strong').length >= 3
          ? 'Highly trusted professional with strong verification and track record.'
          : signals.length >= 3
            ? 'Trusted professional with growing track record.'
            : 'New professional building their reputation.',
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/trust/:professionalId/level
 * Public — get provider's trust level (Bronze/Silver/Gold/Platinum) with score breakdown.
 */
const getTrustLevel = async (req, res, next) => {
  try {
    const { professionalId } = req.params;

    const result = await query(
      `SELECT p.id, p.completed_jobs, p.response_time_hours, p.repeat_customer_rate,
              p.total_customers, p.cancellation_rate, p.trust_level, p.trust_score,
              u.government_id_verified, u.selfie_verified,
              COALESCE(AVG(r.rating), 0) as average_rating,
              COUNT(r.id)::int as review_count
       FROM professionals p
       JOIN users u ON p.user_id = u.id
       LEFT JOIN reviews r ON r.professional_id = p.id
       WHERE p.id = $1
       GROUP BY p.id, u.government_id_verified, u.selfie_verified`,
      [professionalId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Professional not found.' });
    }

    const pro = result.rows[0];
    const avgRating = parseFloat(pro.average_rating);
    const repeatRate = parseFloat(pro.repeat_customer_rate || 0);
    const cancellationRate = parseFloat(pro.cancellation_rate || 0);

    // Calculate trust score (0-100)
    const factors = {
      verification: (pro.government_id_verified ? 15 : 0) + (pro.selfie_verified ? 10 : 0),
      experience: Math.min(20, (pro.completed_jobs || 0) * 0.2),
      rating: Math.min(25, avgRating * 5),
      repeat_customers: Math.min(15, repeatRate * 0.3),
      responsiveness: pro.response_time_hours && pro.response_time_hours < 1 ? 10 : pro.response_time_hours < 4 ? 5 : 0,
      reliability: Math.max(0, 5 - cancellationRate * 0.5),
    };
    const calculatedScore = Object.values(factors).reduce((sum, v) => sum + v, 0);

    // Determine trust level
    let level = 'bronze';
    if (calculatedScore >= 85 && pro.completed_jobs >= 100 && avgRating >= 4.7 && repeatRate >= 50 && cancellationRate <= 5) {
      level = 'platinum';
    } else if (calculatedScore >= 60 && pro.completed_jobs >= 50 && avgRating >= 4.2 && repeatRate >= 30 && cancellationRate <= 15) {
      level = 'gold';
    } else if (calculatedScore >= 30 && pro.completed_jobs >= 10 && avgRating >= 3.5 && repeatRate >= 10 && cancellationRate <= 30) {
      level = 'silver';
    }

    // Get level config for benefits
    let levelConfig = null;
    try {
      const configResult = await query('SELECT * FROM trust_level_config WHERE level = $1', [level]);
      levelConfig = configResult.rows[0] || null;
    } catch (err) { /* table may not exist yet */ }

    // Next level requirements
    const levels = ['bronze', 'silver', 'gold', 'platinum'];
    const currentIdx = levels.indexOf(level);
    let nextLevelRequirements = null;
    if (currentIdx < levels.length - 1) {
      const nextLevel = levels[currentIdx + 1];
      try {
        const nextConfig = await query('SELECT * FROM trust_level_config WHERE level = $1', [nextLevel]);
        if (nextConfig.rows[0]) {
          const nc = nextConfig.rows[0];
          nextLevelRequirements = {
            level: nextLevel,
            min_score: parseFloat(nc.min_score),
            min_completed_jobs: nc.min_completed_jobs,
            min_rating: parseFloat(nc.min_rating),
            min_repeat_rate: parseFloat(nc.min_repeat_rate),
            max_cancellation_rate: parseFloat(nc.max_cancellation_rate),
            progress: {
              score: Math.min(100, Math.round((calculatedScore / parseFloat(nc.min_score)) * 100)),
              jobs: Math.min(100, Math.round((pro.completed_jobs / nc.min_completed_jobs) * 100)),
              rating: Math.min(100, Math.round((avgRating / parseFloat(nc.min_rating)) * 100)),
              repeat_rate: Math.min(100, Math.round((repeatRate / parseFloat(nc.min_repeat_rate)) * 100)),
            },
          };
        }
      } catch (err) { /* table may not exist */ }
    }

    res.status(200).json({
      success: true,
      data: {
        trust_level: level,
        trust_score: Math.round(calculatedScore * 100) / 100,
        score_breakdown: factors,
        badge_color: levelConfig?.badge_color || '#CD7F32',
        benefits: levelConfig?.benefits || { verified_badge: true },
        next_level: nextLevelRequirements,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/trust/:professionalId/neighborhood
 * Public — get neighborhood trust scores for a provider.
 */
const getNeighborhoodTrust = async (req, res, next) => {
  try {
    const { professionalId } = req.params;
    const { city, locality } = req.query;

    let whereClause = 'WHERE nt.professional_id = $1';
    const params = [professionalId];
    let idx = 2;

    if (city) {
      whereClause += ` AND nt.city ILIKE $${idx}`;
      params.push(`%${city}%`);
      idx++;
    }
    if (locality) {
      whereClause += ` AND nt.locality ILIKE $${idx}`;
      params.push(`%${locality}%`);
      idx++;
    }

    const result = await query(
      `SELECT nt.*, 
              RANK() OVER (PARTITION BY nt.city ORDER BY nt.neighborhood_score DESC) as city_rank
       FROM neighborhood_trust nt
       ${whereClause}
       ORDER BY nt.neighborhood_score DESC
       LIMIT 20`,
      params
    );

    res.status(200).json({
      success: true,
      data: result.rows.map((row) => ({
        ...row,
        neighborhood_score: parseFloat(row.neighborhood_score),
        average_rating: parseFloat(row.average_rating || 0),
      })),
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/trust/neighborhood/top
 * Public — get top-trusted providers in a locality.
 */
const getTopInNeighborhood = async (req, res, next) => {
  try {
    const { city, locality, limit: queryLimit } = req.query;

    if (!city) {
      return res.status(400).json({ success: false, message: 'city query parameter is required' });
    }

    const limitNum = Math.min(50, Math.max(1, parseInt(queryLimit, 10) || 10));
    let whereClause = 'WHERE nt.city ILIKE $1';
    const params = [`%${city}%`];
    let idx = 2;

    if (locality) {
      whereClause += ` AND nt.locality ILIKE $${idx}`;
      params.push(`%${locality}%`);
      idx++;
    }

    params.push(limitNum);

    const result = await query(
      `SELECT nt.*, p.headline, u.name as professional_name, u.avatar_url
       FROM neighborhood_trust nt
       JOIN professionals p ON nt.professional_id = p.id
       JOIN users u ON p.user_id = u.id
       ${whereClause}
       ORDER BY nt.neighborhood_score DESC
       LIMIT $${idx}`,
      params
    );

    res.status(200).json({
      success: true,
      data: result.rows.map((row) => ({
        ...row,
        neighborhood_score: parseFloat(row.neighborhood_score),
        average_rating: parseFloat(row.average_rating || 0),
      })),
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getBadges,
  getTimeline,
  explainTrust,
  getTrustLevel,
  getNeighborhoodTrust,
  getTopInNeighborhood,
  BADGE_DEFINITIONS,
};
