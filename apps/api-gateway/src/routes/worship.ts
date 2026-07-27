import { FastifyInstance, FastifyRequest } from 'fastify';
import { worshipClient } from '../http-client';

export async function worshipRoutes(fastify: FastifyInstance) {
  fastify.get('/songs', { preHandler: [fastify.authenticate] }, async (r, reply) => {
    const q = r.query as Record<string, string>;
    const params = new URLSearchParams(q).toString();
    const path = `/worship/songs${params ? '?' + params : ''}`;
    reply.send(await worshipClient.get(path));
  });
  fastify.get('/songs/:id', { preHandler: [fastify.authenticate] }, async (r: FastifyRequest<{ Params: { id: string } }>, reply) => reply.send(await worshipClient.get(`/worship/songs/${r.params.id}`)));
  fastify.post('/songs', { preHandler: [fastify.authenticate] }, async (r, reply) => reply.status(201).send(await worshipClient.post('/worship/songs', r.body)));
  fastify.post('/songs/search', async (r, reply) => reply.send(await worshipClient.post('/worship/songs/search', r.body)));
  fastify.put('/songs/:id', { preHandler: [fastify.authenticate] }, async (r: FastifyRequest<{ Params: { id: string } }>, reply) => reply.send(await worshipClient.put(`/worship/songs/${r.params.id}`, r.body)));
  fastify.post('/songs/:id/transpose', { preHandler: [fastify.authenticate] }, async (r: FastifyRequest<{ Params: { id: string } }>, reply) => reply.send(await worshipClient.post(`/worship/songs/${r.params.id}/transpose`, r.body)));
  fastify.get('/songs/:id/history', { preHandler: [fastify.authenticate] }, async (r: FastifyRequest<{ Params: { id: string } }>, reply) => reply.send(await worshipClient.get(`/worship/songs/${r.params.id}/history`)));

  fastify.get('/playlists', { preHandler: [fastify.authenticate] }, async (r, reply) => {
    const q = r.query as Record<string, string>;
    const params = new URLSearchParams(q).toString();
    const path = `/worship/playlists${params ? '?' + params : ''}`;
    reply.send(await worshipClient.get(path));
  });
  fastify.get('/playlists/:id', { preHandler: [fastify.authenticate] }, async (r: FastifyRequest<{ Params: { id: string } }>, reply) => reply.send(await worshipClient.get(`/worship/playlists/${r.params.id}`)));
  fastify.post('/playlists', { preHandler: [fastify.authenticate] }, async (r, reply) => reply.status(201).send(await worshipClient.post('/worship/playlists', r.body)));
  fastify.put('/playlists/:id', { preHandler: [fastify.authenticate] }, async (r: FastifyRequest<{ Params: { id: string } }>, reply) => reply.send(await worshipClient.put(`/worship/playlists/${r.params.id}`, r.body)));
  fastify.delete('/playlists/:id', { preHandler: [fastify.authenticate] }, async (r: FastifyRequest<{ Params: { id: string } }>, reply) => { await worshipClient.delete(`/worship/playlists/${r.params.id}`); return reply.send({ success: true }); });
  fastify.post('/playlists/:id/duplicate', { preHandler: [fastify.authenticate] }, async (r: FastifyRequest<{ Params: { id: string } }>, reply) => reply.send(await worshipClient.post(`/worship/playlists/${r.params.id}/duplicate`)));
  fastify.put('/playlists/:id/songs/reorder', { preHandler: [fastify.authenticate] }, async (r: FastifyRequest<{ Params: { id: string } }>, reply) => reply.send(await worshipClient.put(`/worship/playlists/${r.params.id}/songs/reorder`, { data: r.body })));

  fastify.get('/worship-events', { preHandler: [fastify.authenticate] }, async (r, reply) => {
    const q = r.query as Record<string, string>;
    const params = new URLSearchParams(q).toString();
    const path = `/worship/worship-events${params ? '?' + params : ''}`;
    reply.send(await worshipClient.get(path));
  });
  fastify.get('/worship-events/:id', { preHandler: [fastify.authenticate] }, async (r: FastifyRequest<{ Params: { id: string } }>, reply) => reply.send(await worshipClient.get(`/worship/worship-events/${r.params.id}`)));
  fastify.get('/worship-events/event/:eventId', { preHandler: [fastify.authenticate] }, async (r: FastifyRequest<{ Params: { eventId: string } }>, reply) => reply.send(await worshipClient.get(`/worship/worship-events/event/${r.params.eventId}`)));
  fastify.post('/worship-events', { preHandler: [fastify.authenticate] }, async (r, reply) => reply.status(201).send(await worshipClient.post('/worship/worship-events', r.body)));
  fastify.put('/worship-events/:id', { preHandler: [fastify.authenticate] }, async (r: FastifyRequest<{ Params: { id: string } }>, reply) => reply.send(await worshipClient.put(`/worship/worship-events/${r.params.id}`, r.body)));
  fastify.put('/worship-events/:id/songs', { preHandler: [fastify.authenticate] }, async (r: FastifyRequest<{ Params: { id: string } }>, reply) => reply.send(await worshipClient.put(`/worship/worship-events/${r.params.id}/songs`, r.body)));
  fastify.put('/worship-events/:id/musicians', { preHandler: [fastify.authenticate] }, async (r: FastifyRequest<{ Params: { id: string } }>, reply) => reply.send(await worshipClient.put(`/worship/worship-events/${r.params.id}/musicians`, r.body)));
  fastify.post('/worship-events/:id/musicians/:memberId/confirm', { preHandler: [fastify.authenticate] }, async (r: FastifyRequest<{ Params: { id: string; memberId: string } }>, reply) => { await worshipClient.post(`/worship/worship-events/${r.params.id}/musicians/${r.params.memberId}/confirm`, r.body || {}); return reply.send({ success: true }); });

  fastify.get('/favorites', { preHandler: [fastify.authenticate] }, async (r, reply) => reply.send(await worshipClient.get('/worship/favorites')));
  fastify.post('/favorites/:songId', { preHandler: [fastify.authenticate] }, async (r: FastifyRequest<{ Params: { songId: string } }>, reply) => reply.status(201).send(await worshipClient.post(`/worship/favorites/${r.params.songId}`)));
  fastify.delete('/favorites/:songId', { preHandler: [fastify.authenticate] }, async (r: FastifyRequest<{ Params: { songId: string } }>, reply) => { await worshipClient.delete(`/worship/favorites/${r.params.songId}`); return reply.send({ success: true }); });
}
