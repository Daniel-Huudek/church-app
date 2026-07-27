import { FastifyInstance, FastifyRequest } from 'fastify';
import { z } from 'zod';
import { validate } from '@church-app/shared';
import { SongService } from '../services/song.service';
import { SongSearchService } from '../services/song-search.service';
import { PlaylistService } from '../services/playlist.service';
import { WorshipEventService } from '../services/worship-event.service';

export async function worshipRoutes(fastify: FastifyInstance) {
  const songService = new SongService(fastify.prisma);
  const songSearch = new SongSearchService();
  const playlistService = new PlaylistService(fastify.prisma);
  const worshipEventService = new WorshipEventService(fastify.prisma);

  const songCreate = z.object({ title: z.string().min(1), artist: z.string().optional(), key: z.string().optional(), bpm: z.number().int().optional(), duration: z.number().int().optional(), lyrics: z.string().optional(), chords: z.string().optional(), capo: z.number().int().optional(), youtubeUrl: z.string().optional(), thumbnail: z.string().optional(), notes: z.string().optional(), tags: z.array(z.string()).optional() });
  const songUpdate = songCreate.partial();
  const transposeSchema = z.object({ semitons: z.number().int() });
  const playlistCreate = z.object({ name: z.string().min(1), description: z.string().optional(), isPublic: z.boolean().optional(), songIds: z.array(z.string()).optional() });
  const playlistUpdate = z.object({ name: z.string().optional(), description: z.string().optional(), isPublic: z.boolean().optional() });
  const reorder = z.object({ songIds: z.array(z.string()) });
  const weCreate = z.object({ eventId: z.string().min(1), playlistId: z.string().optional(), notes: z.string().optional(), estimatedTime: z.number().int().optional() });
  const weUpdate = z.object({ notes: z.string().optional(), estimatedTime: z.number().int().optional(), playlistId: z.string().optional() });
  const musiciansSchema = z.object({ musicians: z.array(z.object({ memberId: z.string().min(1), instrument: z.string().optional(), role: z.string().optional() })) });

  fastify.get('/songs', async (r) => songService.list({ search: (r.query as any).search, tag: (r.query as any).tag, key: (r.query as any).key, page: Number((r.query as any).page) || 1, limit: Number((r.query as any).limit) || 20 }));
  fastify.get('/songs/:id', async (r: FastifyRequest<{ Params: { id: string } }>) => songService.getById(r.params.id));
  fastify.post('/songs', async (r, reply) => { const b = validate(songCreate, r.body); return reply.status(201).send({ success: true, data: await songService.create(b) }); });
  fastify.put('/songs/:id', async (r: FastifyRequest<{ Params: { id: string } }>) => songService.update(r.params.id, validate(songUpdate, r.body)));
  fastify.delete('/songs/:id', async (r: FastifyRequest<{ Params: { id: string } }>) => { await songService.remove(r.params.id); return { success: true }; });
  fastify.post('/songs/:id/transpose', async (r: FastifyRequest<{ Params: { id: string } }>) => songService.transpose(r.params.id, validate(transposeSchema, r.body).semitons));
  fastify.get('/songs/:id/history', async (r: FastifyRequest<{ Params: { id: string } }>) => songService.getHistory(r.params.id));

  const searchSchema = z.object({ query: z.string().min(1) });
  fastify.post('/songs/search', async (r) => {
    const { query } = validate(searchSchema, r.body);
    return { success: true, data: await songSearch.search(query) };
  });

  fastify.get('/playlists', async (r) => playlistService.list({ page: Number((r.query as any).page) || 1, limit: Number((r.query as any).limit) || 20 }));
  fastify.get('/playlists/:id', async (r: FastifyRequest<{ Params: { id: string } }>) => playlistService.getById(r.params.id));
  fastify.post('/playlists', async (r, reply) => { const b = validate(playlistCreate, r.body); return reply.status(201).send({ success: true, data: await playlistService.create({ ...b, createdBy: (r as any).userId || 'system' }) }); });
  fastify.put('/playlists/:id', async (r: FastifyRequest<{ Params: { id: string } }>) => playlistService.update(r.params.id, validate(playlistUpdate, r.body)));
  fastify.delete('/playlists/:id', async (r: FastifyRequest<{ Params: { id: string } }>) => { await playlistService.remove(r.params.id); return { success: true }; });
  fastify.post('/playlists/:id/duplicate', async (r: FastifyRequest<{ Params: { id: string } }>) => playlistService.duplicate(r.params.id, (r as any).userId || 'system'));
  fastify.put('/playlists/:id/songs/reorder', async (r: FastifyRequest<{ Params: { id: string } }>) => { await playlistService.reorderSongs(r.params.id, validate(reorder, r.body).songIds); return { success: true }; });

  fastify.get('/worship-events', async (r) => worshipEventService.list({ page: Number((r.query as any).page) || 1, limit: Number((r.query as any).limit) || 50 }));
  fastify.get('/worship-events/:id', async (r: FastifyRequest<{ Params: { id: string } }>) => worshipEventService.getById(r.params.id));
  fastify.get('/worship-events/event/:eventId', async (r: FastifyRequest<{ Params: { eventId: string } }>) => worshipEventService.getByEvent(r.params.eventId));
  fastify.post('/worship-events', async (r, reply) => { const b = validate(weCreate, r.body); return reply.status(201).send({ success: true, data: await worshipEventService.create(b) }); });
  fastify.put('/worship-events/:id', async (r: FastifyRequest<{ Params: { id: string } }>) => worshipEventService.update(r.params.id, validate(weUpdate, r.body)));
  fastify.put('/worship-events/:id/songs', async (r: FastifyRequest<{ Params: { id: string } }>) => { await worshipEventService.reorderSongs(r.params.id, validate(reorder, r.body).songIds); return { success: true }; });
  fastify.put('/worship-events/:id/musicians', async (r: FastifyRequest<{ Params: { id: string } }>) => worshipEventService.setMusicians(r.params.id, validate(musiciansSchema, r.body).musicians));
  fastify.post('/worship-events/:id/musicians/:memberId/confirm', async (r: FastifyRequest<{ Params: { id: string; memberId: string } }>) => { const body = r.body as any; await worshipEventService.confirmMusician(r.params.id, r.params.memberId, body?.status ?? 'confirmado'); return { success: true }; });

  fastify.get('/favorites', async (r) => { const songs = await fastify.prisma.favorite.findMany({ where: { userId: (r as any).userId || '' }, include: { song: { include: { tags: { include: { tag: true } } } } }, orderBy: { createdAt: 'desc' } }); return { data: songs.map(f => f.song) }; });
  fastify.post('/favorites/:songId', async (r: FastifyRequest<{ Params: { songId: string } }>, reply) => { const f = await fastify.prisma.favorite.upsert({ where: { userId_songId: { userId: (r as any).userId || '', songId: r.params.songId } }, update: {}, create: { userId: (r as any).userId || '', songId: r.params.songId } }); return reply.status(201).send({ success: true, data: f }); });
  fastify.delete('/favorites/:songId', async (r: FastifyRequest<{ Params: { songId: string } }>) => { await fastify.prisma.favorite.deleteMany({ where: { userId: (r as any).userId || '', songId: r.params.songId } }); return { success: true }; });
}
