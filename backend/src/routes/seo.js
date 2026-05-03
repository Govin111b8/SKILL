/**
 * SEO Routes — Sitemap, robots.txt, and structured data endpoints
 */
const express = require('express');
const router = express.Router();
const { pool } = require('../config/database');

const BASE_URL = process.env.APP_URL || 'https://skillconnect.in';

/**
 * GET /api/seo/sitemap.xml
 * Dynamic XML sitemap for SEO crawlers
 */
router.get('/sitemap.xml', async (req, res) => {
  try {
    // Get all active professionals
    const prosResult = await pool.query(
      `SELECT p.id, p.updated_at FROM professionals p
       JOIN users u ON p.user_id = u.id
       WHERE p.is_verified = TRUE AND u.is_active = TRUE
       ORDER BY p.updated_at DESC LIMIT 5000`
    );

    // Get all categories
    const catsResult = await pool.query(
      `SELECT slug, updated_at FROM categories WHERE is_active = TRUE ORDER BY name`
    );

    const staticPages = [
      { url: '/', priority: '1.0', changefreq: 'daily' },
      { url: '/search', priority: '0.9', changefreq: 'daily' },
      { url: '/categories', priority: '0.8', changefreq: 'weekly' },
      { url: '/register', priority: '0.7', changefreq: 'monthly' },
      { url: '/login', priority: '0.5', changefreq: 'monthly' },
    ];

    let xml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
`;

    // Static pages
    for (const page of staticPages) {
      xml += `  <url>
    <loc>${BASE_URL}${page.url}</loc>
    <changefreq>${page.changefreq}</changefreq>
    <priority>${page.priority}</priority>
  </url>
`;
    }

    // Category pages
    for (const cat of catsResult.rows) {
      xml += `  <url>
    <loc>${BASE_URL}/categories/${cat.slug}</loc>
    <lastmod>${new Date(cat.updated_at || Date.now()).toISOString().split('T')[0]}</lastmod>
    <changefreq>weekly</changefreq>
    <priority>0.7</priority>
  </url>
`;
    }

    // Professional profiles
    for (const pro of prosResult.rows) {
      xml += `  <url>
    <loc>${BASE_URL}/professionals/${pro.id}</loc>
    <lastmod>${new Date(pro.updated_at || Date.now()).toISOString().split('T')[0]}</lastmod>
    <changefreq>weekly</changefreq>
    <priority>0.6</priority>
  </url>
`;
    }

    xml += `</urlset>`;

    res.set('Content-Type', 'application/xml');
    res.set('Cache-Control', 'public, max-age=3600'); // Cache for 1 hour
    res.send(xml);
  } catch (err) {
    res.status(500).send('<?xml version="1.0"?><urlset></urlset>');
  }
});

/**
 * GET /api/seo/robots.txt
 * Robots.txt for crawler instructions
 */
router.get('/robots.txt', (req, res) => {
  const robots = `User-agent: *
Allow: /
Disallow: /dashboard
Disallow: /settings
Disallow: /messages
Disallow: /bookings
Disallow: /admin
Disallow: /api/

Sitemap: ${BASE_URL}/sitemap.xml

# Crawl-delay for responsible scraping
Crawl-delay: 1
`;
  res.set('Content-Type', 'text/plain');
  res.send(robots);
});

module.exports = router;
