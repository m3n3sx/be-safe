// GCS upload helper for user-generated images (avatars + alert photos).
// Bucket besafe-uploads is public-read. URLs returned as /uploads/<key>
// which LB rewrites to gs://besafe-uploads/<key>.
//
// In Cloud Run, ADC uses default compute service account
// 1098119585965-compute@developer.gserviceaccount.com (granted storage.objectAdmin).
// Locally, falls back to filesystem path if GCS_BUCKET unset.

const path = require('path');
const fs = require('fs');

const BUCKET_NAME = process.env.GCS_BUCKET || '';
const LOCAL_DIR = process.env.UPLOAD_DIR || path.join(__dirname, '..', '..', 'uploads');

let bucket = null;
if (BUCKET_NAME) {
  const { Storage } = require('@google-cloud/storage');
  const storage = new Storage();
  bucket = storage.bucket(BUCKET_NAME);
}

if (!BUCKET_NAME && !fs.existsSync(LOCAL_DIR)) {
  fs.mkdirSync(LOCAL_DIR, { recursive: true });
}

/**
 * Upload a buffer to GCS (or local disk fallback).
 * @param {Buffer} buffer raw file bytes
 * @param {string} key relative key like "avatars/avatar-123.jpg" or "alerts/abc.png"
 * @param {string} contentType e.g. "image/jpeg"
 * @returns {Promise<string>} public path like "/uploads/avatars/avatar-123.jpg"
 */
async function uploadBuffer(buffer, key, contentType) {
  if (bucket) {
    const file = bucket.file(key);
    await file.save(buffer, {
      metadata: { contentType, cacheControl: 'public,max-age=2592000' },
      resumable: false,
      validation: false,
    });
    return `/uploads/${key}`;
  }
  // Local fallback: write into LOCAL_DIR with full key (creates subdirs)
  const fullPath = path.join(LOCAL_DIR, key);
  fs.mkdirSync(path.dirname(fullPath), { recursive: true });
  fs.writeFileSync(fullPath, buffer);
  return `/uploads/${key}`;
}

/**
 * Build a unique filename with extension from multer file.
 * @param {object} file multer file (originalname, mimetype)
 * @param {string} prefix e.g. "avatar-"
 * @returns {string} filename
 */
function makeFilename(file, prefix = '') {
  const ext = path.extname(file.originalname || '') || extFromMime(file.mimetype);
  return `${prefix}${Date.now()}-${Math.random().toString(36).slice(2, 8)}${ext}`;
}

function extFromMime(mime) {
  if (mime === 'image/jpeg') return '.jpg';
  if (mime === 'image/png') return '.png';
  if (mime === 'image/webp') return '.webp';
  return '';
}

module.exports = { uploadBuffer, makeFilename };
