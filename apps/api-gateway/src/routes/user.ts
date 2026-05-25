import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { authClient } from '../http-client';
import { z } from 'zod';
import { validate } from '@church-app/shared';

const userUpdateSchema = z.object({
  role: z.string().optional(),
  name: z.string().min(1).optional(),
  email: z.string().email().optional(),
  avatar: z.string().optional(),
});
const permissionsUpdateSchema = z.object({ permissions: z.array(z.string()) });

export async function userRoutes(fastify: FastifyInstance) {
  fastify.get('/', { preHandler: [fastify.authenticate] }, async (request: any, reply: FastifyReply) => {
    try {
      const data = await authClient.get('/auth');
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({
        success: false,
        message: error.message || 'Failed to fetch users',
      });
    }
  });

  fastify.get('/:id', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    try {
      const data = await authClient.get(`/auth/${request.params.id}`);
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({
        success: false,
        message: error.message || 'Failed to fetch user',
      });
    }
  });

  fastify.put('/:id', { preHandler: [fastify.authenticate] }, async (request: any, reply: FastifyReply) => {
    try {
      const body = validate(userUpdateSchema, request.body);
      const data = await authClient.put(`/auth/${request.params.id}`, body, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({
        success: false,
        message: error.message || 'Failed to update user',
      });
    }
  });

  fastify.put('/me', { preHandler: [fastify.authenticate] }, async (request: any, reply: FastifyReply) => {
    try {
      const body = validate(userUpdateSchema, request.body);
      const data = await authClient.put(`/auth/${request.user.userId}`, body, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({
        success: false,
        message: error.message || 'Failed to update profile',
      });
    }
  });

  fastify.put('/:id/permissions', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    try {
      const body = validate(permissionsUpdateSchema, request.body);
      const data = await authClient.put(`/auth/${request.params.id}/permissions`, body, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({
        success: false,
        message: error.message || 'Failed to update permissions',
      });
    }
  });
}

function getAuthHeader(request: FastifyRequest): Record<string, string> {
  return { Authorization: request.headers.authorization as string };
}