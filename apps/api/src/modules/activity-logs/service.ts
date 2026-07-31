import { PrismaClient } from '@prisma/client';
import { ACTIVITY_DOMAINS, ActivityDomain } from './writer.js';

export class ActivityLogService {
  constructor(private prisma: PrismaClient) {}

  async list({
    page = 1,
    limit = 20,
    domain,
    action,
    from,
    to,
  }: {
    page?: number;
    limit?: number;
    domain?: string;
    action?: string;
    from?: string;
    to?: string;
  }) {
    const where: Record<string, unknown> = {};

    if (domain && ACTIVITY_DOMAINS.includes(domain as ActivityDomain)) {
      where.domain = domain;
    }
    if (action?.trim()) {
      where.action = action.trim().toUpperCase();
    }
    if (from || to) {
      const createdAt: { gte?: Date; lte?: Date } = {};
      if (from) createdAt.gte = new Date(from);
      if (to) createdAt.lte = new Date(to);
      where.createdAt = createdAt;
    }

    const skip = (page - 1) * limit;
    const [rows, total] = await Promise.all([
      this.prisma.activityLog.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.activityLog.count({ where }),
    ]);

    const actorIds = [...new Set(rows.map((r) => r.changedById).filter((id): id is string => !!id))];
    const actors = actorIds.length
      ? await this.prisma.user.findMany({
          where: { id: { in: actorIds } },
          select: { id: true, name: true, email: true },
        })
      : [];
    const actorById = new Map(actors.map((a) => [a.id, a]));

    const data = rows.map((row) => ({
      ...row,
      changedBy: row.changedById ? actorById.get(row.changedById) ?? null : null,
    }));

    return {
      success: true,
      data: {
        data,
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }
}
