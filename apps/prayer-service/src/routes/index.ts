import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { validate, parsePagination } from '@church-app/shared';
import { z } from 'zod';
import { PrayerService } from '../services/prayer.service';

const prayerSchema = z.object({
  authorId: z.string().uuid(),
  title: z.string().min(1).max(200),
  content: z.string().min(1),
  categoryId: z.string().uuid().optional(),
  isPublic: z.boolean().default(true),
  isAnonymous: z.boolean().default(false),
  isUrgent: z.boolean().default(false),
});

const commentSchema = z.object({
  authorId: z.string().uuid(),
  content: z.string().min(1),
});

const reactionSchema = z.object({
  userId: z.string().uuid(),
  type: z.enum(['PRAYING', 'AMEN', 'THANKS']),
});

const categorySchema = z.object({
  name: z.string().min(1),
  color: z.string().optional(),
  icon: z.string().optional(),
});

export async function prayerRoutes(fastify: FastifyInstance) {
  const service = new PrayerService(fastify.prisma);

  fastify.get('/', async (request: FastifyRequest, reply: FastifyReply) => {
    const { page, limit } = parsePagination(request.query);
    const { categoryId, isUrgent } = request.query as Record<string, string | undefined>;
    const data = await service.findAll({
      page, limit, categoryId,
      isUrgent: isUrgent === 'true' ? true : isUrgent === 'false' ? false : undefined,
    });
    return reply.send(data);
  });

  fastify.get('/my', async (request: FastifyRequest, reply: FastifyReply) => {
    const { userId, page, limit } = request.query as Record<string, string | undefined>;
    const pagination = parsePagination({ page, limit });
    const data = await service.findMyPrayers(userId ?? '', pagination);
    return reply.send(data);
  });

  fastify.get('/urgent', async (request: FastifyRequest, reply: FastifyReply) => {
    const { page, limit } = parsePagination(request.query);
    const data = await service.findAll({ page, limit, isUrgent: true });
    return reply.send(data);
  });

  fastify.get('/favorites', async (request: FastifyRequest, reply: FastifyReply) => {
    const { userId, page, limit } = request.query as Record<string, string | undefined>;
    const pagination = parsePagination({ page, limit });
    const data = await service.getFavorites(userId ?? '', pagination);
    return reply.send(data);
  });

  fastify.get('/categories', async (_request: FastifyRequest, reply: FastifyReply) => {
    const data = await service.findAllCategories();
    return reply.send(data);
  });

  fastify.post('/categories', async (request: FastifyRequest, reply: FastifyReply) => {
    const body = validate(categorySchema, request.body);
    const data = await service.createCategory(body);
    return reply.status(201).send(data);
  });

  fastify.get('/:id', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const { userId } = request.query as Record<string, string | undefined>;
    const data = await service.findById(request.params.id, userId ?? '');
    return reply.send(data);
  });

  fastify.post('/', async (request: FastifyRequest, reply: FastifyReply) => {
    const body = validate(prayerSchema, request.body);
    const data = await service.create(body);
    return reply.status(201).send(data);
  });

  fastify.put('/:id', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const { userId } = request.query as Record<string, string | undefined>;
    const body = validate(prayerSchema.partial(), request.body);
    const data = await service.update(request.params.id, userId ?? '', body);
    return reply.send(data);
  });

  fastify.delete('/:id', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const { userId } = request.query as Record<string, string | undefined>;
    await service.delete(request.params.id, userId ?? '');
    return reply.send({ success: true });
  });

  fastify.post('/:id/answer', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const { userId } = request.body as { userId?: string };
    const data = await service.markAnswered(request.params.id, userId ?? '');
    return reply.send(data);
  });

  fastify.post('/:id/comments', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const body = validate(commentSchema, request.body);
    const data = await service.addComment(request.params.id, body.authorId, body.content);
    return reply.status(201).send(data);
  });

  fastify.post('/:id/react', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const body = validate(reactionSchema, request.body);
    const data = await service.toggleReaction(request.params.id, body.userId, body.type);
    return reply.send(data);
  });

  fastify.post('/:id/intercede', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const { userId } = request.body as { userId?: string };
    const data = await service.addIntercessor(request.params.id, userId ?? '');
    return reply.send(data);
  });

  fastify.get('/:id/intercessors', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const data = await service.getIntercessors(request.params.id);
    return reply.send(data);
  });

  fastify.post('/:id/favorite', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const { userId } = request.body as { userId?: string };
    const data = await service.toggleFavorite(request.params.id, userId ?? '');
    return reply.send(data);
  });
}
