/**
 * Face Match Service — HyperVerge / AWS Rekognition integration
 *
 * Compares a selfie against a government ID document photo and
 * returns a confidence score (0–100).  The platform requires >= 85.
 *
 * Providers (set FACE_MATCH_PROVIDER):
 *   'hyperverge'   — HyperVerge India KYC API (preferred for Indian IDs)
 *   'rekognition'  — AWS Rekognition CompareFaces
 *   'mock'         — Returns a configurable score for development/testing
 *
 * Required env vars for HyperVerge:
 *   HYPERVERGE_APP_ID, HYPERVERGE_APP_KEY
 *
 * Required env vars for Rekognition:
 *   AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION
 */

const logger = require('../config/logger');

const PROVIDER = process.env.FACE_MATCH_PROVIDER || 'mock';
const CONFIDENCE_THRESHOLD = 85; // PRD requirement: >= 85%

// ────────────────────────────────────────────────────────────
// HyperVerge provider
// ────────────────────────────────────────────────────────────
async function matchViaHyperVerge(selfieBuffer, idPhotoBuffer) {
  const appId = process.env.HYPERVERGE_APP_ID;
  const appKey = process.env.HYPERVERGE_APP_KEY;

  if (!appId || !appKey) {
    throw new Error('HyperVerge credentials not configured (HYPERVERGE_APP_ID, HYPERVERGE_APP_KEY)');
  }

  const FormData = (await import('form-data')).default;
  const form = new FormData();
  form.append('selfie', selfieBuffer, { filename: 'selfie.jpg', contentType: 'image/jpeg' });
  form.append('id_photo', idPhotoBuffer, { filename: 'id_photo.jpg', contentType: 'image/jpeg' });

  const response = await fetch('https://ind-docs.hyperverge.co/v2.0/matchFace', {
    method: 'POST',
    headers: {
      appId,
      appKey,
      ...form.getHeaders(),
    },
    body: form,
  });

  if (!response.ok) {
    const err = await response.text();
    throw new Error(`HyperVerge API error: ${response.status} — ${err}`);
  }

  const data = await response.json();
  // HyperVerge returns: { result: { details: [{ confidence: '0.92' }] } }
  const confidence = parseFloat(data?.result?.details?.[0]?.confidence || '0');
  return { score: Math.round(confidence * 100), provider: 'hyperverge' };
}

// ────────────────────────────────────────────────────────────
// AWS Rekognition provider
// ────────────────────────────────────────────────────────────
async function matchViaRekognition(selfieBuffer, idPhotoBuffer) {
  let RekognitionClient, CompareFacesCommand;
  try {
    const sdk = require('@aws-sdk/client-rekognition');
    RekognitionClient = sdk.RekognitionClient;
    CompareFacesCommand = sdk.CompareFacesCommand;
  } catch {
    throw new Error('AWS Rekognition SDK not installed. Run: npm install @aws-sdk/client-rekognition');
  }

  const client = new RekognitionClient({
    region: process.env.AWS_REGION || 'ap-south-1',
    credentials: {
      accessKeyId: process.env.AWS_ACCESS_KEY_ID,
      secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
    },
  });

  const command = new CompareFacesCommand({
    SourceImage: { Bytes: selfieBuffer },
    TargetImage: { Bytes: idPhotoBuffer },
    SimilarityThreshold: 0,
  });

  const result = await client.send(command);
  const topMatch = result.FaceMatches?.[0];
  const score = topMatch ? Math.round(topMatch.Similarity) : 0;
  return { score, provider: 'rekognition' };
}

// ────────────────────────────────────────────────────────────
// Mock provider (development / CI)
// ────────────────────────────────────────────────────────────
async function matchViaMock() {
  const score = parseInt(process.env.FACE_MATCH_MOCK_SCORE || '92', 10);
  logger.warn({ score }, 'Face match: using mock provider — never use in production');
  return { score, provider: 'mock' };
}

// ────────────────────────────────────────────────────────────
// Public API
// ────────────────────────────────────────────────────────────

/**
 * Compare a selfie image against an ID document photo.
 *
 * @param {Buffer} selfieBuffer  - Raw image bytes of the live selfie
 * @param {Buffer} idPhotoBuffer - Raw image bytes of the ID document photo
 * @returns {Promise<{ score: number, passed: boolean, provider: string }>}
 *   score   — 0-100 confidence (100 = identical)
 *   passed  — true if score >= CONFIDENCE_THRESHOLD (85)
 *   provider — which backend was used
 */
async function compareFaces(selfieBuffer, idPhotoBuffer) {
  let result;

  try {
    if (PROVIDER === 'hyperverge') {
      result = await matchViaHyperVerge(selfieBuffer, idPhotoBuffer);
    } else if (PROVIDER === 'rekognition') {
      result = await matchViaRekognition(selfieBuffer, idPhotoBuffer);
    } else {
      result = await matchViaMock();
    }
  } catch (err) {
    logger.error({ err, provider: PROVIDER }, 'Face match API error');
    // Fail closed — treat API errors as failed match
    return { score: 0, passed: false, provider: PROVIDER, error: err.message };
  }

  const passed = result.score >= CONFIDENCE_THRESHOLD;
  logger.info({ score: result.score, passed, threshold: CONFIDENCE_THRESHOLD, provider: result.provider }, 'Face match completed');

  return { ...result, passed, threshold: CONFIDENCE_THRESHOLD };
}

module.exports = { compareFaces, CONFIDENCE_THRESHOLD };
