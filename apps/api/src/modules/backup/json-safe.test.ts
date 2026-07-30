import { describe, expect, it } from 'vitest';
import { BACKUP_VERSION, jsonSafe } from './json-safe.js';

class Decimal {
  constructor(private readonly raw: string | number) {}
  toFixed(): string {
    return String(this.raw);
  }
  toString(): string {
    return String(this.raw);
  }
}

describe('backup jsonSafe', () => {
  it('serializes Decimal-like values and Date', () => {
    const result = jsonSafe({
      amount: new Decimal('12.50'),
      when: new Date('2026-07-30T12:00:00.000Z'),
      nested: [{ n: new Decimal(1) }],
    }) as Record<string, unknown>;

    expect(result.amount).toBe('12.50');
    expect(result.when).toBe('2026-07-30T12:00:00.000Z');
    expect((result.nested as Array<Record<string, unknown>>)[0].n).toBe('1');
  });

  it('exposes current backup version', () => {
    expect(BACKUP_VERSION).toBe(1);
  });
});
