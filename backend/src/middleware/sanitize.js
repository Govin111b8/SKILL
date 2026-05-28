/**
 * XSS Sanitization Middleware
 * Uses sanitize-html library for robust HTML sanitization.
 * Strips all HTML tags and dangerous content from string inputs in req.body.
 */

const sanitizeHtml = require('sanitize-html');

// Strict policy: strip ALL HTML tags and attributes
const STRICT_OPTIONS = {
  allowedTags: [],
  allowedAttributes: {},
  disallowedTagsMode: 'recursiveEscape',
};

// Permissive policy for fields that allow basic formatting (e.g., descriptions, bios)
const RICH_TEXT_OPTIONS = {
  allowedTags: ['b', 'i', 'em', 'strong', 'a', 'p', 'br', 'ul', 'ol', 'li'],
  allowedAttributes: {
    a: ['href', 'title', 'target', 'rel'],
  },
  allowedSchemes: ['http', 'https', 'mailto'],
  transformTags: {
    a: sanitizeHtml.simpleTransform('a', { rel: 'noopener noreferrer nofollow', target: '_blank' }),
  },
};

// Fields that are allowed basic rich-text formatting
const RICH_TEXT_FIELDS = new Set([
  'description', 'bio', 'about', 'content', 'body', 'message',
  'professional_description', 'service_description',
]);

function sanitizeValue(value, fieldName) {
  if (typeof value === 'string') {
    const options = RICH_TEXT_FIELDS.has(fieldName) ? RICH_TEXT_OPTIONS : STRICT_OPTIONS;
    return sanitizeHtml(value, options);
  }
  if (Array.isArray(value)) {
    return value.map((item) => sanitizeValue(item, fieldName));
  }
  if (value && typeof value === 'object') {
    return sanitizeObject(value);
  }
  return value;
}

function sanitizeObject(obj) {
  const sanitized = {};
  for (const [key, value] of Object.entries(obj)) {
    sanitized[key] = sanitizeValue(value, key);
  }
  return sanitized;
}

/**
 * Middleware that sanitizes all string fields in req.body
 * Uses sanitize-html for robust XSS prevention
 */
function sanitize(req, res, next) {
  if (req.body && typeof req.body === 'object') {
    req.body = sanitizeObject(req.body);
  }
  next();
}

module.exports = sanitize;
