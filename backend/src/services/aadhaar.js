const crypto = require('crypto');
const logger = require('../config/logger');
const { withRetry } = require('../utils/retry');

const PROVIDER = process.env.AADHAAR_OTP_PROVIDER || 'mock';
const HYPERVERGE_APP_ID = process.env.HYPERVERGE_APP_ID || '';
const HYPERVERGE_APP_KEY = process.env.HYPERVERGE_APP_KEY || '';
const BASE_URL = process.env.AADHAAR_OTP_BASE_URL || 'https://ind-docs.hyperverge.co/v2.0';
const MOCK_OTP = process.env.AADHAAR_MOCK_OTP || '123456';

const sha1 = (value) => crypto.createHash('sha1').update(String(value)).digest('hex');

function getAttr(xml, tag, attr) {
  const pattern = new RegExp(`<${tag}\b[^>]*\s${attr}="([^"]*)"`, 'i');
  return xml.match(pattern)?.[1] || null;
}

function getTag(xml, tag) {
  const pattern = new RegExp(`<${tag}>([\s\S]*?)<\/${tag}>`, 'i');
  return xml.match(pattern)?.[1]?.trim() || null;
}

function normalizeEkycPayload(payload) {
  const result = payload?.result || payload?.data || payload || {};
  const xml = result.ekyc_xml || result.ekycXml || result.xml || payload?.ekyc_xml || payload?.ekycXml || payload?.xml;

  if (typeof xml === 'string' && xml.includes('<')) {
    const line1 = [getAttr(xml, 'Poa', 'house'), getAttr(xml, 'Poa', 'street')].filter(Boolean).join(', ');
    const line2 = [getAttr(xml, 'Poa', 'loc'), getAttr(xml, 'Poa', 'vtc')].filter(Boolean).join(', ');
    return {
      name: getAttr(xml, 'Poi', 'name') || getTag(xml, 'Name') || null,
      dob: getAttr(xml, 'Poi', 'dob') || getTag(xml, 'DOB') || null,
      gender: getAttr(xml, 'Poi', 'gender') || getTag(xml, 'Gender') || null,
      photo: getTag(xml, 'Pht') || null,
      address: [line1, line2, getAttr(xml, 'Poa', 'state'), getAttr(xml, 'Poa', 'pc')].filter(Boolean).join(', ') || null,
      postal_code: getAttr(xml, 'Poa', 'pc') || null,
      state: getAttr(xml, 'Poa', 'state') || null,
      raw_xml: xml,
    };
  }

  const address = result.address || result.full_address || result.formattedAddress || payload?.address || null;
  return {
    name: result.name || result.full_name || payload?.name || null,
    dob: result.dob || result.date_of_birth || payload?.dob || null,
    gender: result.gender || payload?.gender || null,
    photo: result.photo || result.photo_base64 || payload?.photo || null,
    address: typeof address === 'string' ? address : address ? JSON.stringify(address) : null,
    postal_code: result.postal_code || result.pincode || payload?.postal_code || null,
    state: result.state || payload?.state || null,
    raw: typeof payload === 'object' ? payload : null,
  };
}

async function hypervergeRequest(endpoint, body) {
  return withRetry(async () => {
    const response = await fetch(`${BASE_URL}${endpoint}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        appId: HYPERVERGE_APP_ID,
        appKey: HYPERVERGE_APP_KEY,
      },
      body: JSON.stringify(body),
    });

    const text = await response.text();
    let data = {};
    try {
      data = text ? JSON.parse(text) : {};
    } catch {
      data = { raw: text };
    }

    if (!response.ok) {
      const err = new Error(data?.message || data?.error?.message || `Aadhaar provider error (${response.status})`);
      err.statusCode = response.status;
      err.response = data;
      throw err;
    }

    return data;
  }, {
    maxRetries: 2,
    baseDelay: 800,
    serviceName: 'aadhaar-otp',
    shouldRetry: (err) => !err.statusCode || err.statusCode >= 500,
  });
}

async function initiateMock(aadhaarNumber) {
  const suffix = String(aadhaarNumber).slice(-4);
  return {
    provider: 'mock',
    transactionId: `aadhaar_txn_${Date.now()}`,
    referenceId: `aadhaar_ref_${suffix}_${Date.now()}`,
  };
}

async function verifyMock({ transactionId, otp, aadhaarNumber }) {
  if (String(otp) !== String(MOCK_OTP)) {
    return {
      verified: false,
      provider: 'mock',
      transactionId,
      referenceId: `aadhaar_ref_${sha1(transactionId).slice(0, 12)}`,
    };
  }

  return {
    verified: true,
    provider: 'mock',
    transactionId,
    referenceId: `aadhaar_ref_${sha1(`${transactionId}:${aadhaarNumber}`).slice(0, 12)}`,
    ekycData: {
      name: process.env.AADHAAR_MOCK_NAME || 'Test User',
      dob: process.env.AADHAAR_MOCK_DOB || '1995-01-01',
      gender: process.env.AADHAAR_MOCK_GENDER || 'M',
      address: process.env.AADHAAR_MOCK_ADDRESS || 'MG Road, Bengaluru, Karnataka 560001',
      postal_code: '560001',
      state: 'Karnataka',
      photo: null,
    },
  };
}

async function initiateOtp(aadhaarNumber) {
  if (PROVIDER === 'hyperverge' && HYPERVERGE_APP_ID && HYPERVERGE_APP_KEY) {
    const data = await hypervergeRequest('/aadhaar/otp', {
      aadhaarNumber,
      consent: 'Y',
    });

    const transactionId = data?.transactionId || data?.transaction_id || data?.result?.transactionId || data?.result?.transaction_id;
    const referenceId = data?.referenceId || data?.reference_id || data?.result?.referenceId || data?.result?.reference_id || transactionId;

    if (!transactionId) {
      throw new Error('Aadhaar OTP provider did not return a transactionId');
    }

    return {
      provider: 'hyperverge',
      transactionId,
      referenceId,
    };
  }

  if (PROVIDER === 'hyperverge') {
    logger.warn('Aadhaar OTP provider set to hyperverge but credentials are missing; falling back to mock mode');
  }

  return initiateMock(aadhaarNumber);
}

async function verifyOtp({ transactionId, otp, aadhaarNumber }) {
  if (PROVIDER === 'hyperverge' && HYPERVERGE_APP_ID && HYPERVERGE_APP_KEY) {
    const data = await hypervergeRequest('/aadhaar/otp/verify', {
      transactionId,
      otp,
    });

    const verified = Boolean(
      data?.verified ??
      data?.success ??
      data?.result?.verified ??
      data?.result?.success ??
      data?.result?.status === 'verified'
    );

    return {
      verified,
      provider: 'hyperverge',
      transactionId,
      referenceId: data?.referenceId || data?.reference_id || data?.result?.referenceId || data?.result?.reference_id || transactionId,
      ekycData: normalizeEkycPayload(data),
      raw: data,
    };
  }

  return verifyMock({ transactionId, otp, aadhaarNumber });
}

module.exports = {
  initiateOtp,
  verifyOtp,
};
