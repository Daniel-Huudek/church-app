import { FastifyInstance, FastifyRequest } from 'fastify';
import { validate, parsePagination } from '@church-app/shared';
import { z } from 'zod';
import { EventService } from '../services/event.service';

const eventSchema = z.object({
  title: z.string().min(1), description: z.string().optional(), type: z.enum(['WORSHIP', 'EVENT', 'REHEARSAL']),
  date: z.string(), startTime: z.string(), endTime: z.string(), location: z.string().optional(),
  isRecurring: z.boolean().default(false), recurrenceRule: z.string().optional(),
});

export async function eventRoutes(fastify: FastifyInstance) {
  const service = new EventService(fastify.prisma);

  fastify.get('/', async (request: FastifyRequest, _reply) => {
    const { page, limit } = parsePagination(request.query);
    const { startDate, endDate, type } = request.query as Record<string, string | undefined>;
    return service.findAll({ page, limit, startDate, endDate, type });
  });

  fastify.get('/:id', async (request: FastifyRequest<{ Params: { id: string } }>, _reply) => service.findById(request.params.id));

  fastify.post('/', async (request: FastifyRequest, _reply) => {
    const body = validate(eventSchema, request.body);
    return service.create(body);
  });

  fastify.put('/:id', async (request: FastifyRequest<{ Params: { id: string } }>, _reply) => {
    const body = validate(eventSchema.partial(), request.body);
    return service.update(request.params.id, body);
  });

  fastify.delete('/:id', async (request: FastifyRequest<{ Params: { id: string } }>, _reply) => service.delete(request.params.id));

  fastify.get('/calendar', async (request: FastifyRequest, _reply) => {
    const { startDate, endDate } = request.query as Record<string, string | undefined>;
    return service.getCalendar(startDate, endDate);
  });
}