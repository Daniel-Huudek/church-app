import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { prayerClient, authClient } from '../http-client';

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
      const res = await authClient.get(`/auth/${id}`, authHeader);
      userMap[id] = { name: res.data.name, avatar: res.data.avatar };
    } catch {}
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
  fastify.get('/', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest, reply: FastifyReply) => {
    const { page, limit, categoryId, isUrgent } = request.query as Record<string, string>;
    let url = `/prayers?page=${page || 1}&limit=${limit || 20}`;
    if (categoryId) url += `&categoryId=${categoryId}`;
    if (isUrgent) url += `&isUrgent=${isUrgent}`;
    try {
      const data = await prayerClient.get(url, getAuthHeader(request));
      return reply.send(await enrichWithAuthors(data, getAuthHeader(request)));
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/my', { preHandler: [fastify.authenticate] }, async (request: any, reply: FastifyReply) => {
    const { page, limit } = request.query as Record<string, string>;
    try {
      const data = await prayerClient.get(`/prayers/my?userId=${request.user.userId}&page=${page || 1}&limit=${limit || 20}`, getAuthHeader(request));
      return reply.send(await enrichWithAuthors(data, getAuthHeader(request)));
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/urgent', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest, reply: FastifyReply) => {
    const { page, limit } = request.query as Record<string, string>;
    try {
      const data = await prayerClient.get(`/prayers/urgent?page=${page || 1}&limit=${limit || 20}`, getAuthHeader(request));
      return reply.send(await enrichWithAuthors(data, getAuthHeader(request)));
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/favorites', { preHandler: [fastify.authenticate] }, async (request: any, reply: FastifyReply) => {
    const { page, limit } = request.query as Record<string, string>;
    try {
      const data = await prayerClient.get(`/prayers/favorites?userId=${request.user.userId}&page=${page || 1}&limit=${limit || 20}`, getAuthHeader(request));
      return reply.send(await enrichWithAuthors(data, getAuthHeader(request)));
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/categories', { preHandler: [fastify.authenticate] }, async (_request: FastifyRequest, reply: FastifyReply) => {
    try {
      const data = await prayerClient.get('/prayers/categories');
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/categories', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest, reply: FastifyReply) => {
    try {
      const data = await prayerClient.post('/prayers/categories', request.body, getAuthHeader(request));
      return reply.status(201).send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/:id', { preHandler: [fastify.authenticate] }, async (request: any, reply: FastifyReply) => {
    try {
      const data = await prayerClient.get(`/prayers/${request.params.id}?userId=${request.user.userId}`, getAuthHeader(request));
      return reply.send(await enrichWithAuthors(data, getAuthHeader(request)));
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/', { preHandler: [fastify.authenticate] }, async (request: any, reply: FastifyReply) => {
    const body = { ...request.body, authorId: request.user.userId };
    try {
      const data = await prayerClient.post('/prayers', body, getAuthHeader(request));
      return reply.send(await enrichWithAuthors(data, getAuthHeader(request)));
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.put('/:id', { preHandler: [fastify.authenticate] }, async (request: any, reply: FastifyReply) => {
    try {
      const data = await prayerClient.put(`/prayers/${request.params.id}`, { ...request.body, userId: request.user.userId }, getAuthHeader(request));
      return reply.send(await enrichWithAuthors(data, getAuthHeader(request)));
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.delete('/:id', { preHandler: [fastify.authenticate] }, async (request: any, reply: FastifyReply) => {
    try {
      const data = await prayerClient.delete(`/prayers/${request.params.id}?userId=${request.user.userId}`, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/:id/answer', { preHandler: [fastify.authenticate] }, async (request: any, reply: FastifyReply) => {
    try {
      const data = await prayerClient.post(`/prayers/${request.params.id}/answer`, { userId: request.user.userId }, getAuthHeader(request));
      return reply.send(await enrichWithAuthors(data, getAuthHeader(request)));
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/:id/comments', { preHandler: [fastify.authenticate] }, async (request: any, reply: FastifyReply) => {
    try {
      const data = await prayerClient.post(`/prayers/${request.params.id}/comments`, { ...request.body, authorId: request.user.userId }, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/:id/react', { preHandler: [fastify.authenticate] }, async (request: any, reply: FastifyReply) => {
    try {
      const data = await prayerClient.post(`/prayers/${request.params.id}/react`, { ...request.body, userId: request.user.userId }, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/:id/intercede', { preHandler: [fastify.authenticate] }, async (request: any, reply: FastifyReply) => {
    try {
      const data = await prayerClient.post(`/prayers/${request.params.id}/intercede`, { userId: request.user.userId }, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/:id/intercessors', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    try {
      const data = await prayerClient.get(`/prayers/${request.params.id}/intercessors`, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/:id/favorite', { preHandler: [fastify.authenticate] }, async (request: any, reply: FastifyReply) => {
    try {
      const data = await prayerClient.post(`/prayers/${request.params.id}/favorite`, { userId: request.user.userId }, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });
}

function getAuthHeader(request: FastifyRequest): Record<string, string> {
  return { Authorization: request.headers.authorization as string };
}
