/**
 * DOMPurify sanitization utility for user-generated content.
 * 
 * Use this to sanitize any HTML/text content received from the API
 * before rendering it with dangerouslySetInnerHTML or in contexts
 * where XSS is a concern.
 * 
 * Usage:
 *   import { sanitize, sanitizeRichText } from '../utils/sanitize';
 *   
 *   // Strip all HTML (for plain text display)
 *   const cleanText = sanitize(userInput);
 *   
 *   // Allow basic formatting (for rich text like descriptions)
 *   const cleanHtml = sanitizeRichText(userDescription);
 *   <div dangerouslySetInnerHTML={{ __html: cleanHtml }} />
 */

import DOMPurify from 'dompurify';

/**
 * Strip ALL HTML tags — use for plain text contexts.
 * @param {string} dirty - Untrusted input
 * @returns {string} Clean text with no HTML
 */
export function sanitize(dirty) {
  if (!dirty || typeof dirty !== 'string') return '';
  return DOMPurify.sanitize(dirty, { ALLOWED_TAGS: [] });
}

/**
 * Allow basic rich text formatting tags.
 * Use when rendering descriptions, bios, messages with dangerouslySetInnerHTML.
 * @param {string} dirty - Untrusted HTML input
 * @returns {string} Sanitized HTML with only safe tags
 */
export function sanitizeRichText(dirty) {
  if (!dirty || typeof dirty !== 'string') return '';
  return DOMPurify.sanitize(dirty, {
    ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'a', 'p', 'br', 'ul', 'ol', 'li', 'span'],
    ALLOWED_ATTR: ['href', 'title', 'target', 'rel', 'class'],
    ALLOW_DATA_ATTR: false,
    ADD_ATTR: ['target'],
    FORBID_TAGS: ['script', 'style', 'iframe', 'object', 'embed', 'form', 'input'],
    FORBID_ATTR: ['onerror', 'onload', 'onclick', 'onmouseover'],
  });
}

/**
 * Sanitize a URL to prevent javascript: protocol attacks.
 * @param {string} url - Untrusted URL
 * @returns {string} Safe URL or empty string
 */
export function sanitizeUrl(url) {
  if (!url || typeof url !== 'string') return '';
  const trimmed = url.trim();
  // Block javascript:, data:, vbscript: protocols
  if (/^(javascript|data|vbscript):/i.test(trimmed)) return '';
  return trimmed;
}

export default { sanitize, sanitizeRichText, sanitizeUrl };
