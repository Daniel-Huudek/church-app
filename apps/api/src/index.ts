import './fastify.d.ts';
import Fastify from 'fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import rateLimit from '@fastify/rate-limit';
import jwt from '@fastify/jwt';
import multipart from '@fastify/multipart';
import { PrismaClient } from '@prisma/client';
import { AppError, logger } from '@church-app/shared';

import { authRoutes } from './modules/auth/routes.js';
import { memberRoutes, ministryRoutes } from './modules/members/routes.js';
import { scheduleRoutes } from './modules/schedules/routes.js';
import { eventRoutes } from './modules/events/routes.js';
import { notificationRoutes } from './modules/notifications/routes.js';
import { prayerRoutes } from './modules/prayers/routes.js';
import { financeRoutes } from './modules/finance/routes.js';
import { worshipRoutes } from './modules/worship/routes.js';
import { chatRoutes } from './modules/chat/routes.js';
import { userRoutes } from './routes/users.js';

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

  const corsOrigin = process.env.CORS_ORIGIN
    ? process.env.CORS_ORIGIN.split(',').map((s) => s.trim())
    : true;

  await fastify.register(cors, {
    origin: corsOrigin,
    credentials: true,
  });

  await fastify.register(rateLimit, {
    max: 200,
    timeWindow: '1 minute',
  });

  await fastify.register(multipart, { limits: { fileSize: 10 * 1024 * 1024 } });

  await fastify.register(jwt, {
    secret: process.env.JWT_SECRET,
    sign: {
      expiresIn: process.env.JWT_EXPIRES_IN || '15m',
    },
  });

  fastify.decorate('prisma', prisma);

  // Gateway-compatible helper (also used by some shared requireRoles callers)
  fastify.decorate('authenticate', async function (request: any, reply: any) {
    try {
      await request.jwtVerify();
    } catch {
      reply.status(401).send({ success: false, message: 'Unauthorized' });
    }
  });

  fastify.get('/health', async () => ({ status: 'ok', service: 'api' }));

  // Public API surface (same prefixes as former api-gateway)
  await fastify.register(authRoutes, { prefix: '/auth' });
  await fastify.register(userRoutes, { prefix: '/users' });
  await fastify.register(memberRoutes, { prefix: '/members' });
  await fastify.register(ministryRoutes, { prefix: '/members/ministries' });
  await fastify.register(scheduleRoutes, { prefix: '/schedules' });
  await fastify.register(eventRoutes, { prefix: '/events' });
  await fastify.register(notificationRoutes, { prefix: '/notifications' });
  await fastify.register(prayerRoutes, { prefix: '/prayers' });
  await fastify.register(financeRoutes, { prefix: '/finance' });
  await fastify.register(worshipRoutes, { prefix: '/worship' });
  await fastify.register(chatRoutes, { prefix: '/chats' });

  fastify.setErrorHandler((error, request, reply) => {
    logger.error('Error occurred', error, { path: request.url, method: request.method });

    if (error instanceof AppError) {
      return reply.status(error.statusCode).send({
        success: false,
        message: error.message,
        code: error.code,
      });
    }

    if (error.validation) {
      return reply.status(400).send({
        success: false,
        message: 'Validation error',
        details: error.validation,
      });
    }

    return reply.status(500).send({
      success: false,
      message: 'Internal server error',
    });
  });

  const port = Number(process.env.PORT) || 3030;
  await fastify.listen({ port, host: '0.0.0.0' });
  logger.info(`API (modular monolith) running on port ${port}`);
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
