import Fastify from 'fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import rateLimit from '@fastify/rate-limit';
import jwt from '@fastify/jwt';
import { AppError } from './shared/index.js';
import { authRoutes } from './routes/auth';
import { userRoutes } from './routes/user';
import { scheduleRoutes } from './routes/schedule';
import { eventRoutes } from './routes/event';
import { notificationRoutes } from './routes/notification';
import { logger } from './logger';

const fastify = Fastify({
  logger: false,
});

async function bootstrap() {
  await fastify.register(helmet, {
    contentSecurityPolicy: false,
  });

  await fastify.register(cors, {
    origin: true,
    credentials: true,
  });

  await fastify.register(rateLimit, {
    max: 100,
    timeWindow: '1 minute',
  });

  await fastify.register(jwt, {
    secret: process.env.JWT_SECRET || 'default-secret-change-me',
    sign: {
      expiresIn: process.env.JWT_EXPIRES_IN || '15m',
    },
  });

  fastify.decorate('authenticate', async function (request: any, reply: any) {
    try {
      await request.jwtVerify();
    } catch (err) {
      reply.status(401).send({ success: false, message: 'Unauthorized' });
    }
  });

  fastify.get('/health', async () => ({ status: 'ok', service: 'api-gateway' }));

  await fastify.register(authRoutes, { prefix: '/auth' });
  await fastify.register(userRoutes, { prefix: '/users' });
  await fastify.register(scheduleRoutes, { prefix: '/schedules' });
  await fastify.register(eventRoutes, { prefix: '/events' });
  await fastify.register(notificationRoutes, { prefix: '/notifications' });

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

  const port = Number(process.env.PORT) || 3000;
  await fastify.listen({ port, host: '0.0.0.0' });

  logger.info(`API Gateway running on port ${port}`);
}

bootstrap().catch((err) => {
  logger.error('Failed to start server', err);
  process.exit(1);
});