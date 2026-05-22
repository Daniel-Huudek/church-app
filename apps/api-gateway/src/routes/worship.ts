import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { worshipClient } from '../http-client';

export async function worshipRoutes(fastify: FastifyInstance) {
  fastify.get('/songs', async (r, reply) => reply.send(await worshipClient.get('/worship/songs', { params: r.query })));
  fastify.get('/songs/:id', async (r: FastifyRequest<{ Params: { id: string } }>, reply) => reply.send(await worshipClient.get(`/worship/songs/${r.params.id}`)));
  fastify.post('/songs', async (r, reply) => reply.status(201).send(await worshipClient.post('/worship/songs', { data: r.body })));
  fastify.put('/songs/:id', async (r: FastifyRequest<{ Params: { id: string } }>, reply) => reply.send(await worshipClient.put(`/worship/songs/${r.params.id}`, { data: r.body })));
  fastify.delete('/songs/:id', async (r: FastifyRequest<{ Params: { id: string } }>, reply) => { await worshipClient.delete(`/worship/songs/${r.params.id}`); return reply.send({ success: true }); });
  fastify.post('/songs/:id/transpose', async (r: FastifyRequest<{ Params: { id: string } }>, reply) => reply.send(await worshipClient.post(`/worship/songs/${r.params.id}/transpose`, { data: r.body })));
  fastify.get('/songs/:id/history', async (r: FastifyRequest<{ Params: { id: string } }>, reply) => reply.send(await worshipClient.get(`/worship/songs/${r.params.id}/history`)));

  fastify.get('/playlists', async (r, reply) => reply.send(await worshipClient.get('/worship/playlists', { params: r.query })));
  fastify.get('/playlists/:id', async (r: FastifyRequest<{ Params: { id: string } }>, reply) => reply.send(await worshipClient.get(`/worship/playlists/${r.params.id}`)));
  fastify.post('/playlists', async (r, reply) => reply.status(201).send(await worshipClient.post('/worship/playlists', { data: r.body })));
  fastify.put('/playlists/:id', async (r: FastifyRequest<{ Params: { id: string } }>, reply) => reply.send(await worshipClient.put(`/worship/playlists/${r.params.id}`, { data: r.body })));
  fastify.delete('/playlists/:id', async (r: FastifyRequest<{ Params: { id: string } }>, reply) => { await worshipClient.delete(`/worship/playlists/${r.params.id}`); return reply.send({ success: true }); });
  fastify.post('/playlists/:id/duplicate', async (r: FastifyRequest<{ Params: { id: string } }>, reply) => reply.send(await worshipClient.post(`/worship/playlists/${r.params.id}/duplicate`)));
  fastify.put('/playlists/:id/songs/reorder', async (r: FastifyRequest<{ Params: { id: string } }>, reply) => reply.send(await worshipClient.put(`/worship/playlists/${r.params.id}/songs/reorder`, { data: r.body })));

  fastify.get('/worship-events/event/:eventId', async (r: FastifyRequest<{ Params: { eventId: string } }>, reply) => reply.send(await worshipClient.get(`/worship/worship-events/event/${r.params.eventId}`)));
  fastify.post('/worship-events', async (r, reply) => reply.status(201).send(await worshipClient.post('/worship/worship-events', { data: r.body })));
  fastify.put('/worship-events/:id', async (r: FastifyRequest<{ Params: { id: string } }>, reply) => reply.send(await worshipClient.put(`/worship/worship-events/${r.params.id}`, { data: r.body })));
  fastify.put('/worship-events/:id/songs', async (r: FastifyRequest<{ Params: { id: string } }>, reply) => reply.send(await worshipClient.put(`/worship/worship-events/${r.params.id}/songs`, { data: r.body })));
  fastify.put('/worship-events/:id/musicians', async (r: FastifyRequest<{ Params: { id: string } }>, reply) => reply.send(await worshipClient.put(`/worship/worship-events/${r.params.id}/musicians`, { data: r.body })));
  fastify.post('/worship-events/:id/musicians/:memberId/confirm', async (r: FastifyRequest<{ Params: { id: string; memberId: string } }>, reply) => { await worshipClient.post(`/worship/worship-events/${r.params.id}/musicians/${r.params.memberId}/confirm`); return reply.send({ success: true }); });

  fastify.get('/favorites', async (r, reply) => reply.send(await worshipClient.get('/worship/favorites')));
  fastify.post('/favorites/:songId', async (r: FastifyRequest<{ Params: { songId: string } }>, reply) => reply.status(201).send(await worshipClient.post(`/worship/favorites/${r.params.songId}`)));
  fastify.delete('/favorites/:songId', async (r: FastifyRequest<{ Params: { songId: string } }>, reply) => { await worshipClient.delete(`/worship/favorites/${r.params.songId}`); return reply.send({ success: true }); });
}
