import { describe, expect, it } from 'vitest';
import { websiteContentSchema } from './schema.js';
import { DEFAULT_WEBSITE_CONTENT } from './defaults.js';

describe('websiteContentSchema', () => {
  it('accepts default website content', () => {
    const parsed = websiteContentSchema.parse(DEFAULT_WEBSITE_CONTENT);
    expect(parsed.brand).toBe('IPI Avaré');
    expect(parsed.faith.paragraphs.length).toBeGreaterThan(0);
    expect(parsed.leadership.name).toBeTruthy();
  });

  it('rejects empty brand', () => {
    expect(() =>
      websiteContentSchema.parse({
        ...DEFAULT_WEBSITE_CONTENT,
        brand: '',
      }),
    ).toThrow();
  });
});
