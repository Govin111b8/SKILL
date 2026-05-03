const { pool } = require('../config/database');

/**
 * Matching Engine - Returns Top N ranked providers based on:
 * - Distance (proximity to customer)
 * - Rating (average review score)
 * - Availability (currently available status)
 * - Response time (faster = better)
 *
 * Formula: weighted composite score
 * - Distance score: 30% weight (closer = higher)
 * - Rating score: 35% weight (higher rating = higher)
 * - Availability bonus: 15% weight (available > busy > offline)
 * - Response time: 20% weight (faster = higher)
 */
async function matchProviders(req, res, next) {
  try {
    const {
      category_id,
      latitude,
      longitude,
      limit = 10,
      radius_km = 50
    } = req.query;

    if (!latitude || !longitude) {
      return res.status(400).json({ error: 'Latitude and longitude are required for matching' });
    }

    if (!category_id) {
      return res.status(400).json({ error: 'Category ID is required' });
    }

    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);
    const maxResults = Math.min(Math.max(parseInt(limit) || 10, 3), 10);
    const radiusKm = parseInt(radius_km) || 50;

    // Main matching query with composite scoring
    const query = `
      WITH provider_data AS (
        SELECT
          p.id as professional_id,
          p.user_id,
          u.name,
          u.avatar_url,
          p.headline,
          p.bio,
          p.pricing_estimate,
          p.availability_status,
          p.response_time_hours,
          p.completed_jobs,
          p.reputation_score,
          p.latitude as pro_lat,
          p.longitude as pro_lng,
          p.provider_type,
          p.service_location_radius_km,
          -- Calculate distance using Haversine formula
          (6371 * acos(
            LEAST(1.0, cos(radians($1)) * cos(radians(p.latitude))
            * cos(radians(p.longitude) - radians($2))
            + sin(radians($1)) * sin(radians(p.latitude)))
          )) as distance_km,
          -- Average rating
          COALESCE(AVG(r.rating), 0) as avg_rating,
          COUNT(r.id) as review_count
        FROM professionals p
        JOIN users u ON u.id = p.user_id
        JOIN professional_categories pc ON pc.professional_id = p.id
        LEFT JOIN reviews r ON r.professional_id = p.id
        WHERE pc.category_id = $3
          AND p.latitude IS NOT NULL
          AND p.longitude IS NOT NULL
        GROUP BY p.id, u.id
      )
      SELECT *,
        -- Composite matching score (0-100)
        (
          -- Distance score (30% weight): closer = higher score, max at 0km, 0 at radius
          (GREATEST(0, (1 - (distance_km / $4))) * 30) +
          -- Rating score (35% weight): 5.0 = 35 points
          ((avg_rating / 5.0) * 35) +
          -- Availability bonus (15% weight)
          (CASE availability_status
            WHEN 'available' THEN 15
            WHEN 'busy' THEN 5
            ELSE 0
          END) +
          -- Response time score (20% weight): faster = better, max 24h baseline
          (CASE
            WHEN response_time_hours IS NULL THEN 10
            WHEN response_time_hours <= 1 THEN 20
            WHEN response_time_hours <= 4 THEN 15
            WHEN response_time_hours <= 12 THEN 10
            ELSE 5
          END)
        ) as match_score
      FROM provider_data
      WHERE distance_km <= $4
      ORDER BY match_score DESC, distance_km ASC
      LIMIT $5
    `;

    const result = await pool.query(query, [lat, lng, category_id, radiusKm, maxResults]);

    res.json({
      success: true,
      matched_providers: result.rows.map(row => ({
        professional_id: row.professional_id,
        user_id: row.user_id,
        name: row.name,
        avatar_url: row.avatar_url,
        headline: row.headline,
        pricing_estimate: row.pricing_estimate,
        availability_status: row.availability_status,
        distance_km: Math.round(row.distance_km * 10) / 10,
        avg_rating: parseFloat(row.avg_rating).toFixed(1),
        review_count: parseInt(row.review_count),
        response_time_hours: row.response_time_hours,
        completed_jobs: row.completed_jobs,
        match_score: Math.round(row.match_score),
        provider_type: row.provider_type
      })),
      meta: {
        category_id: parseInt(category_id),
        location: { latitude: lat, longitude: lng },
        radius_km: radiusKm,
        total_matched: result.rows.length,
        max_results: maxResults
      }
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { matchProviders };
