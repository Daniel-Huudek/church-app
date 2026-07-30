import { describe, expect, it } from 'vitest';
import { Prisma } from '@prisma/client';
import { BACKUP_VERSION, jsonSafe } from './service.js';

describe('backup jsonSafe', () => {
  it('serializes Decimal and Date', () => {
    const result = jsonSafe({
      amount: new Prisma.Decimal('12.50'),
      when: new Date('2026-07-30T12:00:00.000Z'),
      nested: [{ n: new Prisma.Decimal(1) }],
    }) as Record<string, unknown>;

    expect(result.amount).toBe('12.5');
    expect(result.when).toBe('2026-07-30T12:00:00.000Z');
    expect((result.nested as Array<Record<string, unknown>>)[0].n).toBe('1');
  });

  it('exposes current backup version', () => {
    expect(BACKUP_VERSION).toBe(1);
  });
});
