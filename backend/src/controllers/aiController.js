/**
 * AI Controller — Exposes AI-powered endpoints
 * 
 * Endpoints:
 * - POST /api/ai/search-intent     — Parse natural language search query
 * - POST /api/ai/recommendations   — Get personalized service recommendations
 * - POST /api/ai/sentiment         — Analyze review sentiment
 * - POST /api/ai/categorize        — Auto-categorize a service description
 * - POST /api/ai/pricing           — Get smart pricing suggestions
 * - POST /api/ai/chat              — AI chatbot interaction
 */

const { query } = require('../config/database');
const ai = require('../services/ai');

/**
 * POST /api/ai/search-intent
 * Parse a natural language search query into structured intent
 */
async function searchIntent(req, res, next) {
  try {
    const { q } = req.body;
    if (!q || typeof q !== 'string') {
      return res.status(400).json({ success: false, message: 'Query text (q) is required' });
    }

    const intent = await ai.parseSearchIntent(q.trim().substring(0, 500));
    res.json({ success: true, data: intent });
  } catch (err) {
    next(err);
  }
}

/**
 * POST /api/ai/recommendations
 * Get personalized service recommendations for the authenticated user
 */
async function recommendations(req, res, next) {
  try {
    const userId = req.user.id;

    // Fetch user's recent bookings
    const bookingsResult = await query(
      `SELECT b.title, b.status, c.name as category
       FROM bookings b
       LEFT JOIN categories c ON b.category_id = c.id
       WHERE b.customer_id = $1
       ORDER BY b.created_at DESC LIMIT 10`,
      [userId]
    );

    // Fetch user's favorite categories
    const favResult = await query(
      `SELECT c.name FROM favorites f
       JOIN professionals p ON f.professional_id = p.id
       JOIN professional_categories pc ON p.id = pc.professional_id
       JOIN categories c ON pc.category_id = c.id
       WHERE f.user_id = $1
       GROUP BY c.name ORDER BY COUNT(*) DESC LIMIT 5`,
      [userId]
    );

    const context = {
      location: req.user.location,
      recentBookings: bookingsResult.rows,
      favoriteCategories: favResult.rows.map(r => r.name),
    };

    const recs = await ai.getPersonalizedRecommendations(userId, context);
    res.json({ success: true, data: recs });
  } catch (err) {
    next(err);
  }
}

/**
 * POST /api/ai/sentiment
 * Analyze sentiment of a review text
 */
async function sentiment(req, res, next) {
  try {
    const { text } = req.body;
    if (!text || typeof text !== 'string') {
      return res.status(400).json({ success: false, message: 'Review text is required' });
    }

    const result = await ai.analyzeReviewSentiment(text.substring(0, 2000));
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

/**
 * POST /api/ai/categorize
 * Auto-categorize a service description
 */
async function categorize(req, res, next) {
  try {
    const { description } = req.body;
    if (!description || typeof description !== 'string') {
      return res.status(400).json({ success: false, message: 'Service description is required' });
    }

    const result = await ai.suggestCategory(description.substring(0, 1000));
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

/**
 * POST /api/ai/pricing
 * Get smart pricing suggestions for a service
 */
async function pricing(req, res, next) {
  try {
    const { category, location, complexity } = req.body;
    if (!category) {
      return res.status(400).json({ success: false, message: 'Category is required' });
    }

    // Get market data for this category
    const marketResult = await query(
      `SELECT AVG(final_amount) as average, COUNT(*) as total_bookings
       FROM bookings b
       JOIN categories c ON b.category_id = c.id
       WHERE c.name ILIKE $1 AND b.status = 'completed' AND b.final_amount IS NOT NULL`,
      [`%${category}%`]
    );

    const marketData = {
      average: marketResult.rows[0]?.average || null,
      totalBookings: parseInt(marketResult.rows[0]?.total_bookings) || 0,
    };

    const result = await ai.suggestPricing({ category, location, complexity, marketData });
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

/**
 * POST /api/ai/chat
 * AI chatbot interaction
 */
async function chat(req, res, next) {
  try {
    const { message } = req.body;
    if (!message || typeof message !== 'string') {
      return res.status(400).json({ success: false, message: 'Message is required' });
    }

    // Get user context
    let recentBookings = [];
    if (req.user) {
      const bookings = await query(
        `SELECT b.title, b.status, b.created_at FROM bookings
         WHERE customer_id = $1 OR professional_id = (SELECT id FROM professionals WHERE user_id = $1)
         ORDER BY created_at DESC LIMIT 3`,
        [req.user.id]
      );
      recentBookings = bookings.rows;
    }

    const context = {
      userName: req.user?.name || 'Guest',
      recentBookings,
    };

    const result = await ai.generateChatbotResponse(message.substring(0, 1000), context);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

module.exports = { searchIntent, recommendations, sentiment, categorize, pricing, chat };
