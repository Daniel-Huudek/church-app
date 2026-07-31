import { Prisma, PrismaClient } from '@prisma/client';
import { AppError, BadRequestError } from '@church-app/shared';
import { BACKUP_VERSION, jsonSafe } from './json-safe.js';

export type BackupPayload = {
  version: number;
  exportedAt: string;
  exportedBy?: string;
  data: Record<string, unknown[]>;
};

export { BACKUP_VERSION, jsonSafe } from './json-safe.js';

function asRows(value: unknown): Record<string, unknown>[] {
  if (!Array.isArray(value)) return [];
  return value.filter((row): row is Record<string, unknown> => !!row && typeof row === 'object');
}

function stripUndefined<T extends Record<string, unknown>>(row: T): T {
  const out = { ...row };
  for (const key of Object.keys(out)) {
    if (out[key] === undefined) delete out[key];
  }
  return out;
}

export class BackupService {
  constructor(private prisma: PrismaClient) {}

  async createBackup(exportedBy?: string): Promise<BackupPayload> {
    const [
      users,
      roleConfigs,
      ministries,
      members,
      memberMinistries,
      addresses,
      documents,
      familyMembers,
      ministerialHistories,
      auditLogs,
      activityLogs,
      events,
      schedules,
      schedulePositions,
      notifications,
      prayerCategories,
      prayerRequests,
      prayerComments,
      prayerReactions,
      intercessors,
      userFavorites,
      transactionCategories,
      costCenters,
      transactions,
      attachments,
      financialAuditLogs,
      monthlyCloses,
      chatRooms,
      chatRoomMembers,
      chatMessages,
      tags,
      songs,
      songTags,
      playlists,
      playlistSongs,
      worshipEvents,
      worshipEventSongs,
      worshipEventMusicians,
      favorites,
      songHistories,
      websiteContents,
    ] = await Promise.all([
      this.prisma.user.findMany(),
      this.prisma.roleConfig.findMany(),
      this.prisma.ministry.findMany(),
      this.prisma.member.findMany(),
      this.prisma.memberMinistry.findMany(),
      this.prisma.address.findMany(),
      this.prisma.document.findMany(),
      this.prisma.familyMember.findMany(),
      this.prisma.ministerialHistory.findMany(),
      this.prisma.auditLog.findMany(),
      this.prisma.activityLog.findMany(),
      this.prisma.event.findMany(),
      this.prisma.schedule.findMany(),
      this.prisma.schedulePosition.findMany(),
      this.prisma.notification.findMany(),
      this.prisma.prayerCategory.findMany(),
      this.prisma.prayerRequest.findMany(),
      this.prisma.prayerComment.findMany(),
      this.prisma.prayerReaction.findMany(),
      this.prisma.intercessor.findMany(),
      this.prisma.userFavorite.findMany(),
      this.prisma.transactionCategory.findMany(),
      this.prisma.costCenter.findMany(),
      this.prisma.transaction.findMany(),
      this.prisma.attachment.findMany(),
      this.prisma.financialAuditLog.findMany(),
      this.prisma.monthlyClose.findMany(),
      this.prisma.chatRoom.findMany(),
      this.prisma.chatRoomMember.findMany(),
      this.prisma.chatMessage.findMany(),
      this.prisma.tag.findMany(),
      this.prisma.song.findMany(),
      this.prisma.songTag.findMany(),
      this.prisma.playlist.findMany(),
      this.prisma.playlistSong.findMany(),
      this.prisma.worshipEvent.findMany(),
      this.prisma.worshipEventSong.findMany(),
      this.prisma.worshipEventMusician.findMany(),
      this.prisma.favorite.findMany(),
      this.prisma.songHistory.findMany(),
      this.prisma.websiteContent.findMany(),
    ]);

    const data = jsonSafe({
      users,
      roleConfigs,
      ministries,
      members,
      memberMinistries,
      addresses,
      documents,
      familyMembers,
      ministerialHistories,
      auditLogs,
      activityLogs,
      events,
      schedules,
      schedulePositions,
      notifications,
      prayerCategories,
      prayerRequests,
      prayerComments,
      prayerReactions,
      intercessors,
      userFavorites,
      transactionCategories,
      costCenters,
      transactions,
      attachments,
      financialAuditLogs,
      monthlyCloses,
      chatRooms,
      chatRoomMembers,
      chatMessages,
      tags,
      songs,
      songTags,
      playlists,
      playlistSongs,
      worshipEvents,
      worshipEventSongs,
      worshipEventMusicians,
      favorites,
      songHistories,
      websiteContents,
    }) as Record<string, unknown[]>;

    return {
      version: BACKUP_VERSION,
      exportedAt: new Date().toISOString(),
      exportedBy,
      data,
    };
  }

  parseBackup(raw: unknown): BackupPayload {
    if (!raw || typeof raw !== 'object') {
      throw new BadRequestError('Arquivo de backup inválido');
    }
    const payload = raw as BackupPayload;
    if (payload.version !== BACKUP_VERSION) {
      throw new BadRequestError(`Versão de backup não suportada (esperado ${BACKUP_VERSION})`);
    }
    if (!payload.data || typeof payload.data !== 'object') {
      throw new BadRequestError('Backup sem dados');
    }
    return payload;
  }

  async restoreBackup(raw: unknown, actorUserId: string) {
    const payload = this.parseBackup(raw);
    const data = payload.data;

    const actor = await this.prisma.user.findUnique({ where: { id: actorUserId } });
    if (!actor) throw new AppError('Usuário autenticado não encontrado', 401, 'UNAUTHORIZED');

    const users = asRows(data.users);
    const actorInBackup = users.some((u) => u.id === actorUserId);

    await this.prisma.$transaction(
      async (tx) => {
        await this.clearAll(tx);

        await this.createMany(tx.user, users);
        if (!actorInBackup) {
          await tx.user.create({
            data: {
              id: actor.id,
              email: actor.email,
              name: actor.name,
              password: actor.password,
              avatar: actor.avatar,
              role: actor.role,
              permissions: actor.permissions,
              googleId: actor.googleId,
              createdAt: actor.createdAt,
              updatedAt: actor.updatedAt,
              deletedAt: actor.deletedAt,
            },
          });
        }

        await this.createMany(tx.roleConfig, asRows(data.roleConfigs));

        const ministries = asRows(data.ministries).map((row) => ({
          ...row,
          leaderId: null,
        }));
        await this.createMany(tx.ministry, ministries);

        await this.createMany(tx.member, asRows(data.members));

        for (const ministry of asRows(data.ministries)) {
          if (ministry.leaderId) {
            await tx.ministry.update({
              where: { id: String(ministry.id) },
              data: { leaderId: String(ministry.leaderId) },
            });
          }
        }

        await this.createMany(tx.memberMinistry, asRows(data.memberMinistries));
        await this.createMany(tx.address, asRows(data.addresses));
        await this.createMany(tx.document, asRows(data.documents));
        await this.createMany(tx.familyMember, asRows(data.familyMembers));
        await this.createMany(tx.ministerialHistory, asRows(data.ministerialHistories));
        await this.createMany(tx.auditLog, asRows(data.auditLogs));
        await this.createMany(tx.activityLog, asRows(data.activityLogs));
        await this.createMany(tx.event, asRows(data.events));
        await this.createMany(tx.schedule, asRows(data.schedules));
        await this.createMany(tx.schedulePosition, asRows(data.schedulePositions));
        await this.createMany(tx.notification, asRows(data.notifications));
        await this.createMany(tx.prayerCategory, asRows(data.prayerCategories));
        await this.createMany(tx.prayerRequest, asRows(data.prayerRequests));
        await this.createMany(tx.prayerComment, asRows(data.prayerComments));
        await this.createMany(tx.prayerReaction, asRows(data.prayerReactions));
        await this.createMany(tx.intercessor, asRows(data.intercessors));
        await this.createMany(tx.userFavorite, asRows(data.userFavorites));
        await this.createMany(tx.transactionCategory, asRows(data.transactionCategories));
        await this.createMany(tx.costCenter, asRows(data.costCenters));
        await this.createMany(tx.transaction, asRows(data.transactions));
        await this.createMany(tx.attachment, asRows(data.attachments));
        await this.createMany(tx.financialAuditLog, asRows(data.financialAuditLogs));
        await this.createMany(tx.monthlyClose, asRows(data.monthlyCloses));
        await this.createMany(tx.chatRoom, asRows(data.chatRooms));
        await this.createMany(tx.chatRoomMember, asRows(data.chatRoomMembers));
        await this.createMany(tx.chatMessage, asRows(data.chatMessages));
        await this.createMany(tx.tag, asRows(data.tags));
        await this.createMany(tx.song, asRows(data.songs));
        await this.createMany(tx.songTag, asRows(data.songTags));
        await this.createMany(tx.playlist, asRows(data.playlists));
        await this.createMany(tx.playlistSong, asRows(data.playlistSongs));
        await this.createMany(tx.worshipEvent, asRows(data.worshipEvents));
        await this.createMany(tx.worshipEventSong, asRows(data.worshipEventSongs));
        await this.createMany(tx.worshipEventMusician, asRows(data.worshipEventMusicians));
        await this.createMany(tx.favorite, asRows(data.favorites));
        await this.createMany(tx.songHistory, asRows(data.songHistories));
        await this.createMany(tx.websiteContent, asRows(data.websiteContents));
      },
      { timeout: 180_000, maxWait: 20_000 },
    );

    return {
      version: payload.version,
      exportedAt: payload.exportedAt,
      restoredAt: new Date().toISOString(),
      counts: Object.fromEntries(
        Object.entries(data).map(([key, rows]) => [key, Array.isArray(rows) ? rows.length : 0]),
      ),
    };
  }

  private async clearAll(tx: Prisma.TransactionClient) {
    await tx.session.deleteMany();
    await tx.refreshToken.deleteMany();
    await tx.songHistory.deleteMany();
    await tx.favorite.deleteMany();
    await tx.worshipEventMusician.deleteMany();
    await tx.worshipEventSong.deleteMany();
    await tx.playlistSong.deleteMany();
    await tx.songTag.deleteMany();
    await tx.worshipEvent.deleteMany();
    await tx.playlist.deleteMany();
    await tx.song.deleteMany();
    await tx.tag.deleteMany();
    await tx.chatMessage.deleteMany();
    await tx.chatRoomMember.deleteMany();
    await tx.chatRoom.deleteMany();
    await tx.attachment.deleteMany();
    await tx.financialAuditLog.deleteMany();
    await tx.transaction.deleteMany();
    await tx.monthlyClose.deleteMany();
    await tx.transactionCategory.deleteMany();
    await tx.costCenter.deleteMany();
    await tx.prayerComment.deleteMany();
    await tx.prayerReaction.deleteMany();
    await tx.intercessor.deleteMany();
    await tx.userFavorite.deleteMany();
    await tx.prayerRequest.deleteMany();
    await tx.prayerCategory.deleteMany();
    await tx.notification.deleteMany();
    await tx.schedulePosition.deleteMany();
    await tx.schedule.deleteMany();
    await tx.event.deleteMany();
    await tx.activityLog.deleteMany();
    await tx.auditLog.deleteMany();
    await tx.ministerialHistory.deleteMany();
    await tx.familyMember.deleteMany();
    await tx.document.deleteMany();
    await tx.address.deleteMany();
    await tx.memberMinistry.deleteMany();
    await tx.ministry.updateMany({ data: { leaderId: null } });
    await tx.member.updateMany({ data: { ministryId: null } });
    await tx.member.deleteMany();
    await tx.ministry.deleteMany();
    await tx.websiteContent.deleteMany();
    await tx.roleConfig.deleteMany();
    await tx.user.deleteMany();
  }

  private async createMany(
    model: { createMany: (args: { data: any[]; skipDuplicates?: boolean }) => Promise<unknown> },
    rows: Record<string, unknown>[],
  ) {
    if (rows.length === 0) return;
    const chunkSize = 500;
    for (let i = 0; i < rows.length; i += chunkSize) {
      const chunk = rows.slice(i, i + chunkSize).map((row) => stripUndefined(row));
      await model.createMany({ data: chunk as any[] });
    }
  }
}
