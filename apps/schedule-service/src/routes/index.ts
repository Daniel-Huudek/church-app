import { FastifyInstance, FastifyRequest } from 'fastify';
import { validate, parsePagination } from '../shared';
import { z } from 'zod';
import { ScheduleService } from '../services/schedule.service';

const scheduleSchema = z.object({
  eventId: z.string().uuid(), ministryId: z.string().uuid(), date: z.string(), startTime: z.string(), endTime: z.string(),
  positions: z.array(z.object({ memberId: z.string().uuid(), position: z.string() })),
});

const confirmSchema = z.object({ scheduleId: z.string().uuid(), positionId: z.string().uuid(), confirmed: z.boolean() });

export async function scheduleRoutes(fastify: FastifyInstance) {
  const service = new ScheduleService(fastify.prisma);

  fastify.get('/', async (request: FastifyRequest, _reply) => {
    const { page, limit } = parsePagination(request.query);
    return service.findAll({ page, limit });
  });

  fastify.get('/:id', async (request: FastifyRequest<{ Params: { id: string } }>, _reply) => {
    return service.findById(request.params.id);
  });

  fastify.post('/', async (request: FastifyRequest, _reply) => {
    const body = validate(scheduleSchema, request.body);
    return service.create(body);
  });

  fastify.put('/:id', async (request: FastifyRequest<{ Params: { id: string } }>, _reply) => {
    const body = validate(scheduleSchema.partial(), request.body);
    return service.update(request.params.id, body);
  });

  fastify.delete('/:id', async (request: FastifyRequest<{ Params: { id: string } }>, _reply) => {
    return service.delete(request.params.id);
  });

  fastify.post('/confirm', async (request: FastifyRequest, _reply) => {
    const body = validate(confirmSchema, request.body);
    return service.confirmPresence(body);
  });

  fastify.post('/substitute', async (request: FastifyRequest, _reply) => {
    const { scheduleId, positionId, substituteMemberId } = request.body as any;
    return service.substitute(scheduleId, positionId, substituteMemberId);
  });

  fastify.get('/member/:memberId', async (request: FastifyRequest<{ Params: { memberId: string } }>, _reply) => {
    return service.findByMember(request.params.memberId);
  });

  fastify.get('/conflicts/:memberId', async (request: FastifyRequest<{ Params: { memberId: string } }>, _reply) => {
    return service.getConflicts(request.params.memberId);
  });
}