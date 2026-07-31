import { PrismaClient } from '@prisma/client';
import { NotFoundError, ForbiddenError } from '@church-app/shared';
import { prayerActivityLabel, recordActivityLog } from '../activity-logs/writer.js';

export class PrayerService {
  constructor(private prisma: PrismaClient) {}

  async findAll({ page = 1, limit = 20, categoryId, isUrgent }: {
    page?: number; limit?: number; categoryId?: string; isUrgent?: boolean;
  }) {
    const where: any = { deletedAt: null, isPublic: true };
    if (categoryId) where.categoryId = categoryId;
    if (isUrgent) where.isUrgent = true;

    const skip = (page - 1) * limit;
    const [data, total] = await Promise.all([
      this.prisma.prayerRequest.findMany({
        skip, take: limit, where,
        include: {
          category: true,
          reactions: true,
          _count: { select: { comments: true, reactions: true, intercessors: true } },
        },
        orderBy: [{ isUrgent: 'desc' }, { createdAt: 'desc' }],
      }),
      this.prisma.prayerRequest.count({ where }),
    ]);
    return { success: true, data: { data, total, page, limit, totalPages: Math.ceil(total / limit) } };
  }

  async findMyPrayers(userId: string, { page = 1, limit = 20 }) {
    const where = { authorId: userId, deletedAt: null };
    const skip = (page - 1) * limit;
    const [data, total] = await Promise.all([
      this.prisma.prayerRequest.findMany({
        skip, take: limit, where,
        include: { category: true, reactions: true, _count: { select: { comments: true, reactions: true, intercessors: true } } },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.prayerRequest.count({ where }),
    ]);
    return { success: true, data: { data, total, page, limit, totalPages: Math.ceil(total / limit) } };
  }

  async findById(id: string, userId?: string) {
    const data = await this.prisma.prayerRequest.findFirst({
      where: { id, deletedAt: null },
      include: {
        category: true,
        comments: { orderBy: { createdAt: 'asc' } },
        reactions: true,
        intercessors: true,
        _count: { select: { comments: true, reactions: true, intercessors: true, favoritedBy: true } },
      },
    });
    if (!data) throw new NotFoundError('Prayer request not found');
    if (!data.isPublic && data.authorId !== userId) throw new ForbiddenError('This prayer is private');

    await this.prisma.prayerRequest.update({ where: { id }, data: { viewsCount: { increment: 1 } } });

    const payload: any = { ...data };
    if (payload.isAnonymous) delete payload.authorId;
    return { success: true, data: payload };
  }

  /** Private prayers are only visible/mutable by author (or already public). */
  private async requireAccessiblePrayer(prayerId: string, userId: string) {
    const prayer = await this.prisma.prayerRequest.findFirst({ where: { id: prayerId, deletedAt: null } });
    if (!prayer) throw new NotFoundError('Prayer request not found');
    if (!prayer.isPublic && prayer.authorId !== userId) {
      throw new ForbiddenError('This prayer is private');
    }
    return prayer;
  }

  async create(body: any) {
    const data = await this.prisma.prayerRequest.create({
      data: {
        authorId: body.authorId,
        title: body.title,
        content: body.content,
        categoryId: body.categoryId,
        isPublic: body.isPublic ?? true,
        isAnonymous: body.isAnonymous ?? false,
        isUrgent: body.isUrgent ?? false,
      },
      include: { category: true },
    });
    await recordActivityLog(this.prisma, {
      domain: 'PRAYERS',
      action: 'CREATED',
      entityId: data.id,
      entityLabel: prayerActivityLabel(data),
      changedById: body.authorId,
      oldValue: null,
      newValue: { id: data.id, title: data.title, isPublic: data.isPublic, isUrgent: data.isUrgent },
    });
    return { success: true, data };
  }

  async update(id: string, userId: string, body: any, role?: string) {
    const existing = await this.prisma.prayerRequest.findFirst({ where: { id, deletedAt: null } });
    if (!existing) throw new NotFoundError('Prayer request not found');
    if (existing.authorId !== userId && role !== 'ADMINISTRADOR') throw new ForbiddenError('Not authorized');

    const data = await this.prisma.prayerRequest.update({ where: { id }, data: body, include: { category: true } });
    await recordActivityLog(this.prisma, {
      domain: 'PRAYERS',
      action: 'UPDATED',
      entityId: data.id,
      entityLabel: prayerActivityLabel(data),
      changedById: userId,
      changedByRole: role,
      oldValue: { id: existing.id, title: existing.title, isPublic: existing.isPublic, isUrgent: existing.isUrgent },
      newValue: { id: data.id, title: data.title, isPublic: data.isPublic, isUrgent: data.isUrgent },
    });
    return { success: true, data };
  }

  async delete(id: string, userId: string, role?: string) {
    const existing = await this.prisma.prayerRequest.findFirst({ where: { id, deletedAt: null } });
    if (!existing) throw new NotFoundError('Prayer request not found');
    if (existing.authorId !== userId && role !== 'ADMINISTRADOR') throw new ForbiddenError('Not authorized');
    await this.prisma.prayerRequest.update({ where: { id }, data: { deletedAt: new Date() } });
    await recordActivityLog(this.prisma, {
      domain: 'PRAYERS',
      action: 'DELETED',
      entityId: existing.id,
      entityLabel: prayerActivityLabel(existing),
      changedById: userId,
      changedByRole: role,
      oldValue: { id: existing.id, title: existing.title, isPublic: existing.isPublic, isUrgent: existing.isUrgent },
      newValue: null,
    });
    return { success: true };
  }

  async markAnswered(id: string, userId: string) {
    const existing = await this.prisma.prayerRequest.findFirst({ where: { id, deletedAt: null } });
    if (!existing) throw new NotFoundError('Prayer request not found');
    if (existing.authorId !== userId) throw new ForbiddenError('Not authorized');
    const data = await this.prisma.prayerRequest.update({
      where: { id },
      data: { isAnswered: true, answeredAt: new Date(), answeredBy: userId },
    });
    await recordActivityLog(this.prisma, {
      domain: 'PRAYERS',
      action: 'ANSWERED',
      entityId: data.id,
      entityLabel: prayerActivityLabel(data),
      changedById: userId,
      oldValue: { id: existing.id, title: existing.title, isAnswered: existing.isAnswered },
      newValue: { id: data.id, title: data.title, isAnswered: data.isAnswered },
    });
    return { success: true, data };
  }

  // Comments
  async addComment(prayerId: string, authorId: string, content: string) {
    await this.requireAccessiblePrayer(prayerId, authorId);
    const data = await this.prisma.prayerComment.create({ data: { prayerId, authorId, content } });
    return { success: true, data };
  }

  // Reactions
  async toggleReaction(prayerId: string, userId: string, type: string) {
    await this.requireAccessiblePrayer(prayerId, userId);

    const existing = await this.prisma.prayerReaction.findUnique({
      where: { prayerId_userId_type: { prayerId, userId, type } },
    });
    if (existing) {
      await this.prisma.prayerReaction.delete({ where: { id: existing.id } });
      return { success: true, data: { action: 'removed' } };
    }
    const data = await this.prisma.prayerReaction.create({ data: { prayerId, userId, type } });
    return { success: true, data: { action: 'added', reaction: data } };
  }

  // Intercessors
  async addIntercessor(prayerId: string, userId: string) {
    await this.requireAccessiblePrayer(prayerId, userId);
    const existing = await this.prisma.intercessor.findUnique({
      where: { prayerId_userId: { prayerId, userId } },
    });
    if (existing) return { success: true, message: 'Already interceding' };
    const data = await this.prisma.intercessor.create({ data: { prayerId, userId } });
    return { success: true, data };
  }

  async getIntercessors(prayerId: string, userId: string) {
    await this.requireAccessiblePrayer(prayerId, userId);
    const data = await this.prisma.intercessor.findMany({ where: { prayerId } });
    return { success: true, data };
  }

  // Favorites
  async toggleFavorite(prayerId: string, userId: string) {
    await this.requireAccessiblePrayer(prayerId, userId);
    const existing = await this.prisma.userFavorite.findUnique({
      where: { prayerId_userId: { prayerId, userId } },
    });
    if (existing) {
      await this.prisma.userFavorite.delete({ where: { id: existing.id } });
      return { success: true, data: { action: 'removed' } };
    }
    await this.prisma.userFavorite.create({ data: { prayerId, userId } });
    return { success: true, data: { action: 'added' } };
  }

  async getFavorites(userId: string, { page = 1, limit = 20 }) {
    const where = {
      userId,
      prayer: {
        deletedAt: null,
        OR: [{ isPublic: true }, { authorId: userId }],
      },
    };
    const skip = (page - 1) * limit;
    const [data, total] = await Promise.all([
      this.prisma.userFavorite.findMany({
        skip, take: limit, where,
        include: { prayer: { include: { category: true, _count: { select: { comments: true, reactions: true, intercessors: true } } } } },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.userFavorite.count({ where }),
    ]);
    const prayers = data.map((f) => {
      const prayer: any = { ...f.prayer };
      if (prayer.isAnonymous) delete prayer.authorId;
      return prayer;
    });
    return { success: true, data: { data: prayers, total, page, limit, totalPages: Math.ceil(total / limit) } };
  }

  // Categories
  async findAllCategories() {
    const data = await this.prisma.prayerCategory.findMany({
      include: { _count: { select: { prayers: true } } },
    });
    return { success: true, data };
  }

  async createCategory(body: { name: string; color?: string; icon?: string }) {
    const data = await this.prisma.prayerCategory.create({ data: body });
    return { success: true, data };
  }
}
