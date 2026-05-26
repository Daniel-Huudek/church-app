import Fastify from 'fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import { PrismaClient } from '@prisma/client';
import { AppError, logger } from '@church-app/shared';
import { chatRoutes } from './routes/chat.js';

const prisma = new PrismaClient();
const fastify = Fastify({ logger: false });

async function bootstrap() {
  await prisma.$connect();

  await fastify.register(helmet, { contentSecurityPolicy: false });
  await fastify.register(cors, { origin: true, credentials: true });

  fastify.decorate('prisma', prisma);

  fastify.get('/health', async () => ({ status: 'ok', service: 'chat-service' }));

  await fastify.register(chatRoutes, { prefix: '/chats' });

  fastify.setErrorHandler((error, request, reply) => {
    logger.error('Error', error, { path: request.url });
    if (error instanceof AppError) {
      return reply.status(error.statusCode).send({ success: false, message: error.message });
    }
    return reply.status(500).send({ success: false, message: 'Internal server error' });
  });

  const port = Number(process.env.PORT) || 3002;
  await fastify.listen({ port, host: '0.0.0.0' });
  logger.info(`Chat service running on port ${port}`);
}

bootstrap()
  .catch((err) => {
    logger.error('Failed to start server', err);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
