import { FastifyInstance, FastifyRequest } from 'fastify';
import { validate, parsePagination, authorize } from '@church-app/shared';
import { z } from 'zod';
import { NotificationService } from '../services/notification.service';

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

export async function notificationRoutes(fastify: FastifyInstance) {
  const service = new NotificationService(fastify.prisma);

  fastify.get('/', async (request: FastifyRequest, _reply) => {
    const { page, limit } = parsePagination(request.query);
    return service.findAll({ page, limit });
  });

  fastify.post('/', { preHandler: [notifyRoles] }, async (request: FastifyRequest, _reply) => {
    const body = validate(notificationSchema, request.body);
    return service.send(body);
  });

  fastify.post('/bulk', { preHandler: [notifyRoles] }, async (request: FastifyRequest, _reply) => {
    const body = validate(bulkSchema, request.body);
    return service.sendBulk(body);
  });

  fastify.get('/history/:recipientId', async (request: FastifyRequest<{ Params: { recipientId: string } }>, _reply) => {
    return service.getHistory(request.params.recipientId);
  });
}
