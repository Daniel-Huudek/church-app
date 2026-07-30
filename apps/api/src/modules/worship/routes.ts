import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { validate, authenticate, requireAuthUser } from '@church-app/shared';
import { SongService } from './song.service';
import { SongSearchService } from './song-search.service';
import { PlaylistService } from './playlist.service';
import { WorshipEventService } from './worship-event.service';

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
  const weCreate = z.object({
    eventId: z.string().min(1),
    playlistId: z.string().optional(),
    ministerMemberId: z.string().min(1).nullable().optional(),
    notes: z.string().optional(),
    estimatedTime: z.number().int().optional(),
  });
  const weUpdate = z.object({
    notes: z.string().optional(),
    estimatedTime: z.number().int().optional(),
    playlistId: z.string().optional(),
    ministerMemberId: z.string().min(1).nullable().optional(),
  });
  const musiciansSchema = z.object({ musicians: z.array(z.object({ memberId: z.string().min(1), instrument: z.string().optional(), role: z.string().optional() })) });

  // Song search stays public (former gateway behavior)
  const searchSchema = z.object({ query: z.string().min(1) });
  fastify.post('/songs/search', async (r) => {
    const { query } = validate(searchSchema, r.body);
    return { success: true, data: await songSearch.search(query) };
  });

  await fastify.register(async (secured) => {
    secured.addHook('preHandler', authenticate());

    secured.get('/songs', async (r) => songService.list({ search: (r.query as any).search, tag: (r.query as any).tag, key: (r.query as any).key, page: Number((r.query as any).page) || 1, limit: Number((r.query as any).limit) || 20 }));
    secured.get('/songs/:id', async (r) => songService.getById((r.params as any).id));
    secured.post('/songs', async (r, reply) => { const b = validate(songCreate, r.body); return reply.status(201).send({ success: true, data: await songService.create(b) }); });
    secured.put('/songs/:id', async (r) => songService.update((r.params as any).id, validate(songUpdate, r.body)));
    secured.delete('/songs/:id', async (r) => { await songService.remove((r.params as any).id); return { success: true }; });
    secured.post('/songs/:id/transpose', async (r) => songService.transpose((r.params as any).id, validate(transposeSchema, r.body).semitons));
    secured.get('/songs/:id/history', async (r) => songService.getHistory((r.params as any).id));

    secured.get('/playlists', async (r) => playlistService.list({ page: Number((r.query as any).page) || 1, limit: Number((r.query as any).limit) || 20 }));
    secured.get('/playlists/:id', async (r) => playlistService.getById((r.params as any).id));
    secured.post('/playlists', async (r, reply) => {
      const { userId } = requireAuthUser(r);
      const b = validate(playlistCreate, r.body);
      return reply.status(201).send({ success: true, data: await playlistService.create({ ...b, createdBy: userId }) });
    });
    secured.put('/playlists/:id', async (r) => playlistService.update((r.params as any).id, validate(playlistUpdate, r.body)));
    secured.delete('/playlists/:id', async (r) => { await playlistService.remove((r.params as any).id); return { success: true }; });
    secured.post('/playlists/:id/duplicate', async (r) => {
      const { userId } = requireAuthUser(r);
      return playlistService.duplicate((r.params as any).id, userId);
    });
    secured.put('/playlists/:id/songs/reorder', async (r) => { await playlistService.reorderSongs((r.params as any).id, validate(reorder, r.body).songIds); return { success: true }; });

    secured.get('/worship-events', async (r) => worshipEventService.list({ page: Number((r.query as any).page) || 1, limit: Number((r.query as any).limit) || 50 }));
    secured.get('/worship-events/event/:eventId', async (r) => worshipEventService.getByEvent((r.params as any).eventId));
    secured.get('/worship-events/:id', async (r) => worshipEventService.getById((r.params as any).id));
    secured.post('/worship-events', async (r, reply) => { const b = validate(weCreate, r.body); return reply.status(201).send({ success: true, data: await worshipEventService.create(b) }); });
    secured.put('/worship-events/:id', async (r) => worshipEventService.update((r.params as any).id, validate(weUpdate, r.body)));
    secured.delete('/worship-events/:id', async (r) => worshipEventService.remove((r.params as any).id));
    secured.put('/worship-events/:id/songs', async (r) => { await worshipEventService.reorderSongs((r.params as any).id, validate(reorder, r.body).songIds); return { success: true }; });
    secured.put('/worship-events/:id/musicians', async (r) => worshipEventService.setMusicians((r.params as any).id, validate(musiciansSchema, r.body).musicians));
    secured.post('/worship-events/:id/musicians/:memberId/confirm', async (r) => { const body = r.body as any; await worshipEventService.confirmMusician((r.params as any).id, (r.params as any).memberId, body?.status ?? 'confirmado'); return { success: true }; });

    secured.get('/favorites', async (r) => {
      const { userId } = requireAuthUser(r);
      const songs = await fastify.prisma.favorite.findMany({ where: { userId }, include: { song: { include: { tags: { include: { tag: true } } } } }, orderBy: { createdAt: 'desc' } });
      return { data: songs.map(f => f.song) };
    });
    secured.post('/favorites/:songId', async (r, reply) => {
      const { userId } = requireAuthUser(r);
      const f = await fastify.prisma.favorite.upsert({ where: { userId_songId: { userId, songId: (r.params as any).songId } }, update: {}, create: { userId, songId: (r.params as any).songId } });
      return reply.status(201).send({ success: true, data: f });
    });
    secured.delete('/favorites/:songId', async (r) => {
      const { userId } = requireAuthUser(r);
      await fastify.prisma.favorite.deleteMany({ where: { userId, songId: (r.params as any).songId } });
      return { success: true };
    });
  });
}
