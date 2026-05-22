import { PrismaClient, SongKey } from '@prisma/client';
import { AppError, NotFoundError } from '../shared';

export class SongService {
  constructor(private prisma: PrismaClient) {}

  async list(params: { search?: string; tag?: string; key?: string; page?: number; limit?: number }) {
    const { search, tag, key: songKey, page = 1, limit = 20 } = params;
    const where: any = { isActive: true };
    if (search) where.OR = [{ title: { contains: search, mode: 'insensitive' } }, { artist: { contains: search, mode: 'insensitive' } }];
    if (songKey) where.key = songKey as SongKey;
    if (tag) where.tags = { some: { tag: { name: { equals: tag, mode: 'insensitive' } } } };
    const [data, total] = await Promise.all([
      this.prisma.song.findMany({ where, include: { tags: { include: { tag: true } }, _count: { select: { favorites: true } } }, orderBy: { title: 'asc' }, skip: (page - 1) * limit, take: limit }),
      this.prisma.song.count({ where }),
    ]);
    return { data, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async getById(id: string) {
    const song = await this.prisma.song.findUnique({ where: { id }, include: { tags: { include: { tag: true } }, favorites: true, histories: { orderBy: { date: 'desc' }, take: 10 } } });
    if (!song) throw new NotFoundError('Song not found');
    return song;
  }

  async create(data: { title: string; artist?: string; key?: SongKey; bpm?: number; duration?: number; lyrics?: string; chords?: string; capo?: number; youtubeUrl?: string; thumbnail?: string; notes?: string; tags?: string[] }) {
    return this.prisma.song.create({
      data: { title: data.title, artist: data.artist, key: data.key, bpm: data.bpm, duration: data.duration, lyrics: data.lyrics, chords: data.chords, capo: data.capo, youtubeUrl: data.youtubeUrl, thumbnail: data.thumbnail, notes: data.notes,
        tags: data.tags?.length ? { create: data.tags.map(name => ({ tag: { connectOrCreate: { where: { name }, create: { name } } } })) } : undefined,
      }, include: { tags: { include: { tag: true } } },
    });
  }

  async update(id: string, data: Partial<{ title: string; artist: string; key: SongKey; bpm: number; duration: number; lyrics: string; chords: string; capo: number; youtubeUrl: string; thumbnail: string; notes: string; isActive: boolean }>) {
    if (!await this.prisma.song.findUnique({ where: { id } })) throw new NotFoundError('Song not found');
    return this.prisma.song.update({ where: { id }, data });
  }

  async remove(id: string) {
    if (!await this.prisma.song.findUnique({ where: { id } })) throw new NotFoundError('Song not found');
    await this.prisma.song.update({ where: { id }, data: { isActive: false } });
  }

  async transpose(id: string, semitons: number) {
    const song = await this.prisma.song.findUnique({ where: { id } });
    if (!song) throw new NotFoundError('Song not found');
    if (!song.chords) throw new AppError('Song has no chords', 400);
    const keyOrder: SongKey[] = ['C','Cm','C7','Cm7','Cs','Csm','D','Dm','D7','Dm7','Eb','Ebm','E','Em','E7','Em7','F','Fm','F7','Fm7','Fs','Fsm','G','Gm','G7','Gm7','Ab','Abm','A','Am','A7','Am7','Bb','Bbm','B','Bm','B7','Bm7'];
    const newKey = song.key ? keyOrder[(keyOrder.indexOf(song.key) + semitons + keyOrder.length) % keyOrder.length] : undefined;
    const transposedChords = song.chords.replace(/\b([A-G][#b]?)(m?)(7?)\b/g, (m) => {
      const idx = keyOrder.indexOf(m as SongKey);
      return idx === -1 ? m : keyOrder[(idx + semitons + keyOrder.length) % keyOrder.length];
    });
    return { transposedChords, originalKey: song.key, newKey };
  }

  async getHistory(songId: string) {
    return this.prisma.songHistory.findMany({ where: { songId }, orderBy: { date: 'desc' }, take: 50 });
  }
}
