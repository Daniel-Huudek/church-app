import { FastifyInstance, FastifyRequest } from 'fastify';
import { validate, parsePagination } from '../shared';
import { z } from 'zod';
import { NotificationService } from '../services/notification.service';

const notificationSchema = z.object({
  type: z.enum(['SCHEDULE_REMINDER', 'ATTENDANCE_CONFIRMATION', 'GENERAL']),
  recipientId: z.string().uuid(), message: z.string().min(1), phone: z.string(),
});

const bulkSchema = z.object({
  type: z.enum(['SCHEDULE_REMINDER', 'ATTENDANCE_CONFIRMATION', 'GENERAL']),
  recipientIds: z.array(z.string().uuid()), message: z.string().min(1),
});

export async function notificationRoutes(fastify: FastifyInstance) {
  const service = new NotificationService(fastify.prisma);

  fastify.get('/', async (request: FastifyRequest, _reply) => {
    const { page, limit } = parsePagination(request.query);
    return service.findAll({ page, limit });
  });

  fastify.post('/', async (request: FastifyRequest, _reply) => {
    const body = validate(notificationSchema, request.body);
    return service.send(body);
  });

  fastify.post('/bulk', async (request: FastifyRequest, _reply) => {
    const body = validate(bulkSchema, request.body);
    return service.sendBulk(body);
  });

  fastify.get('/history/:recipientId', async (request: FastifyRequest<{ Params: { recipientId: string } }>, _reply) => {
    return service.getHistory(request.params.recipientId);
  });
}