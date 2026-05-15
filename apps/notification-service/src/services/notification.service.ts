import { PrismaClient } from '@prisma/client';
import { logger } from '../logger';

export class NotificationService {
  private evolutionApiUrl: string;
  private evolutionApiKey: string;

  constructor(private prisma: PrismaClient) {
    this.evolutionApiUrl = process.env.EVOLUTION_API_URL || 'http://evolution-api:8080';
    this.evolutionApiKey = process.env.EVOLUTION_API_KEY || '';
  }

  async findAll({ page = 1, limit = 20 }: { page?: number; limit?: number }) {
    const skip = (page - 1) * limit;
    const [data, total] = await Promise.all([
      this.prisma.notification.findMany({ skip, take: limit, orderBy: { createdAt: 'desc' } }),
      this.prisma.notification.count(),
    ]);
    return { success: true, data: { data, total, page, limit, totalPages: Math.ceil(total / limit) } };
  }

  async send(body: { type: string; recipientId: string; phone: string; message: string }) {
    const notification = await this.prisma.notification.create({
      data: { type: body.type as any, recipientId: body.recipientId, phone: body.phone, message: body.message, status: 'PENDING' },
    });

    try {
      const result = await this.sendWhatsAppMessage(body.phone, body.message);
      await this.prisma.notification.update({ where: { id: notification.id }, data: { status: 'SENT', sentAt: new Date() } });
      logger.info('WhatsApp message sent', { notificationId: notification.id, phone: body.phone });
      return { success: true, data: notification };
    } catch (error) {
      logger.error('Failed to send WhatsApp message', error as Error);
      await this.prisma.notification.update({ where: { id: notification.id }, data: { status: 'FAILED' } });
      return { success: false, message: 'Failed to send notification' };
    }
  }

  async sendBulk(body: { type: string; recipientIds: string[]; message: string }) {
    const members = await this.prisma.member.findMany({ where: { id: { in: body.recipientIds } } });
    const results = await Promise.all(
      members.map(m => this.send({ type: body.type, recipientId: m.id, phone: m.phone, message: body.message }))
    );
    return { success: true, data: { sent: results.filter(r => r.success).length, failed: results.filter(r => !r.success).length } };
  }

  async getHistory(recipientId: string) {
    const data = await this.prisma.notification.findMany({ where: { recipientId }, orderBy: { createdAt: 'desc' } });
    return { success: true, data };
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