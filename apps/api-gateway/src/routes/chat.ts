import { FastifyInstance } from 'fastify';
import { chatClient } from '../http-client';
import { getAuthHeader, validate } from '@church-app/shared';
import { z } from 'zod';

const messageSchema = z.object({ content: z.string().min(1) });
const directChatSchema = z.object({ participantId: z.string().uuid(), message: z.string().min(1).optional() });
const readSchema = z.object({ messageId: z.string().uuid().optional() });

export async function chatRoutes(fastify: FastifyInstance) {
  fastify.post('/ministry', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = { ...request.body as any, userId: request.user.userId };
    try {
      const data = await chatClient.post('/chats/ministry', body, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await chatClient.get(`/chats?userId=${request.user.userId}`, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/unread', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await chatClient.get(`/chats/unread?userId=${request.user.userId}`, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get<{ Params: { id: string } }>('/:id', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await chatClient.get(`/chats/${request.params.id}?userId=${request.user.userId}`, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get<{ Params: { id: string } }>('/:id/messages', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const { page, limit } = request.query as Record<string, string>;
    try {
      const data = await chatClient.get(`/chats/${request.params.id}/messages?userId=${request.user.userId}&page=${page || 1}&limit=${limit || 50}`, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post<{ Params: { id: string } }>('/:id/messages', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = { ...validate(messageSchema, request.body), userId: request.user.userId };
    try {
      const data = await chatClient.post(`/chats/${request.params.id}/messages`, body, getAuthHeader(request));
      await reply.status(201).send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/direct', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = { ...validate(directChatSchema, request.body), userId: request.user.userId };
    try {
      const data = await chatClient.post('/chats/direct', body, getAuthHeader(request));
      await reply.status(201).send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post<{ Params: { id: string } }>('/:id/read', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = { ...validate(readSchema, request.body), userId: request.user.userId };
    try {
      const data = await chatClient.post(`/chats/${request.params.id}/read`, body, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });
}


