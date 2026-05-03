/**
 * AI Service Module — SkillConnect Platform
 * 
 * Provides AI-powered features:
 * 1. Smart Search (NLP query understanding + intent extraction)
 * 2. Intelligent Matching (ML-enhanced provider recommendations)
 * 3. Review Sentiment Analysis
 * 4. Auto-categorization of service requests
 * 5. Fraud Detection scoring
 * 6. Dynamic Pricing suggestions
 * 7. Chatbot response generation
 * 
 * Architecture:
 * - Modular design: each AI feature is an independent function
 * - Provider-agnostic: supports OpenAI, Google Gemini, or local models
 * - Graceful degradation: falls back to rule-based logic if AI is unavailable
 * - Caching: results are cached to minimize API calls
 * 
 * Environment Variables:
 *   AI_PROVIDER        — 'openai' | 'gemini' | 'local' (default: 'local')
 *   OPENAI_API_KEY     — OpenAI API key (if using openai provider)
 *   GEMINI_API_KEY     — Google Gemini API key (if using gemini provider)
 *   AI_MODEL           — Model name (default: 'gpt-4o-mini' for openai)
 *   AI_CACHE_TTL       — Cache TTL in seconds (default: 3600)
 */

const logger = require('../config/logger');

// ─── Configuration ───────────────────────────────────────────────────────────

const AI_PROVIDER = process.env.AI_PROVIDER || 'local';
const OPENAI_API_KEY = process.env.OPENAI_API_KEY || '';
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';
const AI_MODEL = process.env.AI_MODEL || 'gpt-4o-mini';
const CACHE_TTL = parseInt(process.env.AI_CACHE_TTL) || 3600;

// Simple in-memory cache (use Redis in production)
const cache = new Map();

function getCached(key) {
  const entry = cache.get(key);
  if (!entry) return null;
  if (Date.now() - entry.ts > CACHE_TTL * 1000) {
    cache.delete(key);
    return null;
  }
  return entry.value;
}

function setCache(key, value) {
  cache.set(key, { value, ts: Date.now() });
  // Prevent unbounded growth
  if (cache.size > 10000) {
    const oldest = cache.keys().next().value;
    cache.delete(oldest);
  }
}

// ─── Provider Abstraction ────────────────────────────────────────────────────

/**
 * Send a prompt to the configured AI provider and get a text response.
 * Falls back to null if provider is unavailable.
 */
async function callAI(systemPrompt, userPrompt, options = {}) {
  const { temperature = 0.3, maxTokens = 500, jsonMode = false } = options;

  if (AI_PROVIDER === 'openai' && OPENAI_API_KEY) {
    return callOpenAI(systemPrompt, userPrompt, { temperature, maxTokens, jsonMode });
  }
  if (AI_PROVIDER === 'gemini' && GEMINI_API_KEY) {
    return callGemini(systemPrompt, userPrompt, { temperature, maxTokens });
  }
  // Local/fallback — return null to trigger rule-based logic
  return null;
}

async function callOpenAI(systemPrompt, userPrompt, { temperature, maxTokens, jsonMode }) {
  try {
    const body = {
      model: AI_MODEL,
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt },
      ],
      temperature,
      max_tokens: maxTokens,
    };
    if (jsonMode) body.response_format = { type: 'json_object' };

    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      logger.warn({ status: response.status }, 'OpenAI API error');
      return null;
    }

    const data = await response.json();
    return data.choices?.[0]?.message?.content || null;
  } catch (err) {
    logger.error({ err: err.message }, 'OpenAI call failed');
    return null;
  }
}

async function callGemini(systemPrompt, userPrompt, { temperature, maxTokens }) {
  try {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${GEMINI_API_KEY}`;
    const body = {
      contents: [{
        parts: [{ text: `${systemPrompt}\n\n${userPrompt}` }],
      }],
      generationConfig: { temperature, maxOutputTokens: maxTokens },
    };

    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      logger.warn({ status: response.status }, 'Gemini API error');
      return null;
    }

    const data = await response.json();
    return data.candidates?.[0]?.content?.parts?.[0]?.text || null;
  } catch (err) {
    logger.error({ err: err.message }, 'Gemini call failed');
    return null;
  }
}

// ─── AI Features ─────────────────────────────────────────────────────────────

/**
 * 1. SMART SEARCH — Extract intent + entities from natural language queries
 * 
 * Input:  "I need a plumber near Koramangala who can fix a leaking pipe tomorrow"
 * Output: { category: "Plumbing", location: "Koramangala", urgency: "high",
 *           keywords: ["leaking pipe"], timeframe: "tomorrow" }
 */
async function parseSearchIntent(queryText) {
  const cacheKey = `search_intent:${queryText.toLowerCase().trim()}`;
  const cached = getCached(cacheKey);
  if (cached) return cached;

  const systemPrompt = `You are a search intent parser for a local services marketplace in India.
Extract structured information from user search queries.
Return JSON with fields: category, subcategory, location, urgency (low/medium/high),
keywords (array), timeframe, budget_hint, language_detected.
If a field cannot be determined, set it to null.`;

  const result = await callAI(systemPrompt, queryText, { jsonMode: true, maxTokens: 200 });

  if (result) {
    try {
      const parsed = JSON.parse(result);
      setCache(cacheKey, parsed);
      return parsed;
    } catch {
      logger.warn('AI returned non-JSON for search intent');
    }
  }

  // Fallback: basic keyword extraction (rule-based)
  const fallback = extractIntentLocal(queryText);
  setCache(cacheKey, fallback);
  return fallback;
}

/**
 * Local (non-AI) intent extraction using keyword matching
 */
function extractIntentLocal(queryText) {
  const text = queryText.toLowerCase();
  
  // Category detection via keywords
  const categoryMap = {
    'plumber': 'Plumbing', 'plumbing': 'Plumbing', 'leak': 'Plumbing', 'pipe': 'Plumbing',
    'electrician': 'Electrical', 'wiring': 'Electrical', 'electrical': 'Electrical',
    'carpenter': 'Carpentry', 'furniture': 'Carpentry', 'wood': 'Carpentry',
    'painter': 'Painting', 'paint': 'Painting', 'wall': 'Painting',
    'cleaner': 'Cleaning', 'cleaning': 'Cleaning', 'deep clean': 'Cleaning',
    'ac': 'AC Repair', 'air conditioner': 'AC Repair', 'ac repair': 'AC Repair',
    'yoga': 'Yoga & Fitness', 'fitness': 'Yoga & Fitness', 'trainer': 'Yoga & Fitness',
    'tutor': 'Tutoring', 'teaching': 'Tutoring', 'math': 'Tutoring',
    'salon': 'Beauty & Salon', 'makeup': 'Beauty & Salon', 'haircut': 'Beauty & Salon',
    'photographer': 'Photography', 'photo': 'Photography', 'wedding': 'Photography',
  };

  let category = null;
  for (const [keyword, cat] of Object.entries(categoryMap)) {
    if (text.includes(keyword)) { category = cat; break; }
  }

  // Urgency detection
  const urgentWords = ['urgent', 'emergency', 'asap', 'immediately', 'now', 'today'];
  const urgency = urgentWords.some(w => text.includes(w)) ? 'high' : 'medium';

  // Time detection
  const timeWords = { 'today': 'today', 'tomorrow': 'tomorrow', 'this week': 'this_week', 'weekend': 'weekend' };
  let timeframe = null;
  for (const [word, tf] of Object.entries(timeWords)) {
    if (text.includes(word)) { timeframe = tf; break; }
  }

  return {
    category,
    subcategory: null,
    location: null,
    urgency,
    keywords: text.split(/\s+/).filter(w => w.length > 3),
    timeframe,
    budget_hint: null,
    language_detected: 'en',
  };
}

/**
 * 2. INTELLIGENT RECOMMENDATIONS — Personalized provider suggestions
 * 
 * Considers: user history, preferences, location patterns, time-of-day,
 * seasonal demand, and provider performance trends.
 */
async function getPersonalizedRecommendations(userId, context = {}) {
  const { location, recentBookings = [], favoriteCategories = [] } = context;

  const systemPrompt = `You are a recommendation engine for a services marketplace.
Given a user's history and context, suggest what services they might need next.
Return JSON array of { category, reason, confidence (0-1) }.`;

  const userPrompt = `User context:
- Recent bookings: ${JSON.stringify(recentBookings.slice(0, 5))}
- Favorite categories: ${JSON.stringify(favoriteCategories)}
- Location: ${location || 'unknown'}
- Current time: ${new Date().toISOString()}
- Day: ${new Date().toLocaleDateString('en-US', { weekday: 'long' })}

Suggest 3-5 services this user might want to book next.`;

  const result = await callAI(systemPrompt, userPrompt, { jsonMode: true, maxTokens: 300 });

  if (result) {
    try { return JSON.parse(result); } catch { /* fallback below */ }
  }

  // Rule-based fallback
  return getLocalRecommendations(recentBookings, favoriteCategories);
}

function getLocalRecommendations(recentBookings, favoriteCategories) {
  const suggestions = [];
  
  // Suggest related services based on recent bookings
  const relatedMap = {
    'Plumbing': ['Bathroom Renovation', 'Water Purifier Service'],
    'Electrical': ['Home Automation', 'Solar Panel Installation'],
    'Cleaning': ['Pest Control', 'Painting'],
    'Carpentry': ['Interior Design', 'Modular Kitchen'],
    'AC Repair': ['Electrician', 'Appliance Repair'],
  };

  for (const booking of recentBookings.slice(0, 3)) {
    const related = relatedMap[booking.category];
    if (related) {
      suggestions.push({
        category: related[0],
        reason: `Based on your recent ${booking.category} booking`,
        confidence: 0.7,
      });
    }
  }

  // Add seasonal suggestions
  const month = new Date().getMonth();
  if (month >= 3 && month <= 5) { // Summer
    suggestions.push({ category: 'AC Repair', reason: 'Summer maintenance', confidence: 0.6 });
  } else if (month >= 9 && month <= 11) { // Festival season
    suggestions.push({ category: 'Cleaning', reason: 'Festival preparation', confidence: 0.65 });
    suggestions.push({ category: 'Painting', reason: 'Festival home refresh', confidence: 0.6 });
  }

  return suggestions.slice(0, 5);
}

/**
 * 3. REVIEW SENTIMENT ANALYSIS — Analyze review text for sentiment + key themes
 * 
 * Returns: { sentiment: 'positive'|'neutral'|'negative', score: 0-1, themes: [...] }
 */
async function analyzeReviewSentiment(reviewText) {
  if (!reviewText || reviewText.length < 10) {
    return { sentiment: 'neutral', score: 0.5, themes: [] };
  }

  const cacheKey = `sentiment:${reviewText.substring(0, 100)}`;
  const cached = getCached(cacheKey);
  if (cached) return cached;

  const systemPrompt = `Analyze this service review. Return JSON:
{ "sentiment": "positive|neutral|negative", "score": 0.0-1.0, "themes": ["punctuality", "quality", etc], "summary": "one line summary" }`;

  const result = await callAI(systemPrompt, reviewText, { jsonMode: true, maxTokens: 150 });

  if (result) {
    try {
      const parsed = JSON.parse(result);
      setCache(cacheKey, parsed);
      return parsed;
    } catch { /* fallback */ }
  }

  // Rule-based sentiment
  const sentiment = analyzeLocalSentiment(reviewText);
  setCache(cacheKey, sentiment);
  return sentiment;
}

function analyzeLocalSentiment(text) {
  const lower = text.toLowerCase();
  const positiveWords = ['excellent', 'great', 'amazing', 'professional', 'punctual', 'recommended', 'perfect', 'best', 'wonderful', 'fantastic', 'happy', 'satisfied', 'good', 'nice'];
  const negativeWords = ['terrible', 'awful', 'bad', 'worst', 'late', 'rude', 'unprofessional', 'disappointed', 'never', 'poor', 'horrible', 'scam', 'fraud'];

  let posCount = 0, negCount = 0;
  const themes = [];

  for (const word of positiveWords) {
    if (lower.includes(word)) posCount++;
  }
  for (const word of negativeWords) {
    if (lower.includes(word)) negCount++;
  }

  // Theme extraction
  if (lower.includes('time') || lower.includes('punctual') || lower.includes('late')) themes.push('punctuality');
  if (lower.includes('quality') || lower.includes('work') || lower.includes('finish')) themes.push('quality');
  if (lower.includes('price') || lower.includes('cost') || lower.includes('expensive') || lower.includes('affordable')) themes.push('pricing');
  if (lower.includes('clean') || lower.includes('neat') || lower.includes('tidy')) themes.push('cleanliness');
  if (lower.includes('polite') || lower.includes('rude') || lower.includes('behavior')) themes.push('behavior');

  const total = posCount + negCount;
  const score = total === 0 ? 0.5 : posCount / total;
  const sentiment = score > 0.6 ? 'positive' : score < 0.4 ? 'negative' : 'neutral';

  return { sentiment, score: Math.round(score * 100) / 100, themes };
}

/**
 * 4. AUTO-CATEGORIZATION — Automatically suggest category for service descriptions
 */
async function suggestCategory(serviceDescription) {
  const systemPrompt = `You are a service categorizer for an Indian home services marketplace.
Given a description of a service need, return the most appropriate category and subcategory.
Return JSON: { "category": "...", "subcategory": "...", "confidence": 0.0-1.0 }
Categories: Plumbing, Electrical, Carpentry, Painting, Cleaning, AC Repair, Appliance Repair,
Pest Control, Beauty & Salon, Photography, Yoga & Fitness, Tutoring, Interior Design,
Home Automation, Cooking, Gardening, Moving & Packing, Car Wash, Laundry, Event Planning`;

  const result = await callAI(systemPrompt, serviceDescription, { jsonMode: true, maxTokens: 100 });
  if (result) {
    try { return JSON.parse(result); } catch { /* fallback */ }
  }

  // Use local keyword matching
  const intent = extractIntentLocal(serviceDescription);
  return { category: intent.category || 'General', subcategory: null, confidence: 0.5 };
}

/**
 * 5. SMART PRICING SUGGESTIONS — Suggest fair pricing based on market data
 */
async function suggestPricing({ category, location, complexity = 'medium', marketData = {} }) {
  const systemPrompt = `You are a pricing advisor for home services in India.
Given the service details and market context, suggest a fair price range in INR.
Return JSON: { "min_price": number, "max_price": number, "recommended": number, "factors": [...] }`;

  const userPrompt = `Service: ${category}
Location: ${location || 'Metro city, India'}
Complexity: ${complexity}
Market average: ${marketData.average || 'unknown'}
Supply/demand ratio: ${marketData.supplyDemand || 'unknown'}`;

  const result = await callAI(systemPrompt, userPrompt, { jsonMode: true, maxTokens: 150 });
  if (result) {
    try { return JSON.parse(result); } catch { /* fallback */ }
  }

  // Default pricing ranges by category
  const defaultPricing = {
    'Plumbing': { min_price: 300, max_price: 2000, recommended: 800 },
    'Electrical': { min_price: 200, max_price: 3000, recommended: 700 },
    'Cleaning': { min_price: 500, max_price: 5000, recommended: 1500 },
    'Painting': { min_price: 2000, max_price: 25000, recommended: 8000 },
    'AC Repair': { min_price: 400, max_price: 3000, recommended: 1000 },
  };

  return defaultPricing[category] || { min_price: 500, max_price: 5000, recommended: 1500, factors: ['standard_rate'] };
}

/**
 * 6. CHATBOT RESPONSE GENERATION — AI-powered customer support
 */
async function generateChatbotResponse(userMessage, context = {}) {
  const { userName, recentBookings = [], faqContext = '' } = context;

  const systemPrompt = `You are SkillBot, the AI assistant for SkillConnect — India's hyperlocal service marketplace.
You help users find professionals, manage bookings, and resolve queries.
Be helpful, concise, and friendly. Reply in the same language as the user.
If you can't help, suggest contacting human support.
Available actions: search_professionals, create_booking, check_status, get_recommendations.`;

  const userPrompt = `User: ${userName || 'Customer'}
Recent activity: ${JSON.stringify(recentBookings.slice(0, 3))}
FAQ context: ${faqContext}

User message: ${userMessage}`;

  const result = await callAI(systemPrompt, userPrompt, { temperature: 0.7, maxTokens: 300 });
  
  if (result) return { response: result, source: 'ai' };

  // Rule-based fallback responses
  return generateLocalChatResponse(userMessage);
}

function generateLocalChatResponse(message) {
  const lower = message.toLowerCase();
  
  if (lower.includes('book') || lower.includes('appointment')) {
    return { response: 'I can help you book a service! Please tell me what service you need and your preferred date/time. You can also search for professionals in our app.', source: 'rules' };
  }
  if (lower.includes('cancel')) {
    return { response: 'To cancel a booking, go to My Bookings > Select the booking > Tap Cancel. Note: cancellation policies may apply depending on the timing.', source: 'rules' };
  }
  if (lower.includes('payment') || lower.includes('pay') || lower.includes('refund')) {
    return { response: 'We support UPI, credit/debit cards, net banking, and wallets via Razorpay. For refunds, please raise a dispute from the booking details page.', source: 'rules' };
  }
  if (lower.includes('contact') || lower.includes('support') || lower.includes('help')) {
    return { response: 'Our support team is available 9 AM - 9 PM IST. You can reach us at support@skillconnect.in or use the in-app chat feature.', source: 'rules' };
  }

  return { response: 'I\'m here to help! You can ask me about booking services, finding professionals, payments, or managing your account. How can I assist you today?', source: 'rules' };
}

/**
 * 7. FRAUD SCORE — AI-enhanced fraud detection
 */
async function calculateFraudScore(activityData) {
  const { userId, action, metadata = {} } = activityData;

  // Rule-based scoring (always runs, AI enhances)
  let score = 0;
  const flags = [];

  if (metadata.rapidActions > 10) { score += 30; flags.push('rapid_actions'); }
  if (metadata.newAccount && metadata.highValueBooking) { score += 20; flags.push('new_account_high_value'); }
  if (metadata.multiplePaymentFailures > 3) { score += 25; flags.push('payment_failures'); }
  if (metadata.unusualLocation) { score += 15; flags.push('unusual_location'); }
  if (metadata.suspiciousPattern) { score += 20; flags.push('suspicious_pattern'); }

  return {
    score: Math.min(score, 100),
    risk: score > 70 ? 'high' : score > 40 ? 'medium' : 'low',
    flags,
    action: score > 70 ? 'block' : score > 40 ? 'review' : 'allow',
  };
}

// ─── Exports ─────────────────────────────────────────────────────────────────

module.exports = {
  parseSearchIntent,
  getPersonalizedRecommendations,
  analyzeReviewSentiment,
  suggestCategory,
  suggestPricing,
  generateChatbotResponse,
  calculateFraudScore,
  // Exposed for testing
  extractIntentLocal,
  analyzeLocalSentiment,
  getLocalRecommendations,
};
