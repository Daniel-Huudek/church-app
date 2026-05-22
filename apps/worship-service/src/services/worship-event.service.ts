import { PrismaClient } from '@prisma/client';
import { NotFoundError } from '../shared';

export class WorshipEventService {
  constructor(private prisma: PrismaClient) {}

  async getByEvent(eventId: string) {
    return this.prisma.worshipEvent.findUnique({ where: { eventId }, include: { songs: { include: { song: true }, orderBy: { order: 'asc' } }, musicians: true, playlist: { include: { songs: { include: { song: true }, orderBy: { order: 'asc' } } } } } });
  }

  async create(data: { eventId: string; playlistId?: string; notes?: string; estimatedTime?: number }) {
    return this.prisma.worshipEvent.create({
      data: { eventId: data.eventId, playlistId: data.playlistId, notes: data.notes, estimatedTime: data.estimatedTime,
        songs: data.playlistId ? { create: (await this.prisma.playlistSong.findMany({ where: { playlistId: data.playlistId }, orderBy: { order: 'asc' } })).map(s => ({ songId: s.songId, order: s.order, transpose: s.transpose })) } : undefined,
      }, include: { songs: { include: { song: true }, orderBy: { order: 'asc' } }, musicians: true },
    });
  }

  async update(id: string, data: { notes?: string; estimatedTime?: number; playlistId?: string }) {
    if (!await this.prisma.worshipEvent.findUnique({ where: { id } })) throw new NotFoundError('Worship event not found');
    return this.prisma.worshipEvent.update({ where: { id }, data });
  }

  async reorderSongs(worshipEventId: string, songIds: string[]) {
    if (!await this.prisma.worshipEvent.findUnique({ where: { id: worshipEventId } })) throw new NotFoundError('Worship event not found');
    await this.prisma.worshipEventSong.deleteMany({ where: { worshipEventId } });
    return this.prisma.worshipEventSong.createMany({ data: songIds.map((id, i) => ({ worshipEventId, songId: id, order: i + 1 })) });
  }

  async setMusicians(worshipEventId: string, musicians: { memberId: string; instrument?: string; role?: string }[]) {
    if (!await this.prisma.worshipEvent.findUnique({ where: { id: worshipEventId } })) throw new NotFoundError('Worship event not found');
    await this.prisma.worshipEventMusician.deleteMany({ where: { worshipEventId } });
    if (musicians.length > 0) await this.prisma.worshipEventMusician.createMany({ data: musicians.map(m => ({ worshipEventId, memberId: m.memberId, instrument: m.instrument, role: m.role })) });
    return this.prisma.worshipEventMusician.findMany({ where: { worshipEventId } });
  }

  async confirmMusician(worshipEventId: string, memberId: string) {
    const m = await this.prisma.worshipEventMusician.findFirst({ where: { worshipEventId, memberId } });
    if (!m) throw new NotFoundError('Musician not found');
    return this.prisma.worshipEventMusician.update({ where: { id: m.id }, data: { isConfirmed: true } });
  }
}
