import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { authClient } from '../http-client';
import { z } from 'zod';
import { validate } from '../shared';

const userUpdateSchema = z.object({ role: z.string() });
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

  fastify.put('/:id', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    try {
      const body = validate(userUpdateSchema, request.body);
      const data = await authClient.put(`/auth/${request.params.id}`, body);
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({
        success: false,
        message: error.message || 'Failed to update user',
      });
    }
  });

  fastify.put('/:id/permissions', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    try {
      const body = validate(permissionsUpdateSchema, request.body);
      const data = await authClient.put(`/auth/${request.params.id}/permissions`, body);
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({
        success: false,
        message: error.message || 'Failed to update permissions',
      });
    }
  });
}