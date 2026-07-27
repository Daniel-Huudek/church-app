/** Calendar helpers for birthday ranges (local dates, Monday–Sunday week). */

export type BirthdayPeriod = 'today' | 'week' | 'month';

export interface DateRange {
  start: Date;
  end: Date;
}

function startOfDay(d: Date): Date {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

function endOfDay(d: Date): Date {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate(), 23, 59, 59, 999);
}

/** Monday as first day of week (ISO / BR common). */
export function startOfWeek(date: Date): Date {
  const d = startOfDay(date);
  const day = d.getDay(); // 0 Sun … 6 Sat
  const diff = day === 0 ? -6 : 1 - day;
  d.setDate(d.getDate() + diff);
  return d;
}

export function endOfWeek(date: Date): Date {
  const start = startOfWeek(date);
  return endOfDay(new Date(start.getFullYear(), start.getMonth(), start.getDate() + 6));
}

export function rangeForPeriod(period: BirthdayPeriod, now = new Date()): DateRange {
  if (period === 'today') {
    return { start: startOfDay(now), end: endOfDay(now) };
  }
  if (period === 'month') {
    const start = new Date(now.getFullYear(), now.getMonth(), 1);
    const end = endOfDay(new Date(now.getFullYear(), now.getMonth() + 1, 0));
    return { start, end };
  }
  return { start: startOfWeek(now), end: endOfWeek(now) };
}

/** Safe birthday occurrence in a given year (Feb 29 → Feb 28 on non-leap years). */
export function birthdayInYear(birth: Date, year: number): Date {
  const month = birth.getMonth();
  const day = birth.getDate();
  if (month === 1 && day === 29) {
    const leap = new Date(year, 1, 29).getMonth() === 1;
    return new Date(year, 1, leap ? 29 : 28);
  }
  return new Date(year, month, day);
}

export function birthdayOccurrenceInRange(birth: Date, start: Date, end: Date): Date | null {
  const years = new Set([start.getFullYear(), end.getFullYear()]);
  for (const year of years) {
    const occ = birthdayInYear(birth, year);
    if (occ >= startOfDay(start) && occ <= end) return occ;
  }
  return null;
}

export function turningAge(birth: Date, occurrence: Date): number {
  return occurrence.getFullYear() - birth.getFullYear();
}

export function isSameDay(a: Date, b: Date): boolean {
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  );
}

export function toDateOnlyIso(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}
