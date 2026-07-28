import { randomUUID } from 'node:crypto';
import path from 'node:path';
import { PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { AppError } from '@church-app/shared';

const ALLOWED_EXT = new Set(['.jpg', '.jpeg', '.png', '.webp']);
const ALLOWED_MIME = new Set(['image/jpeg', 'image/png', 'image/webp']);

export type WebsiteUploadKind = 'leadership' | 'series' | 'news' | 'streams' | 'events' | 'logo' | 'general';

export function getS3Config() {
  const region = process.env.AWS_REGION || process.env.AWS_DEFAULT_REGION || '';
  const bucket = process.env.AWS_S3_BUCKET || '';
  const accessKeyId = process.env.AWS_ACCESS_KEY_ID || '';
  const secretAccessKey = process.env.AWS_SECRET_ACCESS_KEY || '';
  const endpoint = process.env.AWS_S3_ENDPOINT || undefined;
  const publicBaseUrl = (process.env.AWS_S3_PUBLIC_BASE_URL || '').replace(/\/$/, '');
  const forcePathStyle = process.env.AWS_S3_FORCE_PATH_STYLE === 'true';

  return {
    region,
    bucket,
    accessKeyId,
    secretAccessKey,
    endpoint,
    publicBaseUrl,
    forcePathStyle,
  };
}

export function assertS3Configured() {
  const cfg = getS3Config();
  if (!cfg.region || !cfg.bucket || !cfg.accessKeyId || !cfg.secretAccessKey) {
    throw new AppError(
      'AWS S3 não configurado. Defina AWS_REGION, AWS_S3_BUCKET, AWS_ACCESS_KEY_ID e AWS_SECRET_ACCESS_KEY.',
      503,
      'S3_NOT_CONFIGURED',
    );
  }
  return cfg;
}

export function normalizeImageExtension(filename: string, mimeType?: string): string {
  const fromName = path.extname(filename).toLowerCase();
  if (ALLOWED_EXT.has(fromName)) {
    return fromName === '.jpeg' ? '.jpg' : fromName;
  }
  if (mimeType === 'image/png') return '.png';
  if (mimeType === 'image/webp') return '.webp';
  if (mimeType === 'image/jpeg') return '.jpg';
  throw new AppError('Formato de imagem inválido. Use jpg, png ou webp.', 400, 'INVALID_IMAGE');
}

export function assertImageMime(mimeType?: string) {
  if (mimeType && !ALLOWED_MIME.has(mimeType)) {
    throw new AppError('Arquivo deve ser uma imagem (jpg, png ou webp).', 400, 'INVALID_IMAGE');
  }
}

export function buildWebsiteObjectKey(kind: WebsiteUploadKind, filename: string, mimeType?: string) {
  const ext = normalizeImageExtension(filename, mimeType);
  const safeKind = kind.replace(/[^a-z]/gi, '').toLowerCase() || 'general';
  return `website/${safeKind}/${randomUUID()}${ext}`;
}

export function buildPublicUrl(key: string): string {
  const cfg = assertS3Configured();
  if (cfg.publicBaseUrl) {
    return `${cfg.publicBaseUrl}/${key}`;
  }
  if (cfg.endpoint) {
    const base = cfg.endpoint.replace(/\/$/, '');
    return cfg.forcePathStyle ? `${base}/${cfg.bucket}/${key}` : `${base}/${key}`;
  }
  return `https://${cfg.bucket}.s3.${cfg.region}.amazonaws.com/${key}`;
}

function createClient() {
  const cfg = assertS3Configured();
  return new S3Client({
    region: cfg.region,
    credentials: {
      accessKeyId: cfg.accessKeyId,
      secretAccessKey: cfg.secretAccessKey,
    },
    ...(cfg.endpoint
      ? {
          endpoint: cfg.endpoint,
          forcePathStyle: cfg.forcePathStyle,
        }
      : {}),
  });
}

export async function uploadWebsiteImage(params: {
  kind: WebsiteUploadKind;
  filename: string;
  buffer: Buffer;
  mimeType?: string;
}) {
  assertImageMime(params.mimeType);
  const cfg = assertS3Configured();
  const key = buildWebsiteObjectKey(params.kind, params.filename, params.mimeType);
  const contentType =
    params.mimeType && ALLOWED_MIME.has(params.mimeType)
      ? params.mimeType
      : key.endsWith('.png')
        ? 'image/png'
        : key.endsWith('.webp')
          ? 'image/webp'
          : 'image/jpeg';

  const client = createClient();
  await client.send(
    new PutObjectCommand({
      Bucket: cfg.bucket,
      Key: key,
      Body: params.buffer,
      ContentType: contentType,
      CacheControl: 'public, max-age=31536000, immutable',
    }),
  );

  return {
    key,
    url: buildPublicUrl(key),
    contentType,
  };
}
