import { describe, expect, it } from 'vitest';
import {
  birthdayOccurrenceInRange,
  rangeForPeriod,
  toDateOnlyIso,
  turningAge,
} from './birthday.js';

describe('birthday helpers', () => {
  it('builds Monday–Sunday week range', () => {
    // Wednesday 2026-07-29
    const { start, end } = rangeForPeriod('week', new Date(2026, 6, 29));
    expect(toDateOnlyIso(start)).toBe('2026-07-27');
    expect(toDateOnlyIso(end)).toBe('2026-08-02');
  });

  it('finds birthday occurrence in range across year boundary', () => {
    const birth = new Date(1990, 0, 2); // Jan 2
    const start = new Date(2025, 11, 29); // Dec 29
    const end = new Date(2026, 0, 4); // Jan 4
    const occ = birthdayOccurrenceInRange(birth, start, end);
    expect(occ).not.toBeNull();
    expect(toDateOnlyIso(occ!)).toBe('2026-01-02');
    expect(turningAge(birth, occ!)).toBe(36);
  });
});
