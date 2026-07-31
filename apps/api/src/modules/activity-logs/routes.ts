import { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';
import { authenticate, authorize, parsePagination } from '@church-app/shared';
import { ActivityLogService } from './service.js';
import { ACTIVITY_DOMAINS } from './writer.js';

export async function activityLogRoutes(fastify: FastifyInstance) {
  const service = new ActivityLogService(fastify.prisma);
  const adminOnly = authorize('ADMINISTRADOR', 'PASTOR');

  fastify.addHook('preHandler', authenticate());

  /** Lista o feed unificado de auditoria (membros, financeiro, eventos, escalas, orações). */
  fastify.get('/', { preHandler: [adminOnly] }, async (request: FastifyRequest, reply: FastifyReply) => {
    const { page, limit } = parsePagination(request.query);
    const query = request.query as Record<string, string | undefined>;
    const data = await service.list({
      page,
      limit,
      domain: query.domain,
      action: query.action,
      from: query.from,
      to: query.to,
    });
    return reply.send(data);
  });

  fastify.get('/domains', { preHandler: [adminOnly] }, async (_request, reply: FastifyReply) => {
    return reply.send({ success: true, data: ACTIVITY_DOMAINS });
  });
}
