import { PrismaClient } from '@prisma/client';
import { NotFoundError } from '@church-app/shared';
import { eventActivityLabel, recordActivityLog } from '../activity-logs/writer.js';

export class EventService {
  constructor(private prisma: PrismaClient) {}

  async findAll({ page = 1, limit = 20, startDate, endDate, type }: any) {
    const where: any = { deletedAt: null };
    if (startDate && endDate) where.date = { gte: new Date(startDate), lte: new Date(endDate) };
    if (type) where.type = type;
    const skip = (page - 1) * limit;
    const [data, total] = await Promise.all([this.prisma.event.findMany({ skip, take: limit, where }), this.prisma.event.count({ where })]);
    return { success: true, data: { data, total, page, limit, totalPages: Math.ceil(total / limit) } };
  }

  async findById(id: string) {
    const data = await this.prisma.event.findFirst({ where: { id, deletedAt: null } });
    if (!data) throw new NotFoundError('Event not found');
    return { success: true, data };
  }

  async create(body: any, actor?: { userId?: string; role?: string }) {
    const data = await this.prisma.event.create({ data: { ...body, date: new Date(body.date) } });
    await recordActivityLog(this.prisma, {
      domain: 'EVENTS',
      action: 'CREATED',
      entityId: data.id,
      entityLabel: eventActivityLabel(data),
      changedById: actor?.userId,
      changedByRole: actor?.role,
      oldValue: null,
      newValue: data,
    });
    return { success: true, data };
  }

  async update(id: string, body: any, actor?: { userId?: string; role?: string }) {
    const existing = await this.prisma.event.findFirst({ where: { id, deletedAt: null } });
    if (!existing) throw new NotFoundError('Event not found');
    const data = await this.prisma.event.update({
      where: { id },
      data: { ...body, date: body.date ? new Date(body.date) : undefined },
    });
    await recordActivityLog(this.prisma, {
      domain: 'EVENTS',
      action: 'UPDATED',
      entityId: data.id,
      entityLabel: eventActivityLabel(data),
      changedById: actor?.userId,
      changedByRole: actor?.role,
      oldValue: existing,
      newValue: data,
    });
    return { success: true, data };
  }

  async delete(id: string, actor?: { userId?: string; role?: string }) {
    const existing = await this.prisma.event.findFirst({ where: { id, deletedAt: null } });
    if (!existing) throw new NotFoundError('Event not found');
    await this.prisma.event.update({ where: { id }, data: { deletedAt: new Date() } });
    await recordActivityLog(this.prisma, {
      domain: 'EVENTS',
      action: 'DELETED',
      entityId: existing.id,
      entityLabel: eventActivityLabel(existing),
      changedById: actor?.userId,
      changedByRole: actor?.role,
      oldValue: existing,
      newValue: null,
    });
    return { success: true };
  }

  async getCalendar(startDate?: string, endDate?: string) {
    const where: any = { deletedAt: null };
    if (startDate && endDate) where.date = { gte: new Date(startDate), lte: new Date(endDate) };
    const data = await this.prisma.event.findMany({ where, orderBy: { date: 'asc' } });
    return { success: true, data };
  }
}
