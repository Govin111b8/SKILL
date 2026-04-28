const { query } = require('../config/database');

const getDashboard = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const role = req.user.role;

    if (role === 'professional') {
      return getProfessionalDashboard(userId, res, next);
    }
    return getCustomerDashboard(userId, res, next);
  } catch (error) {
    next(error);
  }
};

async function getProfessionalDashboard(userId, res, next) {
  try {
    const profResult = await query(
      `SELECT p.*, u.name, u.email, u.phone, u.location, u.avatar_url
       FROM professionals p
       JOIN users u ON p.user_id = u.id
       WHERE p.user_id = $1`,
      [userId]
    );

    if (profResult.rows.length === 0) {
      return res.status(200).json({
        success: true,
        data: {
          profile: null,
          stats: { views: 0, contacts: 0, rating: 0, reviews: 0, completedJobs: 0 },
          recentRequests: [],
          portfolio: [],
          completeness: 0,
          needsProfile: true,
        },
      });
    }

    const prof = profResult.rows[0];
    const professionalId = prof.id;

    // Stats
    const reviewStats = await query(
      `SELECT COALESCE(AVG(rating), 0) as avg_rating, COUNT(*) as review_count
       FROM reviews WHERE professional_id = $1`,
      [professionalId]
    );

    const contactCount = await query(
      `SELECT COUNT(*) FROM contacts WHERE professional_id = $1`,
      [professionalId]
    );

    // Recent contact requests
    const recentRequests = await query(
      `SELECT c.*, u.name as customer_name, u.email as customer_email
       FROM contacts c
       JOIN users u ON c.customer_id = u.id
       WHERE c.professional_id = $1
       ORDER BY c.created_at DESC LIMIT 10`,
      [professionalId]
    );

    // Portfolio
    const portfolio = await query(
      `SELECT * FROM portfolio_items WHERE professional_id = $1 ORDER BY created_at DESC`,
      [professionalId]
    );

    // Categories
    const categories = await query(
      `SELECT c.id, c.name FROM categories c
       JOIN professional_categories pc ON c.id = pc.category_id
       WHERE pc.professional_id = $1`,
      [professionalId]
    );

    // Profile completeness
    let completeness = 0;
    const fields = [prof.headline, prof.bio, prof.years_of_experience, prof.pricing_estimate, prof.latitude];
    completeness += fields.filter(Boolean).length * 12; // 60% for fields
    completeness += categories.rows.length > 0 ? 15 : 0;
    completeness += portfolio.rows.length > 0 ? 15 : 0;
    completeness += prof.name ? 10 : 0;
    completeness = Math.min(completeness, 100);

    // Booking funnel + earnings (real data)
    const funnel = await query(
      `SELECT status, COUNT(*)::int AS count, COALESCE(SUM(final_amount), 0)::float AS revenue
       FROM bookings
       WHERE professional_id = $1
       GROUP BY status`,
      [professionalId]
    );
    const fmap = {};
    for (const row of funnel.rows) fmap[row.status] = { count: row.count, revenue: row.revenue };
    const totalBookings = funnel.rows.reduce((a, r) => a + r.count, 0);
    const completedCount = fmap.completed?.count || 0;
    const conversion = totalBookings > 0 ? (completedCount / totalBookings * 100) : 0;

    // Earnings windows
    const earningsRow = await query(
      `SELECT
         COALESCE(SUM(final_amount) FILTER (WHERE status = 'completed'), 0)::float AS lifetime,
         COALESCE(SUM(final_amount) FILTER (WHERE status = 'completed' AND completed_at >= date_trunc('month', NOW())), 0)::float AS this_month,
         COALESCE(SUM(final_amount) FILTER (WHERE status = 'completed' AND completed_at >= NOW() - INTERVAL '7 days'), 0)::float AS last_7d,
         COALESCE(SUM(quoted_amount) FILTER (WHERE status IN ('quoted','accepted','scheduled','in_progress')), 0)::float AS pipeline
       FROM bookings WHERE professional_id = $1`,
      [professionalId]
    );

    // Unread count for badge
    const unread = await query(`SELECT COUNT(*)::int AS c FROM notifications WHERE user_id = $1 AND read_at IS NULL`, [userId]);

    res.status(200).json({
      success: true,
      data: {
        profile: {
          ...prof,
          categories: categories.rows,
        },
        stats: {
          views: Math.floor(Math.random() * 200) + 50, // placeholder
          contacts: parseInt(contactCount.rows[0].count),
          rating: parseFloat(reviewStats.rows[0].avg_rating).toFixed(1),
          reviews: parseInt(reviewStats.rows[0].review_count),
          completedJobs: prof.completed_jobs || 0,
          responseTime: prof.response_time_hours || null,
          unreadNotifications: unread.rows[0].c,
        },
        earnings: {
          lifetime: earningsRow.rows[0].lifetime,
          thisMonth: earningsRow.rows[0].this_month,
          last7d: earningsRow.rows[0].last_7d,
          pipeline: earningsRow.rows[0].pipeline,
          currency: 'INR',
        },
        funnel: {
          requested: fmap.requested?.count || 0,
          quoted: fmap.quoted?.count || 0,
          accepted: fmap.accepted?.count || 0,
          scheduled: fmap.scheduled?.count || 0,
          inProgress: fmap.in_progress?.count || 0,
          completed: completedCount,
          cancelled: fmap.cancelled?.count || 0,
          disputed: fmap.disputed?.count || 0,
          conversionPct: Math.round(conversion * 10) / 10,
          totalBookings,
        },
        recentRequests: recentRequests.rows,
        portfolio: portfolio.rows,
        completeness,
      },
    });
  } catch (error) {
    next(error);
  }
}

async function getCustomerDashboard(userId, res, next) {
  try {
    // Recent contacts
    const contacts = await query(
      `SELECT c.*, u.name as professional_name, p.headline
       FROM contacts c
       JOIN professionals p ON c.professional_id = p.id
       JOIN users u ON p.user_id = u.id
       WHERE c.customer_id = $1
       ORDER BY c.created_at DESC LIMIT 10`,
      [userId]
    );

    // Reviews given
    const reviews = await query(
      `SELECT r.*, u.name as professional_name
       FROM reviews r
       JOIN professionals p ON r.professional_id = p.id
       JOIN users u ON p.user_id = u.id
       WHERE r.customer_id = $1
       ORDER BY r.created_at DESC LIMIT 10`,
      [userId]
    );

    // Stats
    const contactCount = await query(
      `SELECT COUNT(*) FROM contacts WHERE customer_id = $1`, [userId]
    );
    const reviewCount = await query(
      `SELECT COUNT(*) FROM reviews WHERE customer_id = $1`, [userId]
    );

    // Bookings summary
    const bookingStats = await query(
      `SELECT
         COUNT(*)::int AS total,
         COUNT(*) FILTER (WHERE status = 'completed')::int AS completed,
         COUNT(*) FILTER (WHERE status IN ('requested','quoted','accepted','scheduled','in_progress'))::int AS active,
         COALESCE(SUM(final_amount) FILTER (WHERE status = 'completed'), 0)::float AS total_spent
       FROM bookings WHERE customer_id = $1`,
      [userId]
    );

    const recentBookings = await query(
      `SELECT b.id, b.title, b.status, b.created_at, b.quoted_amount, b.final_amount,
              u.name AS professional_name
       FROM bookings b
       JOIN professionals p ON b.professional_id = p.id
       JOIN users u ON p.user_id = u.id
       WHERE b.customer_id = $1
       ORDER BY b.updated_at DESC LIMIT 5`,
      [userId]
    );

    const favCount = await query(`SELECT COUNT(*)::int AS c FROM favorites WHERE user_id = $1`, [userId]);
    const unread = await query(`SELECT COUNT(*)::int AS c FROM notifications WHERE user_id = $1 AND read_at IS NULL`, [userId]);

    res.status(200).json({
      success: true,
      data: {
        recentContacts: contacts.rows,
        reviewsGiven: reviews.rows,
        recentBookings: recentBookings.rows,
        stats: {
          totalContacts: parseInt(contactCount.rows[0].count),
          totalReviews: parseInt(reviewCount.rows[0].count),
          totalBookings: bookingStats.rows[0].total,
          activeBookings: bookingStats.rows[0].active,
          completedBookings: bookingStats.rows[0].completed,
          totalSpent: bookingStats.rows[0].total_spent,
          favorites: favCount.rows[0].c,
          unreadNotifications: unread.rows[0].c,
        },
      },
    });
  } catch (error) {
    next(error);
  }
}

module.exports = { getDashboard };
