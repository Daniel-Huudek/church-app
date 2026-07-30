import { PrismaClient } from '@prisma/client';
import { AppError, ForbiddenError } from '@church-app/shared';

const ELEVATED_ROLES = new Set(['ADMINISTRADOR', 'PASTOR']);

function normalizeMinistryKey(name: string): string {
  return name
    .toLowerCase()
    .normalize('NFD')
    .replace(/\p{M}/gu, '');
}

function roleAllowsMinistry(role: string, ministryName: string): boolean {
  const name = normalizeMinistryKey(ministryName);
  if (name.includes('louvor')) {
    return role === 'LIDER_LOUVOR' || role === 'LOUVOR' || role === 'LIDER';
  }
  if (name.includes('diacon')) {
    return role === 'LIDER_DIACONOS' || role === 'DIACONO' || role === 'LIDER';
  }
  return role === 'LIDER';
}

export class ChatService {
  constructor(private prisma: PrismaClient) {}

  async listRooms(userId: string) {
    return this.prisma.chatRoom.findMany({
      where: {
        members: { some: { userId } },
        deletedAt: null,
      },
      include: {
        members: {
          include: { room: false },
        },
        _count: { select: { messages: true } },
      },
      orderBy: { updatedAt: 'desc' },
    });
  }

  async getRoom(roomId: string, userId: string) {
    const room = await this.prisma.chatRoom.findFirst({
      where: {
        id: roomId,
        members: { some: { userId } },
        deletedAt: null,
      },
      include: {
        members: true,
      },
    });
    if (!room) throw new AppError('Chat room not found', 404);
    return room;
  }

  async getMessages(roomId: string, userId: string, page: number, limit: number) {
    await this.getRoom(roomId, userId);
    const messages = await this.prisma.chatMessage.findMany({
      where: { roomId, deletedAt: null },
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * limit,
      take: limit,
    });
    const total = await this.prisma.chatMessage.count({
      where: { roomId, deletedAt: null },
    });
    return { messages: messages.reverse(), total, page, limit };
  }

  async sendMessage(roomId: string, userId: string, content: string, type: string = 'TEXT') {
    await this.getRoom(roomId, userId);
    const message = await this.prisma.chatMessage.create({
      data: { roomId, senderId: userId, content, type: type as any },
    });
    await this.prisma.chatRoom.update({
      where: { id: roomId },
      data: { updatedAt: new Date() },
    });
    await this.prisma.chatRoomMember.updateMany({
      where: { roomId, userId: { not: userId } },
      data: { unreadCount: { increment: 1 } },
    });
    return message;
  }

  async createDirectRoom(userId: string, otherUserId: string) {
    const existing = await this.prisma.chatRoom.findFirst({
      where: {
        type: 'DIRECT',
        deletedAt: null,
        members: {
          every: { userId: { in: [userId, otherUserId] } },
        },
      },
    });
    if (existing) return existing;
    const room = await this.prisma.chatRoom.create({
      data: {
        type: 'DIRECT',
        members: {
          createMany: {
            data: [
              { userId, unreadCount: 0 },
              { userId: otherUserId, unreadCount: 0 },
            ],
          },
        },
      },
    });
    return room;
  }

  async markAsRead(roomId: string, userId: string) {
    await this.prisma.chatRoomMember.updateMany({
      where: { roomId, userId },
      data: { unreadCount: 0 },
    });
  }

  async getUnreadCount(userId: string) {
    const result = await this.prisma.chatRoomMember.aggregate({
      where: { userId },
      _sum: { unreadCount: true },
    });
    return result._sum.unreadCount ?? 0;
  }

  /** Ensures the user belongs to the ministry (or elevated/role match) before joining chat. */
  private async assertMinistryAccess(ministryName: string, userId: string) {
    const user = await this.prisma.user.findFirst({
      where: { id: userId, deletedAt: null },
      select: { id: true, role: true },
    });
    if (!user) throw new ForbiddenError('User not found');
    if (ELEVATED_ROLES.has(user.role)) return;

    if (roleAllowsMinistry(user.role, ministryName)) return;

    const ministry = await this.prisma.ministry.findFirst({
      where: { name: ministryName, deletedAt: null },
      select: { id: true },
    });
    if (!ministry) {
      throw new ForbiddenError('Not authorized to join this ministry chat');
    }

    const member = await this.prisma.member.findFirst({
      where: {
        userId,
        deletedAt: null,
        OR: [
          { ministryId: ministry.id },
          { memberMinistries: { some: { ministryId: ministry.id } } },
        ],
      },
      select: { id: true },
    });
    if (!member) {
      throw new ForbiddenError('Not authorized to join this ministry chat');
    }
  }

  async findOrCreateMinistryRoom(ministry: string, userId: string) {
    await this.assertMinistryAccess(ministry, userId);

    let room = await this.prisma.chatRoom.findFirst({
      where: { name: ministry, type: 'MINISTRY', deletedAt: null },
      include: { members: true },
    });
    if (!room) {
      room = await this.prisma.chatRoom.create({
        data: {
          name: ministry,
          type: 'MINISTRY',
          members: {
            create: { userId, unreadCount: 0 },
          },
        },
        include: { members: true },
      });
    } else {
      const isMember = room.members.some(m => m.userId === userId);
      if (!isMember) {
        await this.prisma.chatRoomMember.create({
          data: { roomId: room.id, userId, unreadCount: 0 },
        });
        room = await this.prisma.chatRoom.findFirstOrThrow({
          where: { id: room.id },
          include: { members: true },
        });
      }
    }
    return room;
  }
}
