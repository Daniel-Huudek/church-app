import { FastifyInstance } from 'fastify';
import { prayerClient, authClient } from '../http-client';
import { getAuthHeader, validate } from '@church-app/shared';
import { z } from 'zod';

const prayerCreateSchema = z.object({
  title: z.string().min(1).max(200),
  content: z.string().min(1),
  categoryId: z.string().uuid().optional(),
  isPublic: z.boolean().optional(),
  isAnonymous: z.boolean().optional(),
  isUrgent: z.boolean().optional(),
});

const commentSchema = z.object({ content: z.string().min(1) });

const reactionSchema = z.object({ type: z.enum(['PRAYING', 'AMEN', 'THANKS']) });

const categorySchema = z.object({
  name: z.string().min(1),
  color: z.string().optional(),
  icon: z.string().optional(),
});

async function enrichWithAuthors(data: any, authHeader: Record<string, string>): Promise<any> {
  const ids = new Set<string>();
  const items = data?.data?.data || data?.data;
  const itemsArr = Array.isArray(items) ? items : [items].filter(Boolean);

  for (const item of itemsArr) {
    if (item.authorId) ids.add(item.authorId);
    if (item.comments) {
      for (const c of item.comments) {
        if (c.authorId) ids.add(c.authorId);
      }
    }
  }

  if (ids.size === 0) return data;

  const userMap: Record<string, { name: string; avatar?: string }> = {};
  await Promise.all([...ids].map(async (id) => {
    try {
      const res: any = await authClient.get(`/auth/${id}`, authHeader);
      userMap[id] = { name: res.data.name, avatar: res.data.avatar };
    } catch {
      // ignore author lookup failures
    }
  }));

  for (const item of itemsArr) {
    const u = userMap[item.authorId];
    if (u) {
      item.authorName = u.name;
      item.authorAvatar = u.avatar;
    }
    if (item.comments) {
      for (const c of item.comments) {
        const cu = userMap[c.authorId];
        if (cu) {
          c.authorName = cu.name;
          c.authorAvatar = cu.avatar;
        }
      }
    }
  }

  return data;
}

export async function prayerRoutes(fastify: FastifyInstance) {
  fastify.get('/', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const { page, limit, categoryId, isUrgent } = request.query as Record<string, string>;
    let url = `/prayers?page=${page || 1}&limit=${limit || 20}`;
    if (categoryId) url += `&categoryId=${categoryId}`;
    if (isUrgent) url += `&isUrgent=${isUrgent}`;
    try {
      const data = await prayerClient.get(url, getAuthHeader(request));
      await reply.send(await enrichWithAuthors(data, getAuthHeader(request)));
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/my', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const { page, limit } = request.query as Record<string, string>;
    try {
      const data = await prayerClient.get(`/prayers/my?userId=${request.user.userId}&page=${page || 1}&limit=${limit || 20}`, getAuthHeader(request));
      await reply.send(await enrichWithAuthors(data, getAuthHeader(request)));
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/urgent', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const { page, limit } = request.query as Record<string, string>;
    try {
      const data = await prayerClient.get(`/prayers/urgent?page=${page || 1}&limit=${limit || 20}`, getAuthHeader(request));
      await reply.send(await enrichWithAuthors(data, getAuthHeader(request)));
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/favorites', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const { page, limit } = request.query as Record<string, string>;
    try {
      const data = await prayerClient.get(`/prayers/favorites?userId=${request.user.userId}&page=${page || 1}&limit=${limit || 20}`, getAuthHeader(request));
      await reply.send(await enrichWithAuthors(data, getAuthHeader(request)));
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/categories', { preHandler: [fastify.authenticate] }, async (_request, reply) => {
    try {
      const data = await prayerClient.get('/prayers/categories');
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/categories', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = validate(categorySchema, request.body);
    try {
      const data = await prayerClient.post('/prayers/categories', body, getAuthHeader(request));
      await reply.status(201).send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get<{ Params: { id: string } }>('/:id', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await prayerClient.get(`/prayers/${request.params.id}?userId=${request.user.userId}`, getAuthHeader(request));
      await reply.send(await enrichWithAuthors(data, getAuthHeader(request)));
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = { ...validate(prayerCreateSchema, request.body), authorId: request.user.userId };
    try {
      const data = await prayerClient.post('/prayers', body, getAuthHeader(request));
      await reply.send(await enrichWithAuthors(data, getAuthHeader(request)));
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.put<{ Params: { id: string } }>('/:id', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await prayerClient.put(`/prayers/${request.params.id}?role=${request.user.role}`, { ...(request.body as object), userId: request.user.userId }, getAuthHeader(request));
      await reply.send(await enrichWithAuthors(data, getAuthHeader(request)));
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.delete<{ Params: { id: string } }>('/:id', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await prayerClient.delete(`/prayers/${request.params.id}?userId=${request.user.userId}&role=${request.user.role}`, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post<{ Params: { id: string } }>('/:id/answer', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await prayerClient.post(`/prayers/${request.params.id}/answer`, { userId: request.user.userId }, getAuthHeader(request));
      await reply.send(await enrichWithAuthors(data, getAuthHeader(request)));
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post<{ Params: { id: string } }>('/:id/comments', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = { ...validate(commentSchema, request.body), authorId: request.user.userId };
    try {
      const data = await prayerClient.post(`/prayers/${request.params.id}/comments`, body, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post<{ Params: { id: string } }>('/:id/react', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = { ...validate(reactionSchema, request.body), userId: request.user.userId };
    try {
      const data = await prayerClient.post(`/prayers/${request.params.id}/react`, body, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post<{ Params: { id: string } }>('/:id/intercede', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await prayerClient.post(`/prayers/${request.params.id}/intercede`, { userId: request.user.userId }, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get<{ Params: { id: string } }>('/:id/intercessors', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await prayerClient.get(`/prayers/${request.params.id}/intercessors`, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post<{ Params: { id: string } }>('/:id/favorite', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await prayerClient.post(`/prayers/${request.params.id}/favorite`, { userId: request.user.userId }, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });
}


