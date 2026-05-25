import Fastify from 'fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import jwt from '@fastify/jwt';
import { PrismaClient } from '@prisma/client';
import { AppError, logger } from '@church-app/shared';
import { authRoutes } from './routes/auth';

const prisma = new PrismaClient();
const fastify = Fastify({ logger: false });

async function bootstrap() {
  await prisma.$connect();

  await fastify.register(helmet, { contentSecurityPolicy: false });
  await fastify.register(cors, { origin: true, credentials: true });

  await fastify.register(jwt, {
    secret: process.env.JWT_SECRET!,
    sign: {
      expiresIn: process.env.JWT_EXPIRES_IN || '15m',
    },
  });

  fastify.decorate('prisma', prisma);

  fastify.get('/health', async () => ({ status: 'ok', service: 'auth-service' }));

  await fastify.register(authRoutes, { prefix: '/auth' });

  fastify.setErrorHandler((error, request, reply) => {
    logger.error('Error occurred', error, { path: request.url, method: request.method });
    if (error instanceof AppError) {
      return reply.status(error.statusCode).send({ success: false, message: error.message, code: error.code });
    }
    return reply.status(500).send({ success: false, message: 'Internal server error' });
  });

  const port = Number(process.env.PORT) || 3001;
  await fastify.listen({ port, host: '0.0.0.0' });
  logger.info(`Auth service running on port ${port}`);
}

bootstrap()
  .catch((err) => {
    logger.error('Failed to start server', err);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());