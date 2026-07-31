import { describe, expect, it } from 'vitest';
import {
  ACTIVITY_DOMAINS,
  eventActivityLabel,
  financeActivityLabel,
  memberActivityLabel,
  prayerActivityLabel,
  scheduleActivityLabel,
} from './writer.js';

describe('activity log labels', () => {
  it('exposes the supported domains', () => {
    expect(ACTIVITY_DOMAINS).toEqual(['MEMBERS', 'FINANCE', 'EVENTS', 'SCHEDULES', 'PRAYERS']);
  });

  it('builds human-readable labels with fallbacks', () => {
    expect(memberActivityLabel({ id: '1', name: ' Ana ' })).toBe('Ana');
    expect(memberActivityLabel({ id: '1', name: null })).toBe('1');
    expect(financeActivityLabel({ id: 't1', description: ' Dizimo ', value: 10 })).toBe('Dizimo');
    expect(financeActivityLabel({ id: 't1', description: null, value: 42 })).toBe('42');
    expect(eventActivityLabel({ id: 'e1', title: ' Culto ' })).toBe('Culto');
    expect(scheduleActivityLabel({ id: 's1', date: '2026-07-31T10:00:00.000Z', startTime: '09:00' })).toBe(
      '2026-07-31 09:00',
    );
    expect(prayerActivityLabel({ id: 'p1', title: ' Pedido ' })).toBe('Pedido');
  });
});
