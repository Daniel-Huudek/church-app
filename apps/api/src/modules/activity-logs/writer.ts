import { PrismaClient } from '@prisma/client';

export const ACTIVITY_DOMAINS = ['MEMBERS', 'FINANCE', 'EVENTS', 'SCHEDULES', 'PRAYERS'] as const;
export type ActivityDomain = (typeof ACTIVITY_DOMAINS)[number];

export type RecordActivityInput = {
  domain: ActivityDomain;
  action: string;
  entityId: string;
  entityLabel?: string | null;
  changedById?: string | null;
  changedByRole?: string | null;
  oldValue?: unknown;
  newValue?: unknown;
};

/** Persiste um evento no feed unificado do painel administrativo. */
export async function recordActivityLog(prisma: PrismaClient, input: RecordActivityInput): Promise<void> {
  await prisma.activityLog.create({
    data: {
      domain: input.domain,
      action: input.action,
      entityId: input.entityId,
      entityLabel: input.entityLabel ?? null,
      changedById: input.changedById ?? null,
      changedByRole: input.changedByRole ?? null,
      oldValue: input.oldValue ?? undefined,
      newValue: input.newValue ?? undefined,
    },
  });
}

export function memberActivityLabel(member: { name?: string | null; id: string }): string {
  return member.name?.trim() || member.id;
}

export function financeActivityLabel(tx: { description?: string | null; value?: unknown; id: string }): string {
  const desc = tx.description?.trim();
  if (desc) return desc;
  if (tx.value !== undefined && tx.value !== null) return String(tx.value);
  return tx.id;
}

export function eventActivityLabel(event: { title?: string | null; id: string }): string {
  return event.title?.trim() || event.id;
}

export function scheduleActivityLabel(schedule: {
  id: string;
  date?: Date | string | null;
  startTime?: string | null;
}): string {
  const date =
    schedule.date instanceof Date
      ? schedule.date.toISOString().slice(0, 10)
      : typeof schedule.date === 'string'
        ? schedule.date.slice(0, 10)
        : null;
  const time = schedule.startTime?.trim();
  if (date && time) return `${date} ${time}`;
  if (date) return date;
  return schedule.id;
}

export function prayerActivityLabel(prayer: { title?: string | null; id: string }): string {
  return prayer.title?.trim() || prayer.id;
}
