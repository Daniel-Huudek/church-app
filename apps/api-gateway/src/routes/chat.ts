import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { chatClient } from '../http-client';

export async function chatRoutes(fastify: FastifyInstance) {
  fastify.get('/', { preHandler: [fastify.authenticate] }, async (request: any, reply: FastifyReply) => {
    try {
      const data = await chatClient.get(`/chats?userId=${request.user.userId}`, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/unread', { preHandler: [fastify.authenticate] }, async (request: any, reply: FastifyReply) => {
    try {
      const data = await chatClient.get(`/chats/unread?userId=${request.user.userId}`, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/:id', { preHandler: [fastify.authenticate] }, async (request: any, reply: FastifyReply) => {
    try {
      const data = await chatClient.get(`/chats/${request.params.id}?userId=${request.user.userId}`, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/:id/messages', { preHandler: [fastify.authenticate] }, async (request: any, reply: FastifyReply) => {
    const { page, limit } = request.query as Record<string, string>;
    try {
      const data = await chatClient.get(`/chats/${request.params.id}/messages?userId=${request.user.userId}&page=${page || 1}&limit=${limit || 50}`, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/:id/messages', { preHandler: [fastify.authenticate] }, async (request: any, reply: FastifyReply) => {
    try {
      const body = { ...(request.body as object), userId: request.user.userId };
      const data = await chatClient.post(`/chats/${request.params.id}/messages`, body, getAuthHeader(request));
      return reply.status(201).send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/direct', { preHandler: [fastify.authenticate] }, async (request: any, reply: FastifyReply) => {
    try {
      const body = { ...(request.body as object), userId: request.user.userId };
      const data = await chatClient.post('/chats/direct', body, getAuthHeader(request));
      return reply.status(201).send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/:id/read', { preHandler: [fastify.authenticate] }, async (request: any, reply: FastifyReply) => {
    try {
      const body = { ...(request.body as object), userId: request.user.userId };
      const data = await chatClient.post(`/chats/${request.params.id}/read`, body, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });
}

function getAuthHeader(request: FastifyRequest): Record<string, string> {
  return { Authorization: request.headers.authorization as string };
}
