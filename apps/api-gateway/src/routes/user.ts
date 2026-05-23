import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { authClient } from '../http-client';
import { z } from 'zod';
import { validate } from '../shared';

const userUpdateSchema = z.object({ role: z.string() });
const permissionsUpdateSchema = z.object({ permissions: z.array(z.string()) });

export async function userRoutes(fastify: FastifyInstance) {
  fastify.get('/', async (request: any, reply: FastifyReply) => {
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

  fastify.get('/:id', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
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

  fastify.put('/:id', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
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

  fastify.put('/:id/permissions', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
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

  fastify.get('/roles', async (_request, reply) => {
    try {
      const data = await authClient.get('/auth/roles');
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({
        success: false,
        message: error.message || 'Failed to fetch roles',
      });
    }
  });

  fastify.put('/roles/:name', async (request: FastifyRequest<{ Params: { name: string } }>, reply) => {
    try {
      const data = await authClient.put(`/auth/roles/${request.params.name}`, request.body);
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({
        success: false,
        message: error.message || 'Failed to update role',
      });
    }
  });

  fastify.post('/roles/reset', async (_request, reply) => {
    try {
      const data = await authClient.post('/auth/roles/reset');
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({
        success: false,
        message: error.message || 'Failed to reset roles',
      });
    }
  });
}