import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { authenticate, requireAuthUser } from '@church-app/shared';
import { ChatService } from '../services/chat.service.js';

export async function chatRoutes(fastify: FastifyInstance) {
  const chatService = new ChatService(fastify.prisma);

  // Prefer JWT identity over client-supplied userId
  fastify.addHook('preHandler', authenticate());

  fastify.post('/ministry', async (request: FastifyRequest, reply: FastifyReply) => {
    const { userId } = requireAuthUser(request);
    const { ministry } = request.body as { ministry?: string };
    if (!ministry) return reply.status(400).send({ success: false, message: 'ministry is required' });
    try {
      const room = await chatService.findOrCreateMinistryRoom(ministry, userId);
      return reply.send({ success: true, data: room });
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/', async (request: FastifyRequest, reply: FastifyReply) => {
    const { userId } = requireAuthUser(request);
    try {
      const rooms = await chatService.listRooms(userId);
      return reply.send({ success: true, data: rooms });
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/unread', async (request: FastifyRequest, reply: FastifyReply) => {
    const { userId } = requireAuthUser(request);
    try {
      const count = await chatService.getUnreadCount(userId);
      return reply.send({ success: true, data: { unread: count } });
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/:id', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const { userId } = requireAuthUser(request);
    try {
      const room = await chatService.getRoom(request.params.id, userId);
      return reply.send({ success: true, data: room });
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/:id/messages', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const { userId } = requireAuthUser(request);
    const { page = '1', limit = '50' } = request.query as Record<string, string>;
    try {
      const result = await chatService.getMessages(request.params.id, userId, parseInt(page), parseInt(limit));
      return reply.send({ success: true, data: result.messages, total: result.total, page: result.page, limit: result.limit });
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/:id/messages', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const { userId } = requireAuthUser(request);
    const { content, type } = request.body as { content?: string; type?: string };
    if (!content) return reply.status(400).send({ success: false, message: 'content is required' });
    try {
      const message = await chatService.sendMessage(request.params.id, userId, content, type);
      return reply.status(201).send({ success: true, data: message });
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/direct', async (request: FastifyRequest, reply: FastifyReply) => {
    const { userId } = requireAuthUser(request);
    const body = request.body as { otherUserId?: string; participantId?: string };
    const otherUserId = body.otherUserId || body.participantId;
    if (!otherUserId) return reply.status(400).send({ success: false, message: 'otherUserId is required' });
    try {
      const room = await chatService.createDirectRoom(userId, otherUserId);
      return reply.status(201).send({ success: true, data: room });
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/:id/read', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const { userId } = requireAuthUser(request);
    try {
      await chatService.markAsRead(request.params.id, userId);
      return reply.send({ success: true });
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });
}
