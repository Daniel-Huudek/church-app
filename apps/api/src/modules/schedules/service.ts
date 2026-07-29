import { PrismaClient } from '@prisma/client';
import { NotFoundError } from '@church-app/shared';

export class ScheduleService {
  constructor(private prisma: PrismaClient) {}

  async findAll({ page = 1, limit = 20, ministryId }: { page?: number; limit?: number; ministryId?: string }) {
    const skip = (page - 1) * limit;
    const where: { deletedAt: null; ministryId?: string } = { deletedAt: null };
    if (ministryId) where.ministryId = ministryId;
    const [data, total] = await Promise.all([
      this.prisma.schedule.findMany({ skip, take: limit, where, include: { positions: true }, orderBy: { date: 'desc' } }),
      this.prisma.schedule.count({ where }),
    ]);
    return { success: true, data: { data, total, page, limit, totalPages: Math.ceil(total / limit) } };
  }

  async findById(id: string) {
    const data = await this.prisma.schedule.findFirst({ where: { id, deletedAt: null }, include: { positions: true } });
    if (!data) throw new NotFoundError('Schedule not found');
    return { success: true, data };
  }

  async create(body: { eventId: string; ministryId: string; date: string; startTime: string; endTime: string; positions: { memberId: string; position: string }[] }) {
    const data = await this.prisma.schedule.create({
      data: { eventId: body.eventId, ministryId: body.ministryId, date: new Date(body.date), startTime: body.startTime, endTime: body.endTime },
    });
    await this.prisma.schedulePosition.createMany({
      data: body.positions.map(p => ({ scheduleId: data.id, memberId: p.memberId, position: p.position })),
    });
    return this.findById(data.id);
  }

  async update(
    id: string,
    body: Partial<{
      eventId: string;
      ministryId: string;
      date: string;
      startTime: string;
      endTime: string;
      positions: { memberId: string; position: string }[];
    }>,
  ) {
    const existing = await this.prisma.schedule.findFirst({ where: { id, deletedAt: null } });
    if (!existing) throw new NotFoundError('Schedule not found');

    const { positions, date, ...rest } = body;
    await this.prisma.schedule.update({
      where: { id },
      data: {
        ...rest,
        ...(date ? { date: new Date(date) } : {}),
      },
    });

    if (positions) {
      await this.prisma.schedulePosition.deleteMany({ where: { scheduleId: id } });
      if (positions.length > 0) {
        await this.prisma.schedulePosition.createMany({
          data: positions.map((p) => ({
            scheduleId: id,
            memberId: p.memberId,
            position: p.position,
          })),
        });
      }
    }

    return this.findById(id);
  }

  async delete(id: string) {
    await this.prisma.schedule.update({ where: { id }, data: { deletedAt: new Date() } });
    return { success: true };
  }

  async confirmPresence(body: { scheduleId: string; positionId: string; confirmed: boolean }) {
    await this.prisma.schedulePosition.update({ where: { id: body.positionId }, data: { isConfirmed: body.confirmed } });
    return { success: true, message: body.confirmed ? 'Presence confirmed' : 'Presence cancelled' };
  }

  async substitute(scheduleId: string, positionId: string, substituteMemberId: string) {
    await this.prisma.schedulePosition.update({ where: { id: positionId }, data: { substitutedById: substituteMemberId, isSubstituted: true } });
    return { success: true, message: 'Substitution completed' };
  }

  async findByMember(memberId: string) {
    const data = await this.prisma.schedulePosition.findMany({
      where: { memberId, schedule: { deletedAt: null } },
      include: { schedule: true },
    });
    return { success: true, data };
  }

  async getConflicts(memberId: string) {
    const positions = await this.prisma.schedulePosition.findMany({
      where: { memberId, schedule: { deletedAt: null } },
      include: { schedule: true },
    });
    const conflicts: any[] = [];
    for (let i = 0; i < positions.length; i++) {
      for (let j = i + 1; j < positions.length; j++) {
        if (positions[i].schedule.date.getTime() === positions[j].schedule.date.getTime() &&
            positions[i].schedule.startTime === positions[j].schedule.startTime) {
          conflicts.push({ schedule1: positions[i].scheduleId, schedule2: positions[j].scheduleId });
        }
      }
    }
    return { success: true, data: conflicts };
  }
}