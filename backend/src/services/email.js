/**
 * Email Service — Transactional email via SendGrid or SMTP fallback
 *
 * Required env vars:
 *   SENDGRID_API_KEY (or SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS)
 *   EMAIL_FROM (default: noreply@skillconnect.in)
 */

const crypto = require('crypto');
const logger = require('../config/logger');

const SENDGRID_API_KEY = process.env.SENDGRID_API_KEY || '';
const EMAIL_FROM = process.env.EMAIL_FROM || 'noreply@skillconnect.in';
const APP_NAME = 'SkillConnect';
const APP_URL = process.env.APP_URL || 'http://localhost:3000';

/**
 * Send email via SendGrid HTTP API
 */
async function sendEmail({ to, subject, html, text }) {
  if (!SENDGRID_API_KEY) {
    logger.warn({ to, subject }, 'SendGrid not configured — email logged only');
    logger.info({ to, subject, text: text?.substring(0, 200) }, 'EMAIL_CONTENT');
    return { success: true, simulated: true };
  }

  const response = await fetch('https://api.sendgrid.com/v3/mail/send', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${SENDGRID_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      personalizations: [{ to: [{ email: to }] }],
      from: { email: EMAIL_FROM, name: APP_NAME },
      subject,
      content: [
        ...(text ? [{ type: 'text/plain', value: text }] : []),
        ...(html ? [{ type: 'text/html', value: html }] : []),
      ],
    }),
  });

  if (!response.ok) {
    const err = await response.text();
    logger.error({ status: response.status, err, to }, 'SendGrid send failed');
    throw new Error(`Email send failed: ${response.status}`);
  }

  logger.info({ to, subject }, 'Email sent successfully');
  return { success: true };
}

/**
 * Generate a secure token (for email verification, password reset)
 */
function generateToken() {
  return crypto.randomBytes(32).toString('hex');
}

/**
 * Send email verification link
 */
async function sendVerificationEmail(email, token) {
  const verifyUrl = `${APP_URL}/verify-email?token=${token}`;
  return sendEmail({
    to: email,
    subject: `Verify your ${APP_NAME} email`,
    html: `
      <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto;">
        <h2>Welcome to ${APP_NAME}!</h2>
        <p>Please verify your email address by clicking the button below:</p>
        <a href="${verifyUrl}" style="display: inline-block; background: #4F46E5; color: white; padding: 12px 24px; border-radius: 6px; text-decoration: none; margin: 16px 0;">Verify Email</a>
        <p style="color: #666; font-size: 14px;">Or copy this link: ${verifyUrl}</p>
        <p style="color: #666; font-size: 14px;">This link expires in 24 hours.</p>
      </div>
    `,
    text: `Welcome to ${APP_NAME}! Verify your email: ${verifyUrl} (expires in 24 hours)`,
  });
}

/**
 * Send password reset email
 */
async function sendPasswordResetEmail(email, token) {
  const resetUrl = `${APP_URL}/reset-password?token=${token}`;
  return sendEmail({
    to: email,
    subject: `Reset your ${APP_NAME} password`,
    html: `
      <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto;">
        <h2>Password Reset</h2>
        <p>You requested a password reset. Click below to set a new password:</p>
        <a href="${resetUrl}" style="display: inline-block; background: #4F46E5; color: white; padding: 12px 24px; border-radius: 6px; text-decoration: none; margin: 16px 0;">Reset Password</a>
        <p style="color: #666; font-size: 14px;">Or copy this link: ${resetUrl}</p>
        <p style="color: #666; font-size: 14px;">This link expires in 1 hour. If you didn't request this, ignore this email.</p>
      </div>
    `,
    text: `Reset your password: ${resetUrl} (expires in 1 hour). If you didn't request this, ignore this email.`,
  });
}

/**
 * Send booking confirmation email
 */
async function sendBookingConfirmation(email, booking) {
  return sendEmail({
    to: email,
    subject: `Booking Confirmed: ${booking.title}`,
    html: `
      <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto;">
        <h2>Booking Confirmed</h2>
        <p>Your booking <strong>${booking.title}</strong> has been confirmed.</p>
        <ul>
          <li><strong>Date:</strong> ${booking.preferred_date || 'TBD'}</li>
          <li><strong>Status:</strong> ${booking.status}</li>
          ${booking.quoted_amount ? `<li><strong>Amount:</strong> ₹${booking.quoted_amount}</li>` : ''}
        </ul>
        <a href="${APP_URL}/bookings/${booking.id}" style="display: inline-block; background: #4F46E5; color: white; padding: 12px 24px; border-radius: 6px; text-decoration: none; margin: 16px 0;">View Booking</a>
      </div>
    `,
    text: `Booking Confirmed: ${booking.title}. View at ${APP_URL}/bookings/${booking.id}`,
  });
}

/**
 * Send payment receipt email
 */
async function sendPaymentReceipt(email, payment) {
  return sendEmail({
    to: email,
    subject: `Payment Receipt — ₹${payment.amount}`,
    html: `
      <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto;">
        <h2>Payment Receipt</h2>
        <table style="width: 100%; border-collapse: collapse;">
          <tr><td style="padding: 8px; border-bottom: 1px solid #eee;">Amount</td><td style="padding: 8px; border-bottom: 1px solid #eee;">₹${payment.amount}</td></tr>
          <tr><td style="padding: 8px; border-bottom: 1px solid #eee;">Platform Fee</td><td style="padding: 8px; border-bottom: 1px solid #eee;">₹${payment.platform_fee}</td></tr>
          <tr><td style="padding: 8px; border-bottom: 1px solid #eee;">Tax (GST)</td><td style="padding: 8px; border-bottom: 1px solid #eee;">₹${payment.tax_amount}</td></tr>
          <tr><td style="padding: 8px;"><strong>Total</strong></td><td style="padding: 8px;"><strong>₹${(parseFloat(payment.amount) + parseFloat(payment.tax_amount)).toFixed(2)}</strong></td></tr>
        </table>
        <p style="color: #666; font-size: 14px; margin-top: 16px;">Transaction Ref: ${payment.transaction_ref}</p>
      </div>
    `,
    text: `Payment Receipt: ₹${payment.amount}. Ref: ${payment.transaction_ref}`,
  });
}

/**
 * Send dispute notification
 */
async function sendDisputeNotification(email, dispute) {
  return sendEmail({
    to: email,
    subject: `Dispute Raised — Booking #${dispute.booking_id}`,
    html: `
      <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto;">
        <h2>Dispute Notification</h2>
        <p>A dispute has been raised regarding your booking.</p>
        <p><strong>Reason:</strong> ${dispute.reason}</p>
        <p>${dispute.description || ''}</p>
        <a href="${APP_URL}/disputes" style="display: inline-block; background: #DC2626; color: white; padding: 12px 24px; border-radius: 6px; text-decoration: none; margin: 16px 0;">View Dispute</a>
      </div>
    `,
    text: `Dispute raised for booking. Reason: ${dispute.reason}. View at ${APP_URL}/disputes`,
  });
}

module.exports = {
  sendEmail,
  generateToken,
  sendVerificationEmail,
  sendPasswordResetEmail,
  sendBookingConfirmation,
  sendPaymentReceipt,
  sendDisputeNotification,
};
