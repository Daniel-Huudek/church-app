import { FastifyInstance, FastifyRequest } from 'fastify';
import { validate, parsePagination, authorize, authenticate, requireAuthUser } from '@church-app/shared';
import { z } from 'zod';
import { NotificationService } from './service';

const notificationSchema = z.object({
  type: z.enum(['SCHEDULE_REMINDER', 'ATTENDANCE_CONFIRMATION', 'GENERAL']),
  recipientId: z.string().uuid(),
  message: z.string().min(1),
  phone: z.string().min(1),
});

const bulkSchema = z.object({
  type: z.enum(['SCHEDULE_REMINDER', 'ATTENDANCE_CONFIRMATION', 'GENERAL']),
  recipients: z.array(z.object({
    recipientId: z.string().uuid(),
    phone: z.string().min(1),
  })).min(1),
  message: z.string().min(1),
});

const notifyRoles = authorize('ADMINISTRADOR', 'PASTOR', 'LIDER', 'FINANCEIRO');
const ELEVATED = new Set(['ADMINISTRADOR', 'PASTOR']);

export async function notificationRoutes(fastify: FastifyInstance) {
  const service = new NotificationService(fastify.prisma);

  fastify.addHook('preHandler', authenticate());

  // Own notifications only (JWT identity) — never dump all phones/messages
  fastify.get('/', async (request: FastifyRequest, _reply) => {
    const { page, limit } = parsePagination(request.query);
    const { userId } = requireAuthUser(request);
    return service.findAll({ page, limit, recipientId: userId, includePhone: false });
  });

  fastify.post('/', { preHandler: [notifyRoles] }, async (request: FastifyRequest, _reply) => {
    const body = validate(notificationSchema, request.body);
    return service.send(body);
  });

  fastify.post('/bulk', { preHandler: [notifyRoles] }, async (request: FastifyRequest, _reply) => {
    const body = validate(bulkSchema, request.body);
    return service.sendBulk(body);
  });

  fastify.get('/unread-count', async (request: FastifyRequest, _reply) => {
    const { userId } = requireAuthUser(request);
    return service.getUnreadCount(userId);
  });

  fastify.post('/read-all', async (request: FastifyRequest, _reply) => {
    const { userId } = requireAuthUser(request);
    return service.markAllAsRead(userId);
  });

  fastify.get('/history/:recipientId', async (request, _reply) => {
    const actor = requireAuthUser(request);
    return service.getHistory(
      (request.params as any).recipientId,
      actor.userId,
      ELEVATED.has(actor.role),
    );
  });
}
