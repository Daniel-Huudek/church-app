import { FastifyInstance } from 'fastify';
import { authClient } from '../http-client';
import { z } from 'zod';
import { validate, getAuthHeader, requireRoles } from '@church-app/shared';

const profileUpdateSchema = z.object({
  name: z.string().min(1).optional(),
  email: z.string().email().optional(),
  avatar: z.string().optional(),
});

const userAdminUpdateSchema = profileUpdateSchema.extend({
  role: z.string().optional(),
});

const permissionsUpdateSchema = z.object({ permissions: z.array(z.string()) });

const adminRoles = requireRoles('ADMINISTRADOR', 'PASTOR');

export async function userRoutes(fastify: FastifyInstance) {
  fastify.get('/', { preHandler: [fastify.authenticate, adminRoles] }, async (_request, reply) => {
    try {
      const data = await authClient.get('/auth');
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({
        success: false,
        message: error.message || 'Failed to fetch users',
      });
    }
  });

  fastify.get<{ Params: { id: string } }>('/:id', { preHandler: [fastify.authenticate, adminRoles] }, async (request, reply) => {
    try {
      const data = await authClient.get(`/auth/${request.params.id}`);
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({
        success: false,
        message: error.message || 'Failed to fetch user',
      });
    }
  });

  fastify.put<{ Params: { id: string } }>('/:id', { preHandler: [fastify.authenticate, adminRoles] }, async (request, reply) => {
    try {
      const body = validate(userAdminUpdateSchema, request.body);
      const data = await authClient.put(`/auth/${request.params.id}`, body, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({
        success: false,
        message: error.message || 'Failed to update user',
      });
    }
  });

  // Self-service profile update: never allow role changes via /me
  fastify.put('/me', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const body = validate(profileUpdateSchema, request.body);
      const data = await authClient.put(`/auth/${request.user.userId}`, body, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({
        success: false,
        message: error.message || 'Failed to update profile',
      });
    }
  });

  fastify.put<{ Params: { id: string } }>('/:id/permissions', { preHandler: [fastify.authenticate, adminRoles] }, async (request, reply) => {
    try {
      const body = validate(permissionsUpdateSchema, request.body);
      const data = await authClient.put(`/auth/${request.params.id}/permissions`, body, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({
        success: false,
        message: error.message || 'Failed to update permissions',
      });
    }
  });
}
