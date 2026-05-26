import { FastifyInstance } from 'fastify';
import { authClient } from '../http-client';
import { z } from 'zod';
import { validate, getAuthHeader } from '@church-app/shared';

const userUpdateSchema = z.object({
  role: z.string().optional(),
  name: z.string().min(1).optional(),
  email: z.string().email().optional(),
  avatar: z.string().optional(),
});
const permissionsUpdateSchema = z.object({ permissions: z.array(z.string()) });

export async function userRoutes(fastify: FastifyInstance) {
  fastify.get('/', { preHandler: [fastify.authenticate] }, async (_request, reply) => {
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

  fastify.get<{ Params: { id: string } }>('/:id', { preHandler: [fastify.authenticate] }, async (request, reply) => {
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

  fastify.put<{ Params: { id: string } }>('/:id', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const body = validate(userUpdateSchema, request.body);
      const data = await authClient.put(`/auth/${request.params.id}`, body, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({
        success: false,
        message: error.message || 'Failed to update user',
      });
    }
  });

  fastify.put('/me', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const body = validate(userUpdateSchema, request.body);
      const data = await authClient.put(`/auth/${request.user.userId}`, body, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({
        success: false,
        message: error.message || 'Failed to update profile',
      });
    }
  });

  fastify.put<{ Params: { id: string } }>('/:id/permissions', { preHandler: [fastify.authenticate] }, async (request, reply) => {
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

