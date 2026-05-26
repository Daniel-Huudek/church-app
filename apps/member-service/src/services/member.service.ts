import { PrismaClient } from '@prisma/client';
import { NotFoundError, ConflictError } from '@church-app/shared';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const UPLOADS_DIR = path.join(__dirname, '../../uploads');

interface PaginatedResult<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export class MemberService {
  constructor(private prisma: PrismaClient) {}

  async findAll({ page = 1, limit = 20, name, email, status, role, ministryId, birthdayMonth }: {
    page?: number; limit?: number; name?: string; email?: string;
    status?: string; role?: string; ministryId?: string; birthdayMonth?: number;
  }) {
    const where: any = { deletedAt: null };
    if (name) where.name = { contains: name, mode: 'insensitive' };
    if (email) where.email = { contains: email, mode: 'insensitive' };
    if (status) where.status = status;
    if (role) where.role = role;
    if (ministryId) where.ministryId = ministryId;
    if (birthdayMonth) {
      where.dateOfBirth = { not: null };
    }

    const skip = (page - 1) * limit;
    const [data, total] = await Promise.all([
      this.prisma.member.findMany({
        skip, take: limit, where,
        include: { ministry: true, address: true },
        orderBy: { name: 'asc' },
      }),
      this.prisma.member.count({ where }),
    ]);

    let filteredData = data;
    if (birthdayMonth) {
      filteredData = data.filter((m) => {
        if (!m.dateOfBirth) return false;
        return m.dateOfBirth.getMonth() + 1 === birthdayMonth;
      });
    }

    return { success: true, data: { data: filteredData, total: birthdayMonth ? filteredData.length : total, page, limit, totalPages: Math.ceil((birthdayMonth ? filteredData.length : total) / limit) } };
  }

  async search(query: string, { page = 1, limit = 20 }) {
    const where = {
      deletedAt: null,
      OR: [
        { name: { contains: query, mode: 'insensitive' as const } },
        { email: { contains: query, mode: 'insensitive' as const } },
        { phone: { contains: query } },
        { occupation: { contains: query, mode: 'insensitive' as const } },
      ],
    };
    const skip = (page - 1) * limit;
    const [data, total] = await Promise.all([
      this.prisma.member.findMany({ skip, take: limit, where, include: { ministry: true } }),
      this.prisma.member.count({ where }),
    ]);
    return { success: true, data: { data, total, page, limit, totalPages: Math.ceil(total / limit) } };
  }

  async findById(id: string) {
    const data = await this.prisma.member.findFirst({
      where: { id, deletedAt: null },
      include: { ministry: true, address: true, documents: true, familyMembers: true, ministerialHistory: true },
    });
    if (!data) throw new NotFoundError('Member not found');
    return { success: true, data };
  }

  async create(body: any) {
    const { address, documents, familyMembers, ministerialHistory, ...memberData } = body;
    const data = await this.prisma.member.create({
      data: {
        ...memberData,
        dateOfBirth: body.dateOfBirth ? new Date(body.dateOfBirth) : undefined,
        baptismDate: body.baptismDate ? new Date(body.baptismDate) : undefined,
        conversionDate: body.conversionDate ? new Date(body.conversionDate) : undefined,
        address: address ? { create: address } : undefined,
        documents: documents ? { create: documents } : undefined,
        familyMembers: familyMembers ? { create: familyMembers } : undefined,
        ministerialHistory: ministerialHistory ? { create: ministerialHistory } : undefined,
      },
      include: { ministry: true, address: true, documents: true, familyMembers: true },
    });
    await this.createAuditLog(data.id, 'CREATED', null, data, 'system');
    return { success: true, data };
  }

  async update(id: string, body: any) {
    const existing = await this.prisma.member.findFirst({ where: { id, deletedAt: null } });
    if (!existing) throw new NotFoundError('Member not found');

    const { address, documents, familyMembers, ministerialHistory, ...memberData } = body;
    const data = await this.prisma.member.update({
      where: { id },
      data: {
        ...memberData,
        dateOfBirth: body.dateOfBirth ? new Date(body.dateOfBirth) : undefined,
        baptismDate: body.baptismDate ? new Date(body.baptismDate) : undefined,
        conversionDate: body.conversionDate ? new Date(body.conversionDate) : undefined,
        address: address ? { upsert: { create: address, update: address } } : undefined,
      },
      include: { ministry: true, address: true, documents: true, familyMembers: true },
    });
    await this.createAuditLog(id, 'UPDATED', existing, data, body.changedBy);
    return { success: true, data };
  }

  async delete(id: string) {
    const existing = await this.prisma.member.findFirst({ where: { id, deletedAt: null } });
    if (!existing) throw new NotFoundError('Member not found');
    await this.prisma.member.update({ where: { id }, data: { deletedAt: new Date(), isActive: false } });
    await this.createAuditLog(id, 'DELETED', existing, null, 'system');
    return { success: true };
  }

  async findByUserId(userId: string) {
    const data = await this.prisma.member.findFirst({
      where: { userId, deletedAt: null },
      include: { ministry: true, address: true },
    });
    if (!data) throw new NotFoundError('Member not found');
    return { success: true, data };
  }

  // Address
  async getAddress(memberId: string) {
    const member = await this.prisma.member.findFirst({ where: { id: memberId, deletedAt: null } });
    if (!member) throw new NotFoundError('Member not found');
    const data = await this.prisma.address.findUnique({ where: { memberId } });
    return { success: true, data };
  }

  async upsertAddress(memberId: string, body: any) {
    const member = await this.prisma.member.findFirst({ where: { id: memberId, deletedAt: null } });
    if (!member) throw new NotFoundError('Member not found');
    const data = await this.prisma.address.upsert({
      where: { memberId },
      create: { memberId, ...body },
      update: body,
    });
    return { success: true, data };
  }

  // Documents
  async getDocuments(memberId: string) {
    const member = await this.prisma.member.findFirst({ where: { id: memberId, deletedAt: null } });
    if (!member) throw new NotFoundError('Member not found');
    const data = await this.prisma.document.findMany({ where: { memberId } });
    return { success: true, data };
  }

  async addDocument(memberId: string, body: { type: string; value: string }) {
    const member = await this.prisma.member.findFirst({ where: { id: memberId, deletedAt: null } });
    if (!member) throw new NotFoundError('Member not found');
    const data = await this.prisma.document.create({ data: { memberId, ...body } });
    return { success: true, data };
  }

  async deleteDocument(id: string) {
    await this.prisma.document.delete({ where: { id } });
    return { success: true };
  }

  // Family
  async getFamilyMembers(memberId: string) {
    const member = await this.prisma.member.findFirst({ where: { id: memberId, deletedAt: null } });
    if (!member) throw new NotFoundError('Member not found');
    const data = await this.prisma.familyMember.findMany({ where: { memberId } });
    return { success: true, data };
  }

  async addFamilyMember(memberId: string, body: { name: string; kinship: string; phone?: string }) {
    const member = await this.prisma.member.findFirst({ where: { id: memberId, deletedAt: null } });
    if (!member) throw new NotFoundError('Member not found');
    const data = await this.prisma.familyMember.create({ data: { memberId, ...body } });
    return { success: true, data };
  }

  async deleteFamilyMember(id: string) {
    await this.prisma.familyMember.delete({ where: { id } });
    return { success: true };
  }

  // Ministerial History
  async getMinisterialHistory(memberId: string) {
    const member = await this.prisma.member.findFirst({ where: { id: memberId, deletedAt: null } });
    if (!member) throw new NotFoundError('Member not found');
    const data = await this.prisma.ministerialHistory.findMany({ where: { memberId }, orderBy: { startDate: 'desc' } });
    return { success: true, data };
  }

  async addMinisterialHistory(memberId: string, body: any) {
    const member = await this.prisma.member.findFirst({ where: { id: memberId, deletedAt: null } });
    if (!member) throw new NotFoundError('Member not found');
    const data = await this.prisma.ministerialHistory.create({
      data: {
        memberId,
        ministry: body.ministry,
        role: body.role,
        startDate: new Date(body.startDate),
        endDate: body.endDate ? new Date(body.endDate) : undefined,
        description: body.description,
      },
    });
    return { success: true, data };
  }

  // Photo upload
  async uploadPhoto(memberId: string, filename: string, buffer: Buffer) {
    const member = await this.prisma.member.findFirst({ where: { id: memberId, deletedAt: null } });
    if (!member) throw new NotFoundError('Member not found');

    await fs.mkdir(UPLOADS_DIR, { recursive: true });
    const ext = path.extname(filename);
    const savedName = `member-${memberId}${ext}`;
    const filePath = path.join(UPLOADS_DIR, savedName);
    await fs.writeFile(filePath, buffer);

    const data = await this.prisma.member.update({
      where: { id: memberId },
      data: { avatar: `/uploads/${savedName}` },
    });
    return { success: true, data };
  }

  // Audit
  async getAuditLogs(memberId: string) {
    const data = await this.prisma.auditLog.findMany({
      where: { memberId },
      orderBy: { createdAt: 'desc' },
    });
    return { success: true, data };
  }

  private async createAuditLog(memberId: string, action: string, oldValue: any, newValue: any, changedBy?: string) {
    await this.prisma.auditLog.create({
      data: { memberId, action, changedBy, oldValue, newValue },
    });
  }

  // Ministries
  async findAllMinistries() {
    const data = await this.prisma.ministry.findMany({
      where: { deletedAt: null },
      include: { leader: true, _count: { select: { members: true } } },
    });
    return { success: true, data };
  }

  async createMinistry(body: { name: string; description?: string; leaderId: string }) {
    const data = await this.prisma.ministry.create({ data: body, include: { leader: true } });
    return { success: true, data };
  }

  async updateMinistry(id: string, body: Partial<{ name: string; description: string; leaderId: string }>) {
    const data = await this.prisma.ministry.update({ where: { id }, data: body, include: { leader: true } });
    return { success: true, data };
  }

  async deleteMinistry(id: string) {
    await this.prisma.ministry.update({ where: { id }, data: { deletedAt: new Date() } });
    return { success: true };
  }

  // Export
  async exportCsv() {
    const members = await this.prisma.member.findMany({
      where: { deletedAt: null },
      include: { address: true, ministry: true },
      orderBy: { name: 'asc' },
    });
    return members.map((m) => ({
      name: m.name,
      email: m.email || '',
      phone: m.phone || '',
      status: m.status,
      role: m.role,
      ministry: m.ministry?.name || '',
      city: m.address?.city || '',
      state: m.address?.state || '',
    }));
  }

  async importCsv(records: any[]) {
    const results: any[] = [];
    for (const record of records) {
      try {
        const data = await this.prisma.member.create({
          data: {
            name: record.name,
            email: record.email,
            phone: record.phone,
            status: record.status || 'ATIVO',
            role: record.role || 'MEMBRO',
            isBaptized: record.isBaptized === 'true' || record.isBaptized === 'sim',
          },
        });
        results.push({ success: true, data });
      } catch (error: any) {
        results.push({ success: false, name: record.name, error: error.message });
      }
    }
    return { success: true, data: results };
  }
}
