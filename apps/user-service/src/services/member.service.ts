import { PrismaClient, Member, Ministry } from '@prisma/client';
import { NotFoundError, ConflictError } from '../shared';

interface PaginatedResult<T> { data: T[]; total: number; page: number; limit: number; totalPages: number }

export class MemberService {
  constructor(private prisma: PrismaClient) {}

  async findAll({ page = 1, limit = 20 }: { page?: number; limit?: number }) {
    const skip = (page - 1) * limit;
    const [data, total] = await Promise.all([
      this.prisma.member.findMany({ skip, take: limit, where: { deletedAt: null }, include: { ministry: true } }),
      this.prisma.member.count({ where: { deletedAt: null } }),
    ]);
    return { success: true, data: { data, total, page, limit, totalPages: Math.ceil(total / limit) } };
  }

  async findById(id: string) {
    const data = await this.prisma.member.findFirst({ where: { id, deletedAt: null }, include: { ministry: true } });
    if (!data) throw new NotFoundError('Member not found');
    return { success: true, data };
  }

  async findByUserId(userId: string) {
    const data = await this.prisma.member.findFirst({ where: { userId, deletedAt: null }, include: { ministry: true } });
    if (!data) throw new NotFoundError('Member not found');
    return { success: true, data };
  }

  async create(body: { name: string; email: string; phone: string; ministryId?: string; role?: string }) {
    const user = await this.prisma.user.create({ data: { email: body.email, name: body.name, role: body.role as any || 'MEMBER', permissions: [] } });
    const data = await this.prisma.member.create({ data: { userId: user.id, name: body.name, email: body.email, phone: body.phone, ministryId: body.ministryId, role: body.role as any || 'MEMBER' }, include: { ministry: true } });
    return { success: true, data };
  }

  async update(id: string, body: Partial<{ name: string; email: string; phone: string; ministryId: string; role: string }>) {
    const data = await this.prisma.member.update({ where: { id }, data: body as any, include: { ministry: true } });
    await this.prisma.user.update({ where: { id: data.userId }, data: { name: body.name, email: body.email } });
    return { success: true, data };
  }

  async delete(id: string) {
    await this.prisma.member.update({ where: { id }, data: { deletedAt: new Date(), isActive: false } });
    return { success: true };
  }

  async findAllMinistries() {
    const data = await this.prisma.ministry.findMany({ where: { deletedAt: null }, include: { leader: true } });
    return { success: true, data };
  }

  async createMinistry(body: { name: string; description?: string; leaderId: string }) {
    const data = await this.prisma.ministry.create({ data: body, include: { leader: true } });
    return { success: true, data };
  }
}