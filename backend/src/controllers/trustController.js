const { query } = require('../config/database');

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
    stats.is_top_rated = false; // would need category-level percentile calculation

    // Get earned badges from DB
    let earnedBadges = [];
    try {
      const badgeResult = await query(
        'SELECT badge_type, earned_at, metadata FROM professional_badges WHERE professional_id = $1',
        [professionalId]
      );
      earnedBadges = badgeResult.rows;
    } catch { /* table may not exist yet */ }

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
    } catch { /* table may not exist yet */ }

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

module.exports = {
  getBadges,
  getTimeline,
  explainTrust,
  BADGE_DEFINITIONS,
};
