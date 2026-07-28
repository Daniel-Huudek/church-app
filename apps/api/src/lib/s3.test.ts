import { describe, expect, it } from 'vitest';
import {
  buildWebsiteObjectKey,
  normalizeImageExtension,
} from './s3.js';

describe('s3 helpers', () => {
  it('normalizes jpeg extension', () => {
    expect(normalizeImageExtension('photo.JPEG', 'image/jpeg')).toBe('.jpg');
    expect(normalizeImageExtension('a.png')).toBe('.png');
  });

  it('builds website object keys under website/{kind}/', () => {
    const key = buildWebsiteObjectKey('leadership', 'pastor.png', 'image/png');
    expect(key.startsWith('website/leadership/')).toBe(true);
    expect(key.endsWith('.png')).toBe(true);
  });
});
