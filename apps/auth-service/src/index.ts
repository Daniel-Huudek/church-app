import Fastify from 'fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import jwt from '@fastify/jwt';
import { PrismaClient } from '@prisma/client';
import { AppError, logger } from '@church-app/shared';
import { authRoutes } from './routes/auth';

const prisma = new PrismaClient();
const fastify = Fastify({ logger: false });

async function connectWithRetry(attempts = 10, delayMs = 2000): Promise<void> {
  let lastError: unknown;
  for (let i = 1; i <= attempts; i++) {
    try {
      await prisma.$connect();
      return;
    } catch (err) {
      lastError = err;
      logger.error(`Prisma connect failed (attempt ${i}/${attempts})`, err as Error);
      if (i < attempts) {
        await new Promise((resolve) => setTimeout(resolve, delayMs));
      }
    }
  }
  throw lastError;
}

async function bootstrap() {
  if (!process.env.JWT_SECRET) {
    throw new Error('JWT_SECRET environment variable is required');
  }

  await connectWithRetry();

  await fastify.register(helmet, { contentSecurityPolicy: false });
  await fastify.register(cors, { origin: true, credentials: true });

  await fastify.register(jwt, {
    secret: process.env.JWT_SECRET,
    sign: {
      expiresIn: process.env.JWT_EXPIRES_IN || '2h',
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
    if (error.validation) {
      return reply.status(400).send({ success: false, message: 'Validation error', details: error.validation });
    }
    return reply.status(500).send({ success: false, message: 'Internal server error' });
  });

  const port = Number(process.env.PORT) || 3001;
  await fastify.listen({ port, host: '0.0.0.0' });
  logger.info(`Auth service running on port ${port}`);
}

async function shutdown() {
  try {
    await fastify.close();
  } catch {
    /* ignore */
  }
  try {
    await prisma.$disconnect();
  } catch {
    /* ignore */
  }
  process.exit(0);
}

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);

bootstrap().catch((err) => {
  logger.error('Failed to start server', err);
  process.exit(1);
});
