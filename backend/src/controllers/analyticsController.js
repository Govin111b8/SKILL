const { query } = require('../config/database');

// Get analytics data for professional — monthly earnings, bookings over time
const getAnalytics = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const role = req.user.role;

    if (role !== 'professional') {
      return res.status(403).json({ success: false, message: 'Analytics only available for professionals' });
    }

    const profResult = await query(
      `SELECT id FROM professionals WHERE user_id = $1`,
      [userId]
    );

    if (profResult.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Professional profile not found' });
    }

    const professionalId = profResult.rows[0].id;

    // Monthly earnings for the last 12 months
    const monthlyEarnings = await query(
      `SELECT
         date_trunc('month', completed_at) AS month,
         COALESCE(SUM(final_amount), 0)::float AS earnings,
         COUNT(*)::int AS bookings_completed
       FROM bookings
       WHERE professional_id = $1
         AND status = 'completed'
         AND completed_at >= NOW() - INTERVAL '12 months'
       GROUP BY date_trunc('month', completed_at)
       ORDER BY month ASC`,
      [professionalId]
    );

    // Weekly bookings for the last 8 weeks
    const weeklyBookings = await query(
      `SELECT
         date_trunc('week', created_at) AS week,
         COUNT(*)::int AS total,
         COUNT(*) FILTER (WHERE status = 'completed')::int AS completed,
         COUNT(*) FILTER (WHERE status = 'cancelled')::int AS cancelled
       FROM bookings
       WHERE professional_id = $1
         AND created_at >= NOW() - INTERVAL '8 weeks'
       GROUP BY date_trunc('week', created_at)
       ORDER BY week ASC`,
      [professionalId]
    );

    // Review ratings distribution
    const ratingDistribution = await query(
      `SELECT rating, COUNT(*)::int AS count
       FROM reviews
       WHERE professional_id = $1
       GROUP BY rating
       ORDER BY rating`,
      [professionalId]
    );

    // Top customers by booking count
    const topCustomers = await query(
      `SELECT u.name, u.avatar_url, COUNT(b.id)::int AS bookings,
              COALESCE(SUM(b.final_amount), 0)::float AS total_spent
       FROM bookings b
       JOIN users u ON b.customer_id = u.id
       WHERE b.professional_id = $1
       GROUP BY u.id, u.name, u.avatar_url
       ORDER BY bookings DESC
       LIMIT 5`,
      [professionalId]
    );

    // Recent activity (last 30 days)
    const recentActivity = await query(
      `SELECT
         COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '7 days')::int AS bookings_7d,
         COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '30 days')::int AS bookings_30d,
         COUNT(*) FILTER (WHERE status = 'completed' AND completed_at >= NOW() - INTERVAL '30 days')::int AS completed_30d
       FROM bookings
       WHERE professional_id = $1`,
      [professionalId]
    );

    res.json({
      success: true,
      data: {
        monthlyEarnings: monthlyEarnings.rows,
        weeklyBookings: weeklyBookings.rows,
        ratingDistribution: ratingDistribution.rows,
        topCustomers: topCustomers.rows,
        recentActivity: recentActivity.rows[0] || {},
      },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = { getAnalytics };
