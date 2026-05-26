import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { ChatService } from '../services/chat.service.js';

export async function chatRoutes(fastify: FastifyInstance) {
  const chatService = new ChatService(fastify.prisma);

  fastify.post('/ministry', async (request: FastifyRequest, reply: FastifyReply) => {
    const { ministry, userId } = request.body as { ministry: string; userId: string };
    if (!ministry || !userId) return reply.status(400).send({ success: false, message: 'ministry and userId are required' });
    try {
      const room = await chatService.findOrCreateMinistryRoom(ministry, userId);
      return reply.send({ success: true, data: room });
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/', async (request: FastifyRequest, reply: FastifyReply) => {
    const { userId } = request.query as { userId: string };
    if (!userId) return reply.status(400).send({ success: false, message: 'userId is required' });
    try {
      const rooms = await chatService.listRooms(userId);
      return reply.send({ success: true, data: rooms });
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/unread', async (request: FastifyRequest, reply: FastifyReply) => {
    const { userId } = request.query as { userId: string };
    if (!userId) return reply.status(400).send({ success: false, message: 'userId is required' });
    try {
      const count = await chatService.getUnreadCount(userId);
      return reply.send({ success: true, data: { unread: count } });
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/:id', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const { userId } = request.query as { userId: string };
    if (!userId) return reply.status(400).send({ success: false, message: 'userId is required' });
    try {
      const room = await chatService.getRoom(request.params.id, userId);
      return reply.send({ success: true, data: room });
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/:id/messages', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const { userId, page = '1', limit = '50' } = request.query as Record<string, string>;
    if (!userId) return reply.status(400).send({ success: false, message: 'userId is required' });
    try {
      const result = await chatService.getMessages(request.params.id, userId, parseInt(page), parseInt(limit));
      return reply.send({ success: true, data: result.messages, total: result.total, page: result.page, limit: result.limit });
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/:id/messages', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const { userId, content, type } = request.body as { userId: string; content: string; type?: string };
    if (!userId || !content) return reply.status(400).send({ success: false, message: 'userId and content are required' });
    try {
      const message = await chatService.sendMessage(request.params.id, userId, content, type);
      return reply.status(201).send({ success: true, data: message });
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/direct', async (request: FastifyRequest, reply: FastifyReply) => {
    const { userId, otherUserId } = request.body as { userId: string; otherUserId: string };
    if (!userId || !otherUserId) return reply.status(400).send({ success: false, message: 'userId and otherUserId are required' });
    try {
      const room = await chatService.createDirectRoom(userId, otherUserId);
      return reply.status(201).send({ success: true, data: room });
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/:id/read', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const { userId } = request.body as { userId: string };
    if (!userId) return reply.status(400).send({ success: false, message: 'userId is required' });
    try {
      await chatService.markAsRead(request.params.id, userId);
      return reply.send({ success: true });
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });
}
