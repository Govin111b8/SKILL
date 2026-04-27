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

    res.status(200).json({
      success: true,
      data: {
        recentContacts: contacts.rows,
        reviewsGiven: reviews.rows,
        stats: {
          totalContacts: parseInt(contactCount.rows[0].count),
          totalReviews: parseInt(reviewCount.rows[0].count),
        },
      },
    });
  } catch (error) {
    next(error);
  }
}

module.exports = { getDashboard };
