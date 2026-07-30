import { PrismaClient } from '@prisma/client';
import { ForbiddenError, logger } from '@church-app/shared';

/** Strip phone from notification payloads for non-admin consumers. */
function sanitizeNotification<T extends Record<string, unknown>>(notification: T, includePhone: boolean): T {
  if (includePhone) return notification;
  const { phone: _, ...rest } = notification as T & { phone?: unknown };
  void _;
  return rest as T;
}

export class NotificationService {
  private evolutionApiUrl: string;
  private evolutionApiKey: string;

  constructor(private prisma: PrismaClient) {
    this.evolutionApiUrl = process.env.EVOLUTION_API_URL || 'http://evolution-api:8080';
    this.evolutionApiKey = process.env.EVOLUTION_API_KEY || '';
  }

  async findAll({
    page = 1,
    limit = 20,
    recipientId,
    includePhone = false,
  }: {
    page?: number;
    limit?: number;
    recipientId: string;
    includePhone?: boolean;
  }) {
    const skip = (page - 1) * limit;
    const where = { recipientId };
    const [data, total] = await Promise.all([
      this.prisma.notification.findMany({ where, skip, take: limit, orderBy: { createdAt: 'desc' } }),
      this.prisma.notification.count({ where }),
    ]);
    return {
      success: true,
      data: {
        data: data.map((n) => sanitizeNotification(n, includePhone)),
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async send(body: { type: string; recipientId: string; phone: string; message: string }) {
    const notification = await this.prisma.notification.create({
      data: { type: body.type as any, recipientId: body.recipientId, phone: body.phone, message: body.message, status: 'PENDING' },
    });

    try {
      await this.sendWhatsAppMessage(body.phone, body.message);
      await this.prisma.notification.update({ where: { id: notification.id }, data: { status: 'SENT', sentAt: new Date() } });
      logger.info('WhatsApp message sent', { notificationId: notification.id });
      return { success: true, data: sanitizeNotification(notification, false) };
    } catch (error) {
      logger.error('Failed to send WhatsApp message', error as Error);
      await this.prisma.notification.update({ where: { id: notification.id }, data: { status: 'FAILED' } });
      return { success: false, message: 'Failed to send notification' };
    }
  }

  async sendBulk(body: { type: string; recipients: { recipientId: string; phone: string }[]; message: string }) {
    const results = await Promise.all(
      body.recipients.map(r => this.send({ type: body.type, recipientId: r.recipientId, phone: r.phone, message: body.message }))
    );
    return { success: true, data: { sent: results.filter(r => r.success).length, failed: results.filter(r => !r.success).length } };
  }

  async getHistory(recipientId: string, actorUserId: string, isElevated: boolean) {
    if (!isElevated && recipientId !== actorUserId) {
      throw new ForbiddenError('Cannot view another user\'s notification history');
    }
    const data = await this.prisma.notification.findMany({
      where: { recipientId },
      orderBy: { createdAt: 'desc' },
    });
    return { success: true, data: data.map((n) => sanitizeNotification(n, isElevated)) };
  }

  async getUnreadCount(recipientId: string) {
    const unread = await this.prisma.notification.count({
      where: { recipientId, isRead: false },
    });
    return { success: true, data: { unread } };
  }

  async markAllAsRead(recipientId: string) {
    await this.prisma.notification.updateMany({
      where: { recipientId, isRead: false },
      data: { isRead: true },
    });
    return { success: true };
  }

  private async sendWhatsAppMessage(phone: string, message: string) {
    const response = await fetch(`${this.evolutionApiUrl}/message/sendText/default`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'apikey': this.evolutionApiKey },
      body: JSON.stringify({ number: phone, text: message }),
    });
    if (!response.ok) throw new Error('Evolution API request failed');
    return response.json();
  }
}
