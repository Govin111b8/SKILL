/**
 * Cloud Storage Service — AWS S3 / Cloudflare R2 compatible
 *
 * Required env vars:
 *   STORAGE_PROVIDER ('s3' | 'r2' | 'local')
 *   AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION, S3_BUCKET
 *   For R2: R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_BUCKET
 */

const crypto = require('crypto');
const path = require('path');
const fs = require('fs');
const logger = require('../config/logger');

const STORAGE_PROVIDER = process.env.STORAGE_PROVIDER || 'local';
const LOCAL_UPLOAD_DIR = path.join(__dirname, '../../uploads');

// Ensure local upload dir exists
if (!fs.existsSync(LOCAL_UPLOAD_DIR)) fs.mkdirSync(LOCAL_UPLOAD_DIR, { recursive: true });

/**
 * Generate a unique filename preserving extension
 */
function generateFilename(originalName) {
  const ext = path.extname(originalName).toLowerCase();
  return `${crypto.randomUUID()}${ext}`;
}

/**
 * Upload file to S3-compatible storage
 */
async function uploadToS3(buffer, key, contentType) {
  // Dynamic import to avoid crash when aws-sdk not installed
  let S3Client, PutObjectCommand;
  try {
    const sdk = require('@aws-sdk/client-s3');
    S3Client = sdk.S3Client;
    PutObjectCommand = sdk.PutObjectCommand;
  } catch {
    logger.error('AWS SDK not installed. Run: npm install @aws-sdk/client-s3');
    throw new Error('S3 storage not available — AWS SDK not installed');
  }

  const isR2 = STORAGE_PROVIDER === 'r2';
  const config = isR2
    ? {
        region: 'auto',
        endpoint: `https://${process.env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
        credentials: {
          accessKeyId: process.env.R2_ACCESS_KEY_ID,
          secretAccessKey: process.env.R2_SECRET_ACCESS_KEY,
        },
      }
    : {
        region: process.env.AWS_REGION || 'ap-south-1',
        credentials: {
          accessKeyId: process.env.AWS_ACCESS_KEY_ID,
          secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
        },
      };

  const bucket = isR2 ? process.env.R2_BUCKET : process.env.S3_BUCKET;
  const client = new S3Client(config);

  await client.send(new PutObjectCommand({
    Bucket: bucket,
    Key: key,
    Body: buffer,
    ContentType: contentType,
  }));

  // Return public URL
  if (isR2) {
    const publicUrl = process.env.R2_PUBLIC_URL || `https://${bucket}.r2.dev`;
    return `${publicUrl}/${key}`;
  }
  return `https://${bucket}.s3.${process.env.AWS_REGION || 'ap-south-1'}.amazonaws.com/${key}`;
}

/**
 * Upload file to local disk (development fallback)
 */
function uploadToLocal(buffer, filename) {
  const filePath = path.join(LOCAL_UPLOAD_DIR, filename);
  fs.writeFileSync(filePath, buffer);
  return `/uploads/${filename}`;
}

/**
 * Upload a file
 * @param {Buffer} buffer - File content
 * @param {string} originalName - Original filename
 * @param {string} contentType - MIME type
 * @param {string} folder - Subfolder (e.g., 'avatars', 'kyc', 'portfolio')
 * @returns {Promise<{url: string, key: string}>}
 */
async function uploadFile(buffer, originalName, contentType, folder = 'uploads') {
  const filename = generateFilename(originalName);
  const key = `${folder}/${filename}`;

  let url;
  if (STORAGE_PROVIDER === 's3' || STORAGE_PROVIDER === 'r2') {
    url = await uploadToS3(buffer, key, contentType);
  } else {
    // Local storage
    const localDir = path.join(LOCAL_UPLOAD_DIR, folder);
    if (!fs.existsSync(localDir)) fs.mkdirSync(localDir, { recursive: true });
    url = uploadToLocal(buffer, `${folder}/${filename}`);
  }

  logger.info({ provider: STORAGE_PROVIDER, key, contentType }, 'File uploaded');
  return { url, key };
}

/**
 * Delete a file from storage
 * @param {string} key - Storage key/path
 */
async function deleteFile(key) {
  if (STORAGE_PROVIDER === 's3' || STORAGE_PROVIDER === 'r2') {
    let S3Client, DeleteObjectCommand;
    try {
      const sdk = require('@aws-sdk/client-s3');
      S3Client = sdk.S3Client;
      DeleteObjectCommand = sdk.DeleteObjectCommand;
    } catch {
      logger.error('AWS SDK not installed');
      return;
    }

    const isR2 = STORAGE_PROVIDER === 'r2';
    const config = isR2
      ? {
          region: 'auto',
          endpoint: `https://${process.env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
          credentials: {
            accessKeyId: process.env.R2_ACCESS_KEY_ID,
            secretAccessKey: process.env.R2_SECRET_ACCESS_KEY,
          },
        }
      : {
          region: process.env.AWS_REGION || 'ap-south-1',
          credentials: {
            accessKeyId: process.env.AWS_ACCESS_KEY_ID,
            secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
          },
        };

    const bucket = isR2 ? process.env.R2_BUCKET : process.env.S3_BUCKET;
    const client = new S3Client(config);
    await client.send(new DeleteObjectCommand({ Bucket: bucket, Key: key }));
  } else {
    const filePath = path.join(LOCAL_UPLOAD_DIR, key);
    if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
  }

  logger.info({ key }, 'File deleted');
}

/**
 * Get a signed URL for temporary access (private files like KYC docs)
 * @param {string} key - Storage key
 * @param {number} expiresIn - Seconds until URL expires (default 1 hour)
 */
async function getSignedUrl(key, expiresIn = 3600) {
  if (STORAGE_PROVIDER === 'local') {
    return `/uploads/${key}`;
  }

  let S3Client, GetObjectCommand, getSignedUrl;
  try {
    const sdk = require('@aws-sdk/client-s3');
    const signer = require('@aws-sdk/s3-request-presigner');
    S3Client = sdk.S3Client;
    GetObjectCommand = sdk.GetObjectCommand;
    getSignedUrl = signer.getSignedUrl;
  } catch {
    logger.error('AWS SDK not installed for signed URLs');
    return `/uploads/${key}`;
  }

  const isR2 = STORAGE_PROVIDER === 'r2';
  const config = isR2
    ? {
        region: 'auto',
        endpoint: `https://${process.env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
        credentials: {
          accessKeyId: process.env.R2_ACCESS_KEY_ID,
          secretAccessKey: process.env.R2_SECRET_ACCESS_KEY,
        },
      }
    : {
        region: process.env.AWS_REGION || 'ap-south-1',
        credentials: {
          accessKeyId: process.env.AWS_ACCESS_KEY_ID,
          secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
        },
      };

  const bucket = isR2 ? process.env.R2_BUCKET : process.env.S3_BUCKET;
  const client = new S3Client(config);
  const command = new GetObjectCommand({ Bucket: bucket, Key: key });
  return getSignedUrl(client, command, { expiresIn });
}

module.exports = {
  uploadFile,
  deleteFile,
  getSignedUrl,
  generateFilename,
  STORAGE_PROVIDER,
};
