import Fastify from 'fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import multipart from '@fastify/multipart';
import { PrismaClient } from '@prisma/client';
import { AppError, logger } from '@church-app/shared';
import { memberRoutes, ministryRoutes } from './routes/index';

const prisma = new PrismaClient();
const fastify = Fastify({ logger: false });

async function bootstrap() {
  await prisma.$connect();
  await fastify.register(helmet, { contentSecurityPolicy: false });
  await fastify.register(cors, { origin: true, credentials: true });
  await fastify.register(multipart, {
    limits: { fileSize: 5 * 1024 * 1024 },
  });

  fastify.decorate('prisma', prisma);

  fastify.get('/health', async () => ({ status: 'ok', service: 'member-service' }));

  await fastify.register(memberRoutes, { prefix: '/members' });
  await fastify.register(ministryRoutes, { prefix: '/ministries' });

  fastify.setErrorHandler((error, request, reply) => {
    logger.error('Error', error, { path: request.url });
    if (error instanceof AppError) {
      return reply.status(error.statusCode).send({ success: false, message: error.message, code: error.code });
    }
    if (error.validation) {
      return reply.status(400).send({ success: false, message: 'Validation error', details: error.validation });
    }
    return reply.status(500).send({ success: false, message: 'Internal server error' });
  });

  const port = Number(process.env.PORT) || 3006;
  await fastify.listen({ port, host: '0.0.0.0' });
  logger.info(`Member service running on port ${port}`);
}

bootstrap().catch((err) => { logger.error('Failed', err); process.exit(1); }).finally(() => prisma.$disconnect());
