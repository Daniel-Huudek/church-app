import { PrismaClient } from '@prisma/client';
import { NotFoundError } from '@church-app/shared';

export class PlaylistService {
  constructor(private prisma: PrismaClient) {}

  async list(params: { page?: number; limit?: number }) {
    const { page = 1, limit = 20 } = params;
    const [data, total] = await Promise.all([
      this.prisma.playlist.findMany({ include: { songs: { include: { song: { select: { id: true, title: true, artist: true, key: true, duration: true } } }, orderBy: { order: 'asc' } } }, orderBy: { updatedAt: 'desc' }, skip: (page - 1) * limit, take: limit }),
      this.prisma.playlist.count(),
    ]);
    return { data, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async getById(id: string) {
    const p = await this.prisma.playlist.findUnique({ where: { id }, include: { songs: { include: { song: { include: { tags: { include: { tag: true } } } } }, orderBy: { order: 'asc' } }, worshipEvent: true } });
    if (!p) throw new NotFoundError('Playlist not found');
    return p;
  }

  async create(data: { name: string; description?: string; createdBy: string; isPublic?: boolean; songIds?: string[] }) {
    return this.prisma.playlist.create({ data: { name: data.name, description: data.description, createdBy: data.createdBy, isPublic: data.isPublic ?? false,
      songs: data.songIds?.length ? { create: data.songIds.map((songId, i) => ({ songId, order: i + 1 })) } : undefined,
    }, include: { songs: { orderBy: { order: 'asc' } } } });
  }

  async duplicate(id: string, createdBy: string) {
    const original = await this.prisma.playlist.findUnique({ where: { id }, include: { songs: true } });
    if (!original) throw new NotFoundError('Playlist not found');
    return this.prisma.playlist.create({ data: { name: `${original.name} (cópia)`, description: original.description, createdBy, isPublic: false,
      songs: { create: original.songs.map(s => ({ songId: s.songId, order: s.order, transpose: s.transpose })) },
    }, include: { songs: { orderBy: { order: 'asc' } } } });
  }

  async update(id: string, data: { name?: string; description?: string; isPublic?: boolean }) {
    if (!await this.prisma.playlist.findUnique({ where: { id } })) throw new NotFoundError('Playlist not found');
    return this.prisma.playlist.update({ where: { id }, data });
  }

  async remove(id: string) {
    if (!await this.prisma.playlist.findUnique({ where: { id } })) throw new NotFoundError('Playlist not found');
    await this.prisma.playlist.delete({ where: { id } });
  }

  async reorderSongs(playlistId: string, songIds: string[]) {
    if (!await this.prisma.playlist.findUnique({ where: { id: playlistId } })) throw new NotFoundError('Playlist not found');
    await this.prisma.playlistSong.deleteMany({ where: { playlistId } });
    return this.prisma.playlistSong.createMany({ data: songIds.map((id, i) => ({ playlistId, songId: id, order: i + 1 })) });
  }
}
