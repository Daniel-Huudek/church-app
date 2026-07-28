import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { z } from 'zod';
import { validate, authenticate, authorize, requireAuthUser, assertUserAdminRole } from '@church-app/shared';
import { AuthService } from '../modules/auth/service.js';

const profileUpdateSchema = z.object({
  name: z.string().min(1).optional(),
  email: z.string().email().optional(),
  avatar: z.string().optional(),
});

const userAdminUpdateSchema = profileUpdateSchema.extend({
  role: z.string().optional(),
});

const permissionsUpdateSchema = z.object({ permissions: z.array(z.string()) });

const adminOnly = authorize('ADMINISTRADOR', 'PASTOR');
const requireAuth = authenticate();

/** Public `/users` API (formerly gateway → auth-service). */
export async function userRoutes(fastify: FastifyInstance) {
  const authService = new AuthService(fastify.prisma);

  fastify.get('/', { preHandler: [adminOnly] }, async (_request: FastifyRequest, reply: FastifyReply) => {
    const result = await authService.getAllUsers();
    return reply.send({ success: true, data: result });
  });

  fastify.put('/me', { preHandler: [requireAuth] }, async (request: FastifyRequest, reply: FastifyReply) => {
    const actor = requireAuthUser(request);
    const body = validate(profileUpdateSchema, request.body);
    const result = await authService.updateUser(actor.userId, body);
    return reply.send({ success: true, data: result });
  });

  fastify.get('/:id', { preHandler: [adminOnly] }, async (request, reply: FastifyReply) => {
    const result = await authService.getUserById((request.params as any).id);
    return reply.send({ success: true, data: result });
  });

  fastify.put('/:id', { preHandler: [adminOnly] }, async (request, reply: FastifyReply) => {
    const body = validate(userAdminUpdateSchema, request.body);
    const result = await authService.updateUser((request.params as any).id, body);
    return reply.send({ success: true, data: result });
  });

  fastify.put('/:id/permissions', { preHandler: [adminOnly] }, async (request, reply: FastifyReply) => {
    assertUserAdminRole(requireAuthUser(request).role);
    const body = validate(permissionsUpdateSchema, request.body);
    const result = await authService.setUserPermissions((request.params as any).id, body.permissions);
    return reply.send({ success: true, data: result });
  });
}
