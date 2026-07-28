import { FastifyInstance } from 'fastify';
import { authenticate, authorize, requireAuthUser, validate } from '@church-app/shared';
import { WebsiteService } from './service.js';
import { websiteContentSchema } from './schema.js';

export async function websiteRoutes(fastify: FastifyInstance) {
  const service = new WebsiteService(fastify.prisma);

  // Public — site institucional
  fastify.get('/', async () => {
    const data = await service.getPublic();
    return { success: true, data };
  });

  await fastify.register(async (secured) => {
    secured.addHook('preHandler', authenticate());
    const adminOnly = authorize('ADMINISTRADOR', 'PASTOR');

    secured.get('/admin', { preHandler: [adminOnly] }, async () => {
      const data = await service.getPublic();
      return { success: true, data };
    });

    secured.put('/', { preHandler: [adminOnly] }, async (request) => {
      const { userId } = requireAuthUser(request);
      const body = validate(websiteContentSchema, request.body);
      const data = await service.upsert(body, userId);
      return { success: true, data };
    });
  });
}
