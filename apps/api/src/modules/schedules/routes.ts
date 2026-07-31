import { FastifyInstance, FastifyRequest } from 'fastify';
import {
  validate,
  parsePagination,
  authenticate,
  authorizePermissions,
  requireAuthUser,
  userHasPermission,
  ForbiddenError,
} from '@church-app/shared';
import { z } from 'zod';
import { ScheduleService } from './service';

const scheduleSchema = z.object({
  eventId: z.string().uuid(), ministryId: z.string().uuid(), date: z.string(), startTime: z.string(), endTime: z.string(),
  positions: z.array(z.object({ memberId: z.string().uuid(), position: z.string() })),
});

const confirmSchema = z.object({ scheduleId: z.string().uuid(), positionId: z.string().uuid(), confirmed: z.boolean() });

const canRead = authorizePermissions('schedules_read');
const canWrite = authorizePermissions('schedules_write');
const canDelete = authorizePermissions('schedules_delete', 'schedules_write');

export async function scheduleRoutes(fastify: FastifyInstance) {
  const service = new ScheduleService(fastify.prisma);

  fastify.addHook('preHandler', authenticate());

  fastify.get('/', { preHandler: [canRead] }, async (request: FastifyRequest, _reply) => {
    const { page, limit } = parsePagination(request.query);
    const { ministryId } = request.query as Record<string, string | undefined>;
    return service.findAll({ page, limit, ministryId });
  });

  // Static paths before /:id
  fastify.post('/confirm', { preHandler: [canRead] }, async (request: FastifyRequest, _reply) => {
    const actor = requireAuthUser(request);
    const body = validate(confirmSchema, request.body);
    const canManage = userHasPermission(actor, 'schedules_write');
    if (!canManage) {
      const self = await fastify.prisma.member.findFirst({
        where: { userId: actor.userId, deletedAt: null },
        select: { id: true },
      });
      const position = await fastify.prisma.schedulePosition.findFirst({
        where: { id: body.positionId, scheduleId: body.scheduleId },
        select: { memberId: true },
      });
      if (!self || !position || position.memberId !== self.id) {
        throw new ForbiddenError('Can only confirm your own schedule position');
      }
    }
    return service.confirmPresence(body);
  });

  fastify.post('/substitute', { preHandler: [canWrite] }, async (request: FastifyRequest, _reply) => {
    const { scheduleId, positionId, substituteMemberId } = request.body as { scheduleId?: string; positionId?: string; substituteMemberId?: string };
    return service.substitute(scheduleId, positionId, substituteMemberId);
  });

  fastify.get('/my-schedules', { preHandler: [canRead] }, async (request: FastifyRequest, _reply) => {
    const { userId } = requireAuthUser(request);
    const member = await fastify.prisma.member.findFirst({
      where: { userId, deletedAt: null },
      select: { id: true },
    });
    if (!member) return { success: true, data: [] };
    return service.findByMember(member.id);
  });

  fastify.get('/member/:memberId', { preHandler: [canRead] }, async (request, _reply) => {
    const actor = requireAuthUser(request);
    const memberId = (request.params as any).memberId as string;
    const canManage = userHasPermission(actor, 'schedules_write');
    if (!canManage) {
      const self = await fastify.prisma.member.findFirst({
        where: { userId: actor.userId, deletedAt: null },
        select: { id: true },
      });
      if (!self || self.id !== memberId) {
        throw new ForbiddenError('Cannot view another member\'s schedules');
      }
    }
    return service.findByMember(memberId);
  });

  fastify.get('/conflicts/:memberId', { preHandler: [canRead] }, async (request, _reply) => {
    const actor = requireAuthUser(request);
    const memberId = (request.params as any).memberId as string;
    const canManage = userHasPermission(actor, 'schedules_write');
    if (!canManage) {
      const self = await fastify.prisma.member.findFirst({
        where: { userId: actor.userId, deletedAt: null },
        select: { id: true },
      });
      if (!self || self.id !== memberId) {
        throw new ForbiddenError('Cannot view another member\'s schedule conflicts');
      }
    }
    return service.getConflicts(memberId);
  });

  fastify.get('/:id', { preHandler: [canRead] }, async (request, _reply) => {
    return service.findById((request.params as any).id);
  });

  fastify.post('/', { preHandler: [canWrite] }, async (request: FastifyRequest, _reply) => {
    const { userId, role } = requireAuthUser(request);
    const body = validate(scheduleSchema, request.body);
    return service.create(body, { userId, role });
  });

  fastify.put('/:id', { preHandler: [canWrite] }, async (request, _reply) => {
    const { userId, role } = requireAuthUser(request);
    const body = validate(scheduleSchema.partial(), request.body);
    return service.update((request.params as any).id, body, { userId, role });
  });

  fastify.delete('/:id', { preHandler: [canDelete] }, async (request, _reply) => {
    const { userId, role } = requireAuthUser(request);
    return service.delete((request.params as any).id, { userId, role });
  });
}
