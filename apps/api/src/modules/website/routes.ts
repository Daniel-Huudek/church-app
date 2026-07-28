import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { AppError, authenticate, authorize, requireAuthUser, validate } from '@church-app/shared';
import { uploadWebsiteImage, type WebsiteUploadKind } from '../../lib/s3.js';
import { WebsiteService } from './service.js';
import { websiteContentSchema } from './schema.js';

const uploadKindSchema = z.enum(['leadership', 'series', 'news', 'general']);

export async function websiteRoutes(fastify: FastifyInstance) {
  const service = new WebsiteService(fastify.prisma);

  // Public — site institucional
  fastify.get('/', async () => {
    const data = await service.getPublic();
    return { success: true, data };
  });

  await fastify.register(async (secured) => {
    secured.addHook('preHandler', authenticate());
    const adminOnly = authorize('ADMINISTRADOR', 'PASTOR');

    secured.get('/admin', { preHandler: [adminOnly] }, async () => {
      const data = await service.getPublic();
      return { success: true, data };
    });

    secured.put('/', { preHandler: [adminOnly] }, async (request) => {
      const { userId } = requireAuthUser(request);
      const body = validate(websiteContentSchema, request.body);
      const data = await service.upsert(body, userId);
      return { success: true, data };
    });

    secured.post('/uploads', { preHandler: [adminOnly] }, async (request, reply) => {
      const query = request.query as { kind?: string };
      const kind = validate(uploadKindSchema, query.kind || 'general') as WebsiteUploadKind;

      const data = await request.file();
      if (!data) {
        throw new AppError('Nenhum arquivo enviado', 400, 'NO_FILE');
      }

      const buffer = await data.toBuffer();

      if (buffer.byteLength === 0) {
        throw new AppError('Arquivo vazio', 400, 'EMPTY_FILE');
      }
      if (buffer.byteLength > 8 * 1024 * 1024) {
        throw new AppError('Imagem deve ter no máximo 8MB', 400, 'FILE_TOO_LARGE');
      }

      const uploaded = await uploadWebsiteImage({
        kind,
        filename: data.filename,
        buffer,
        mimeType: data.mimetype,
      });

      return reply.status(201).send({
        success: true,
        data: uploaded,
      });
    });
  });
}
