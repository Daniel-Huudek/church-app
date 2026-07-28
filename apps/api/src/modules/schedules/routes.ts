import { FastifyInstance, FastifyRequest } from 'fastify';
import { validate, parsePagination, authenticate, requireAuthUser } from '@church-app/shared';
import { z } from 'zod';
import { ScheduleService } from './service';

const scheduleSchema = z.object({
  eventId: z.string().uuid(), ministryId: z.string().uuid(), date: z.string(), startTime: z.string(), endTime: z.string(),
  positions: z.array(z.object({ memberId: z.string().uuid(), position: z.string() })),
});

const confirmSchema = z.object({ scheduleId: z.string().uuid(), positionId: z.string().uuid(), confirmed: z.boolean() });

export async function scheduleRoutes(fastify: FastifyInstance) {
  const service = new ScheduleService(fastify.prisma);

  fastify.addHook('preHandler', authenticate());

  fastify.get('/', async (request: FastifyRequest, _reply) => {
    const { page, limit } = parsePagination(request.query);
    const { ministryId } = request.query as Record<string, string | undefined>;
    return service.findAll({ page, limit, ministryId });
  });

  // Static paths before /:id
  fastify.post('/confirm', async (request: FastifyRequest, _reply) => {
    const body = validate(confirmSchema, request.body);
    return service.confirmPresence(body);
  });

  fastify.post('/substitute', async (request: FastifyRequest, _reply) => {
    const { scheduleId, positionId, substituteMemberId } = request.body as { scheduleId?: string; positionId?: string; substituteMemberId?: string };
    return service.substitute(scheduleId, positionId, substituteMemberId);
  });

  fastify.get('/my-schedules', async (request: FastifyRequest, _reply) => {
    const { userId } = requireAuthUser(request);
    return service.findByMember(userId);
  });

  fastify.get('/member/:memberId', async (request, _reply) => {
    return service.findByMember((request.params as any).memberId);
  });

  fastify.get('/conflicts/:memberId', async (request, _reply) => {
    return service.getConflicts((request.params as any).memberId);
  });

  fastify.get('/:id', async (request, _reply) => {
    return service.findById((request.params as any).id);
  });

  fastify.post('/', async (request: FastifyRequest, _reply) => {
    const body = validate(scheduleSchema, request.body);
    return service.create(body);
  });

  fastify.put('/:id', async (request, _reply) => {
    const body = validate(scheduleSchema.partial(), request.body);
    return service.update((request.params as any).id, body);
  });

  fastify.delete('/:id', async (request, _reply) => {
    return service.delete((request.params as any).id);
  });
}