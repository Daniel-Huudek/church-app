import { PrismaClient } from '@prisma/client';
import { NotFoundError, ConflictError, BadRequestError } from '@church-app/shared';
import fs from 'fs/promises';
import path from 'path';
import {
  BirthdayPeriod,
  birthdayOccurrenceInRange,
  isSameDay,
  rangeForPeriod,
  toDateOnlyIso,
  turningAge,
} from './utils/birthday.js';

const UPLOADS_DIR = process.env.UPLOADS_DIR || path.join(process.cwd(), 'uploads');

const ALLOWED_PHOTO_EXT = new Set(['.jpg', '.jpeg', '.png', '.webp']);

function normalizeEmail(email?: string | null): string | undefined {
  if (!email) return undefined;
  const trimmed = email.trim().toLowerCase();
  return trimmed || undefined;
}

function normalizePhone(phone?: string | null): string | undefined {
  if (!phone) return undefined;
  const digits = phone.replace(/\D/g, '');
  return digits || undefined;
}

export class MemberService {
  constructor(private prisma: PrismaClient) {}

  private withPublicAvatar<T extends { id: string; avatar?: string | null }>(member: T): T {
    if (!member.avatar) return member;
    return { ...member, avatar: `/members/${member.id}/avatar` };
  }

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

    if (birthdayMonth && birthdayMonth >= 1 && birthdayMonth <= 12) {
      const candidates = await this.prisma.member.findMany({
        where: { ...where, dateOfBirth: { not: null } },
        select: { id: true, dateOfBirth: true },
        orderBy: { name: 'asc' },
      });
      const matchingIds = candidates
        .filter((m) => m.dateOfBirth && m.dateOfBirth.getUTCMonth() + 1 === birthdayMonth)
        .map((m) => m.id);
      const total = matchingIds.length;
      const skip = (page - 1) * limit;
      const pageIds = matchingIds.slice(skip, skip + limit);
      const data = pageIds.length
        ? await this.prisma.member.findMany({
            where: { id: { in: pageIds } },
            include: { ministry: true, address: true },
            orderBy: { name: 'asc' },
          })
        : [];
      return {
        success: true,
        data: {
          data: data.map((m) => this.withPublicAvatar(m)),
          total,
          page,
          limit,
          totalPages: Math.ceil(total / limit) || 0,
        },
      };
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

    return {
      success: true,
      data: {
        data: data.map((m) => this.withPublicAvatar(m)),
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit) || 0,
      },
    };
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
    return {
      success: true,
      data: {
        data: data.map((m) => this.withPublicAvatar(m)),
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit) || 0,
      },
    };
  }

  async findById(id: string) {
    const data = await this.prisma.member.findFirst({
      where: { id, deletedAt: null },
      include: { ministry: true, address: true, documents: true, familyMembers: true, ministerialHistory: true },
    });
    if (!data) throw new NotFoundError('Member not found');
    return { success: true, data: this.withPublicAvatar(data) };
  }

  async findBirthdays(period: BirthdayPeriod = 'week', now = new Date()) {
    const { start, end } = rangeForPeriod(period, now);
    const members = await this.prisma.member.findMany({
      where: {
        deletedAt: null,
        dateOfBirth: { not: null },
        status: { not: 'EXCLUIDO' },
      },
      include: { ministry: true },
      orderBy: { name: 'asc' },
    });

    const items = members
      .map((member) => {
        const birth = member.dateOfBirth!;
        const occurrence = birthdayOccurrenceInRange(birth, start, end);
        if (!occurrence) return null;
        return {
          ...this.withPublicAvatar(member),
          birthdayThisYear: toDateOnlyIso(occurrence),
          turningAge: turningAge(birth, occurrence),
          isToday: isSameDay(occurrence, now),
        };
      })
      .filter((item): item is NonNullable<typeof item> => item != null)
      .sort((a, b) => {
        if (a.birthdayThisYear === b.birthdayThisYear) {
          return a.name.localeCompare(b.name, 'pt-BR');
        }
        return a.birthdayThisYear.localeCompare(b.birthdayThisYear);
      });

    return {
      success: true,
      data: {
        period,
        startDate: toDateOnlyIso(start),
        endDate: toDateOnlyIso(end),
        total: items.length,
        items,
      },
    };
  }

  async findDuplicates({ email, phone, name, excludeId }: {
    email?: string; phone?: string; name?: string; excludeId?: string;
  }) {
    const or: any[] = [];
    const normalizedEmail = normalizeEmail(email);
    const normalizedPhone = normalizePhone(phone);
    if (normalizedEmail) or.push({ email: { equals: normalizedEmail, mode: 'insensitive' } });
    if (normalizedPhone) or.push({ phone: { contains: normalizedPhone } });
    if (name?.trim()) or.push({ name: { equals: name.trim(), mode: 'insensitive' } });
    if (or.length === 0) return [];

    return this.prisma.member.findMany({
      where: {
        deletedAt: null,
        ...(excludeId ? { id: { not: excludeId } } : {}),
        OR: or,
      },
      select: { id: true, name: true, email: true, phone: true, status: true },
      take: 10,
    });
  }

  private async assertUserExists(userId?: string) {
    if (!userId) return;
    const user = await this.prisma.user.findFirst({ where: { id: userId, deletedAt: null } });
    if (!user) throw new BadRequestError('userId does not reference an existing user');
  }

  private async assertEmailUnique(email?: string, excludeId?: string) {
    const normalized = normalizeEmail(email);
    if (!normalized) return;
    const existing = await this.prisma.member.findFirst({
      where: {
        deletedAt: null,
        email: { equals: normalized, mode: 'insensitive' },
        ...(excludeId ? { id: { not: excludeId } } : {}),
      },
    });
    if (existing) throw new ConflictError('Já existe um membro com este e-mail');
  }

  async create(body: any, changedBy?: string) {
    const { address, documents, familyMembers, ministerialHistory, forceDuplicate, ...memberData } = body;
    const email = normalizeEmail(memberData.email);
    const phone = memberData.phone?.trim() || undefined;

    await this.assertUserExists(memberData.userId);
    await this.assertEmailUnique(email);

    if (!forceDuplicate) {
      const duplicates = await this.findDuplicates({ email, phone, name: memberData.name });
      if (duplicates.length > 0) {
        throw new ConflictError('Possível membro duplicado. Confirme com forceDuplicate=true se desejar continuar.');
      }
    }

    const data = await this.prisma.member.create({
      data: {
        ...memberData,
        email,
        phone,
        dateOfBirth: body.dateOfBirth ? new Date(body.dateOfBirth) : undefined,
        baptismDate: body.baptismDate ? new Date(body.baptismDate) : undefined,
        conversionDate: body.conversionDate ? new Date(body.conversionDate) : undefined,
        admissionDate: body.admissionDate ? new Date(body.admissionDate) : undefined,
        address: address ? { create: address } : undefined,
        documents: documents ? { create: documents } : undefined,
        familyMembers: familyMembers ? { create: familyMembers } : undefined,
        ministerialHistory: ministerialHistory ? { create: ministerialHistory } : undefined,
      },
      include: { ministry: true, address: true, documents: true, familyMembers: true },
    });
    await this.createAuditLog(data.id, 'CREATED', null, data, changedBy);
    return { success: true, data: this.withPublicAvatar(data) };
  }

  async update(id: string, body: any, changedBy?: string) {
    const existing = await this.prisma.member.findFirst({ where: { id, deletedAt: null } });
    if (!existing) throw new NotFoundError('Member not found');

    const { address, forceDuplicate, ...memberData } = body;
    if (memberData.userId !== undefined) await this.assertUserExists(memberData.userId);
    if (memberData.email !== undefined) {
      memberData.email = normalizeEmail(memberData.email);
      await this.assertEmailUnique(memberData.email, id);
    }

    if (!forceDuplicate && (memberData.email || memberData.phone || memberData.name)) {
      const duplicates = await this.findDuplicates({
        email: memberData.email ?? existing.email ?? undefined,
        phone: memberData.phone ?? existing.phone ?? undefined,
        name: memberData.name ?? existing.name,
        excludeId: id,
      });
      // Only block on email/phone matches for update, not name-only
      const hard = duplicates.filter((d) =>
        (memberData.email && d.email && normalizeEmail(d.email) === normalizeEmail(memberData.email)) ||
        (memberData.phone && d.phone && normalizePhone(d.phone) === normalizePhone(memberData.phone))
      );
      if (hard.length > 0) {
        throw new ConflictError('Conflito com outro membro (e-mail ou telefone). Use forceDuplicate=true para forçar.');
      }
    }

    const data = await this.prisma.member.update({
      where: { id },
      data: {
        ...memberData,
        dateOfBirth: body.dateOfBirth ? new Date(body.dateOfBirth) : undefined,
        baptismDate: body.baptismDate ? new Date(body.baptismDate) : undefined,
        conversionDate: body.conversionDate ? new Date(body.conversionDate) : undefined,
        admissionDate: body.admissionDate ? new Date(body.admissionDate) : undefined,
        address: address ? { upsert: { create: address, update: address } } : undefined,
      },
      include: { ministry: true, address: true, documents: true, familyMembers: true },
    });
    await this.createAuditLog(id, 'UPDATED', existing, data, changedBy);
    return { success: true, data: this.withPublicAvatar(data) };
  }

  async delete(id: string, changedBy?: string) {
    const existing = await this.prisma.member.findFirst({ where: { id, deletedAt: null } });
    if (!existing) throw new NotFoundError('Member not found');
    await this.prisma.member.update({
      where: { id },
      data: { deletedAt: new Date(), isActive: false, status: 'EXCLUIDO' },
    });
    await this.createAuditLog(id, 'DELETED', existing, null, changedBy);
    return { success: true };
  }

  async findByUserId(userId: string) {
    const data = await this.prisma.member.findFirst({
      where: { userId, deletedAt: null },
      include: { ministry: true, address: true },
    });
    if (!data) throw new NotFoundError('Member not found');
    return { success: true, data: this.withPublicAvatar(data) };
  }

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

  async deleteDocument(memberId: string, docId: string) {
    const doc = await this.prisma.document.findFirst({ where: { id: docId, memberId } });
    if (!doc) throw new NotFoundError('Document not found');
    await this.prisma.document.delete({ where: { id: docId } });
    return { success: true };
  }

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

  async deleteFamilyMember(memberId: string, familyId: string) {
    const row = await this.prisma.familyMember.findFirst({ where: { id: familyId, memberId } });
    if (!row) throw new NotFoundError('Family member not found');
    await this.prisma.familyMember.delete({ where: { id: familyId } });
    return { success: true };
  }

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

  async uploadPhoto(memberId: string, filename: string, buffer: Buffer, mimeType?: string) {
    const member = await this.prisma.member.findFirst({ where: { id: memberId, deletedAt: null } });
    if (!member) throw new NotFoundError('Member not found');

    const ext = path.extname(filename).toLowerCase() || '.jpg';
    if (!ALLOWED_PHOTO_EXT.has(ext)) {
      throw new BadRequestError('Formato de imagem inválido. Use jpg, png ou webp.');
    }
    if (mimeType && !mimeType.startsWith('image/')) {
      throw new BadRequestError('Arquivo deve ser uma imagem');
    }

    await fs.mkdir(UPLOADS_DIR, { recursive: true });
    const savedName = `member-${memberId}${ext}`;
    const filePath = path.join(UPLOADS_DIR, savedName);
    await fs.writeFile(filePath, buffer);

    const data = await this.prisma.member.update({
      where: { id: memberId },
      data: { avatar: savedName },
    });
    return { success: true, data: this.withPublicAvatar(data) };
  }

  async getAvatarFile(memberId: string): Promise<{ filePath: string; contentType: string }> {
    const member = await this.prisma.member.findFirst({ where: { id: memberId, deletedAt: null } });
    if (!member?.avatar) throw new NotFoundError('Avatar not found');

    const savedName = member.avatar.startsWith('/uploads/')
      ? path.basename(member.avatar)
      : member.avatar.startsWith('/members/')
        ? null
        : path.basename(member.avatar);

    // Prefer stored filename; fall back to scanning known extensions
    const candidates = savedName
      ? [path.join(UPLOADS_DIR, savedName)]
      : [...ALLOWED_PHOTO_EXT].map((ext) => path.join(UPLOADS_DIR, `member-${memberId}${ext}`));

    for (const filePath of candidates) {
      try {
        await fs.access(filePath);
        const ext = path.extname(filePath).toLowerCase();
        const contentType =
          ext === '.png' ? 'image/png' : ext === '.webp' ? 'image/webp' : 'image/jpeg';
        return { filePath, contentType };
      } catch {
        /* try next */
      }
    }
    throw new NotFoundError('Avatar file not found');
  }

  async getAuditLogs(memberId: string) {
    const data = await this.prisma.auditLog.findMany({
      where: { memberId },
      orderBy: { createdAt: 'desc' },
    });
    return { success: true, data };
  }

  private async createAuditLog(memberId: string, action: string, oldValue: any, newValue: any, changedBy?: string) {
    await this.prisma.auditLog.create({
      data: { memberId, action, changedBy: changedBy || null, oldValue, newValue },
    });
  }

  async findAllMinistries() {
    const data = await this.prisma.ministry.findMany({
      where: { deletedAt: null },
      include: { leader: true, _count: { select: { members: true } } },
    });
    return { success: true, data };
  }

  async createMinistry(body: { name: string; description?: string; leaderId?: string }) {
    if (body.leaderId) {
      const leader = await this.prisma.member.findFirst({ where: { id: body.leaderId, deletedAt: null } });
      if (!leader) throw new BadRequestError('leaderId does not reference an existing member');
    }
    const data = await this.prisma.ministry.create({ data: body, include: { leader: true } });
    return { success: true, data };
  }

  async updateMinistry(id: string, body: Partial<{ name: string; description: string; leaderId: string }>) {
    const existing = await this.prisma.ministry.findFirst({ where: { id, deletedAt: null } });
    if (!existing) throw new NotFoundError('Ministry not found');
    if (body.leaderId) {
      const leader = await this.prisma.member.findFirst({ where: { id: body.leaderId, deletedAt: null } });
      if (!leader) throw new BadRequestError('leaderId does not reference an existing member');
    }
    const data = await this.prisma.ministry.update({ where: { id }, data: body, include: { leader: true } });
    return { success: true, data };
  }

  async deleteMinistry(id: string) {
    const existing = await this.prisma.ministry.findFirst({ where: { id, deletedAt: null } });
    if (!existing) throw new NotFoundError('Ministry not found');
    await this.prisma.$transaction([
      this.prisma.member.updateMany({ where: { ministryId: id }, data: { ministryId: null } }),
      this.prisma.ministry.update({ where: { id }, data: { deletedAt: new Date(), leaderId: null } }),
    ]);
    return { success: true };
  }

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

  async importCsv(records: any[], changedBy?: string) {
    const results: any[] = [];
    for (const record of records) {
      try {
        const status = ['ATIVO', 'INATIVO', 'AFASTADO', 'TRANSFERIDO', 'EXCLUIDO'].includes(record.status)
          ? record.status
          : 'ATIVO';
        const role = ['MEMBRO', 'DIACONO', 'PRESBITERO', 'PASTOR'].includes(record.role)
          ? record.role
          : 'MEMBRO';
        const created = await this.create({
          name: record.name,
          email: record.email,
          phone: record.phone,
          status,
          role,
          isBaptized: record.isBaptized === true || record.isBaptized === 'true' || record.isBaptized === 'sim',
          forceDuplicate: true,
        }, changedBy);
        results.push({ success: true, data: created.data });
      } catch (error: any) {
        results.push({ success: false, name: record.name, error: error.message });
      }
    }
    return { success: true, data: results };
  }
}
