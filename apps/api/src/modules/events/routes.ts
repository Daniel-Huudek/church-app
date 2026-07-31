import { FastifyInstance, FastifyRequest } from 'fastify';
import { validate, parsePagination, authenticate, authorizePermissions, requireAuthUser } from '@church-app/shared';
import { z } from 'zod';
import { EventService } from './service';

const eventSchema = z.object({
  title: z.string().min(1), description: z.string().optional(), type: z.enum(['WORSHIP', 'EVENT', 'REHEARSAL']),
  date: z.string(), startTime: z.string(), endTime: z.string(), location: z.string().optional(),
  isRecurring: z.boolean().default(false), recurrenceRule: z.string().optional(),
});

const canRead = authorizePermissions('events_read');
const canWrite = authorizePermissions('events_write');
const canDelete = authorizePermissions('events_delete', 'events_write');

export async function eventRoutes(fastify: FastifyInstance) {
  const service = new EventService(fastify.prisma);

  fastify.addHook('preHandler', authenticate());

  fastify.get('/', { preHandler: [canRead] }, async (request: FastifyRequest, _reply) => {
    const { page, limit } = parsePagination(request.query);
    const { startDate, endDate, type } = request.query as Record<string, string | undefined>;
    return service.findAll({ page, limit, startDate, endDate, type });
  });

  // Static path before /:id
  fastify.get('/calendar', { preHandler: [canRead] }, async (request: FastifyRequest, _reply) => {
    const { startDate, endDate } = request.query as Record<string, string | undefined>;
    return service.getCalendar(startDate, endDate);
  });

  fastify.get('/:id', { preHandler: [canRead] }, async (request, _reply) => service.findById((request.params as any).id));

  fastify.post('/', { preHandler: [canWrite] }, async (request: FastifyRequest, _reply) => {
    const { userId, role } = requireAuthUser(request);
    const body = validate(eventSchema, request.body);
    return service.create(body, { userId, role });
  });

  fastify.put('/:id', { preHandler: [canWrite] }, async (request, _reply) => {
    const { userId, role } = requireAuthUser(request);
    const body = validate(eventSchema.partial(), request.body);
    return service.update((request.params as any).id, body, { userId, role });
  });

  fastify.delete('/:id', { preHandler: [canDelete] }, async (request, _reply) => {
    const { userId, role } = requireAuthUser(request);
    return service.delete((request.params as any).id, { userId, role });
  });
}
