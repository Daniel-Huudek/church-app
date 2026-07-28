import { FastifyInstance, FastifyRequest } from 'fastify';
import { validate, parsePagination, authenticate } from '@church-app/shared';
import { z } from 'zod';
import { EventService } from './service';

const eventSchema = z.object({
  title: z.string().min(1), description: z.string().optional(), type: z.enum(['WORSHIP', 'EVENT', 'REHEARSAL']),
  date: z.string(), startTime: z.string(), endTime: z.string(), location: z.string().optional(),
  isRecurring: z.boolean().default(false), recurrenceRule: z.string().optional(),
});

export async function eventRoutes(fastify: FastifyInstance) {
  const service = new EventService(fastify.prisma);

  fastify.addHook('preHandler', authenticate());

  fastify.get('/', async (request: FastifyRequest, _reply) => {
    const { page, limit } = parsePagination(request.query);
    const { startDate, endDate, type } = request.query as Record<string, string | undefined>;
    return service.findAll({ page, limit, startDate, endDate, type });
  });

  // Static path before /:id
  fastify.get('/calendar', async (request: FastifyRequest, _reply) => {
    const { startDate, endDate } = request.query as Record<string, string | undefined>;
    return service.getCalendar(startDate, endDate);
  });

  fastify.get('/:id', async (request, _reply) => service.findById((request.params as any).id));

  fastify.post('/', async (request: FastifyRequest, _reply) => {
    const body = validate(eventSchema, request.body);
    return service.create(body);
  });

  fastify.put('/:id', async (request, _reply) => {
    const body = validate(eventSchema.partial(), request.body);
    return service.update((request.params as any).id, body);
  });

  fastify.delete('/:id', async (request, _reply) => service.delete((request.params as any).id));
}