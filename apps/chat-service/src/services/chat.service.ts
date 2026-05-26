import { PrismaClient } from '@prisma/client';
import { AppError } from '@church-app/shared';

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
}
