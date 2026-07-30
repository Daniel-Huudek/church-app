import { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';
import { authenticate, authorize, requireAuthUser, AppError } from '@church-app/shared';
import { BackupService } from './service.js';

const MAX_BACKUP_BYTES = 50 * 1024 * 1024;

export async function backupRoutes(fastify: FastifyInstance) {
  const service = new BackupService(fastify.prisma);
  const adminOnly = authorize('ADMINISTRADOR', 'PASTOR');

  fastify.addHook('preHandler', authenticate());

  /** Gera backup JSON completo dos dados da igreja. */
  fastify.get('/', { preHandler: [adminOnly] }, async (request: FastifyRequest, reply: FastifyReply) => {
    const { userId } = requireAuthUser(request);
    const backup = await service.createBackup(userId);
    const filename = `church-backup-${backup.exportedAt.slice(0, 10)}.json`;
    reply.header('Content-Disposition', `attachment; filename="${filename}"`);
    return reply.send({ success: true, data: backup });
  });

  /** Restaura backup a partir de JSON (body) ou arquivo multipart. */
  fastify.post('/restore', { preHandler: [adminOnly] }, async (request: FastifyRequest, reply: FastifyReply) => {
    const { userId } = requireAuthUser(request);
    const contentType = String(request.headers['content-type'] || '');

    let raw: unknown;
    if (contentType.includes('multipart/form-data')) {
      const file = await request.file();
      if (!file) {
        throw new AppError('Nenhum arquivo enviado', 400, 'NO_FILE');
      }
      const buffer = await file.toBuffer();
      if (buffer.byteLength === 0) {
        throw new AppError('Arquivo vazio', 400, 'EMPTY_FILE');
      }
      if (buffer.byteLength > MAX_BACKUP_BYTES) {
        throw new AppError('Backup deve ter no máximo 50MB', 400, 'FILE_TOO_LARGE');
      }
      try {
        raw = JSON.parse(buffer.toString('utf8'));
      } catch {
        throw new AppError('Arquivo JSON inválido', 400, 'INVALID_JSON');
      }
    } else {
      raw = request.body;
    }

    const result = await service.restoreBackup(raw, userId);
    return reply.send({ success: true, data: result, message: 'Backup restaurado com sucesso' });
  });
}
