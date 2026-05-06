/**
 * GST Invoice Generator — SkillConnect
 *
 * Generates GST-compliant PDF invoices for subscription payments.
 *
 * Tax rules (India):
 *   B2C (no GSTIN): 18% GST
 *     - Same state as platform:  CGST 9% + SGST 9%
 *     - Different state:         IGST 18%
 *   B2B (with GSTIN): IGST 18%
 *
 * Platform GSTIN and state must be set in env:
 *   PLATFORM_GSTIN       e.g. 27AAAAA0000A1Z5
 *   PLATFORM_STATE_CODE  e.g. 27 (Maharashtra)
 *   PLATFORM_LEGAL_NAME  e.g. SkillConnect Technologies Pvt Ltd
 */

const path = require('path');
const fs = require('fs');
const logger = require('../config/logger');
const storage = require('./storage');

const GST_RATE = 0.18;
const CGST_RATE = 0.09;
const SGST_RATE = 0.09;
const IGST_RATE = 0.18;

const PLATFORM_GSTIN = process.env.PLATFORM_GSTIN || '';
const PLATFORM_STATE_CODE = process.env.PLATFORM_STATE_CODE || '27'; // Maharashtra
const PLATFORM_LEGAL_NAME = process.env.PLATFORM_LEGAL_NAME || 'SkillConnect Technologies';
const PLATFORM_ADDRESS = process.env.PLATFORM_ADDRESS || 'Mumbai, Maharashtra, India';

/**
 * Generate a sequential invoice number.
 * Format: SC-YYYY-XXXXXXXX
 */
function generateInvoiceNumber() {
  const year = new Date().getFullYear();
  const seq = Date.now().toString(36).toUpperCase().slice(-8);
  return `SC-${year}-${seq}`;
}

/**
 * Calculate GST breakdown for a given base amount.
 *
 * @param {number} baseAmount - Pre-tax amount in INR
 * @param {string|null} customerGstin - Customer GSTIN (null for B2C)
 * @param {string} customerStateCode  - 2-digit state code of customer
 * @returns {{ cgst, sgst, igst, total, invoiceType }}
 */
function calculateGST(baseAmount, customerGstin, customerStateCode) {
  const isSameState = customerStateCode === PLATFORM_STATE_CODE;
  const isB2B = !!(customerGstin && customerGstin.length === 15);

  let cgst = 0;
  let sgst = 0;
  let igst = 0;

  if (isB2B || !isSameState) {
    // Inter-state or B2B: IGST
    igst = Math.round(baseAmount * IGST_RATE * 100) / 100;
  } else {
    // Intra-state B2C: split CGST + SGST
    cgst = Math.round(baseAmount * CGST_RATE * 100) / 100;
    sgst = Math.round(baseAmount * SGST_RATE * 100) / 100;
  }

  const total = Math.round((baseAmount + cgst + sgst + igst) * 100) / 100;

  return {
    cgst,
    sgst,
    igst,
    total,
    invoiceType: isB2B ? 'b2b' : 'b2c',
  };
}

/**
 * Generate a GST invoice PDF using pdfkit.
 *
 * @param {object} opts
 * @param {string} opts.invoiceNumber
 * @param {Date}   opts.date
 * @param {string} opts.customerName
 * @param {string} opts.customerEmail
 * @param {string} opts.customerGstin    - null for B2C
 * @param {string} opts.customerState
 * @param {string} opts.customerStateCode
 * @param {string} opts.plan             - 'premium' | 'featured'
 * @param {number} opts.baseAmount
 * @param {number} opts.cgst
 * @param {number} opts.sgst
 * @param {number} opts.igst
 * @param {number} opts.total
 * @param {string} opts.invoiceType      - 'b2b' | 'b2c'
 * @returns {Promise<Buffer>}            - PDF bytes
 */
async function generatePDF(opts) {
  let PDFDocument;
  try {
    PDFDocument = require('pdfkit');
  } catch {
    logger.error('pdfkit not installed. Run: npm install pdfkit');
    throw new Error('PDF generation unavailable');
  }

  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ size: 'A4', margin: 50 });
    const chunks = [];

    doc.on('data', (chunk) => chunks.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);

    const INR = (n) => `₹${Number(n).toFixed(2)}`;
    const { invoiceNumber, date, customerName, customerEmail, customerGstin,
            customerState, plan, baseAmount, cgst, sgst, igst, total, invoiceType } = opts;

    // ── Header ──────────────────────────────────────────────────────
    doc.fontSize(20).font('Helvetica-Bold').text('TAX INVOICE', { align: 'center' });
    doc.moveDown(0.5);
    doc.fontSize(10).font('Helvetica').text('(As per GST Act, 2017)', { align: 'center' });
    doc.moveDown(1);

    // ── Seller info ─────────────────────────────────────────────────
    doc.fontSize(12).font('Helvetica-Bold').text(PLATFORM_LEGAL_NAME);
    doc.fontSize(9).font('Helvetica')
      .text(PLATFORM_ADDRESS)
      .text(`GSTIN: ${PLATFORM_GSTIN || 'Applied For'}`)
      .text(`SAC Code: 998314 (Software/Platform Subscription)`);
    doc.moveDown(1);

    // ── Invoice details ──────────────────────────────────────────────
    doc.font('Helvetica-Bold').fontSize(10).text('Invoice Details', { underline: true });
    doc.font('Helvetica').fontSize(9)
      .text(`Invoice No  : ${invoiceNumber}`)
      .text(`Invoice Date: ${date.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })}`)
      .text(`Invoice Type: ${invoiceType.toUpperCase()}`);
    doc.moveDown(1);

    // ── Bill To ──────────────────────────────────────────────────────
    doc.font('Helvetica-Bold').fontSize(10).text('Bill To', { underline: true });
    doc.font('Helvetica').fontSize(9)
      .text(customerName)
      .text(customerEmail)
      .text(`State: ${customerState || 'India'}`);
    if (customerGstin) doc.text(`GSTIN: ${customerGstin}`);
    doc.moveDown(1);

    // ── Line items table ─────────────────────────────────────────────
    const tableTop = doc.y;
    const cols = { desc: 50, unit: 320, qty: 370, rate: 420, amount: 480 };

    doc.font('Helvetica-Bold').fontSize(9);
    doc.text('Description', cols.desc, tableTop);
    doc.text('Unit', cols.unit, tableTop);
    doc.text('Qty', cols.qty, tableTop);
    doc.text('Rate', cols.rate, tableTop);
    doc.text('Amount', cols.amount, tableTop);
    doc.moveTo(50, tableTop + 15).lineTo(560, tableTop + 15).stroke();

    doc.font('Helvetica').fontSize(9);
    const itemY = tableTop + 20;
    const planLabel = `SkillConnect ${plan.charAt(0).toUpperCase() + plan.slice(1)} Subscription (1 month)`;
    doc.text(planLabel, cols.desc, itemY, { width: 265 });
    doc.text('Month', cols.unit, itemY);
    doc.text('1', cols.qty, itemY);
    doc.text(INR(baseAmount), cols.rate, itemY);
    doc.text(INR(baseAmount), cols.amount, itemY);
    doc.moveDown(3);

    // ── Tax breakdown ────────────────────────────────────────────────
    doc.moveTo(50, doc.y).lineTo(560, doc.y).stroke();
    doc.moveDown(0.5);

    const taxY = doc.y;
    doc.font('Helvetica').fontSize(9);
    doc.text(`Taxable Amount`, 350, taxY, { width: 120, align: 'right' });
    doc.text(INR(baseAmount), cols.amount, taxY);

    if (cgst > 0) {
      doc.moveDown(0.3);
      doc.text(`CGST @ ${(CGST_RATE * 100)}%`, 350, doc.y, { width: 120, align: 'right' });
      doc.text(INR(cgst), cols.amount, doc.y);
    }
    if (sgst > 0) {
      doc.moveDown(0.3);
      doc.text(`SGST @ ${(SGST_RATE * 100)}%`, 350, doc.y, { width: 120, align: 'right' });
      doc.text(INR(sgst), cols.amount, doc.y);
    }
    if (igst > 0) {
      doc.moveDown(0.3);
      doc.text(`IGST @ ${(IGST_RATE * 100)}%`, 350, doc.y, { width: 120, align: 'right' });
      doc.text(INR(igst), cols.amount, doc.y);
    }

    doc.moveDown(0.5);
    doc.moveTo(50, doc.y).lineTo(560, doc.y).stroke();
    doc.moveDown(0.3);
    doc.font('Helvetica-Bold').fontSize(10);
    doc.text('Total Amount', 350, doc.y, { width: 120, align: 'right' });
    doc.text(INR(total), cols.amount, doc.y);

    // ── Footer ───────────────────────────────────────────────────────
    doc.moveDown(2);
    doc.font('Helvetica').fontSize(8)
      .fillColor('#666666')
      .text('This is a computer-generated invoice and does not require a physical signature.', { align: 'center' })
      .text('For support: support@skillconnect.in', { align: 'center' });

    doc.end();
  });
}

/**
 * Create and store a GST invoice for a subscription payment.
 *
 * @param {object} opts
 * @returns {Promise<{ invoiceNumber, pdfUrl, cgst, sgst, igst, total, invoiceType }>}
 */
async function createInvoice({ professionalId, subscriptionId, plan, baseAmount, customerName, customerEmail, customerGstin, customerState, customerStateCode }) {
  const invoiceNumber = generateInvoiceNumber();
  const date = new Date();
  const { cgst, sgst, igst, total, invoiceType } = calculateGST(baseAmount, customerGstin, customerStateCode || '');

  const pdfBuffer = await generatePDF({
    invoiceNumber,
    date,
    customerName,
    customerEmail,
    customerGstin,
    customerState,
    customerStateCode,
    plan,
    baseAmount,
    cgst,
    sgst,
    igst,
    total,
    invoiceType,
  });

  // Upload to storage (S3 or local)
  const { url: pdfUrl } = await storage.uploadFile(
    pdfBuffer,
    `invoice-${invoiceNumber}.pdf`,
    'application/pdf',
    'invoices'
  );

  logger.info({ invoiceNumber, professionalId, total, invoiceType }, 'GST invoice generated');

  return { invoiceNumber, pdfUrl, cgst, sgst, igst, total, invoiceType };
}

module.exports = { createInvoice, calculateGST, generateInvoiceNumber };
