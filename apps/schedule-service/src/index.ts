import Fastify from 'fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import { PrismaClient } from '@prisma/client';
import { AppError, logger } from '@church-app/shared';
import { scheduleRoutes } from './routes/index';

const prisma = new PrismaClient();
const fastify = Fastify({ logger: false });

async function bootstrap() {
  await prisma.$connect();
  await fastify.register(helmet, { contentSecurityPolicy: false });
  await fastify.register(cors, { origin: true, credentials: true });
  fastify.decorate('prisma', prisma);
  fastify.get('/health', async () => ({ status: 'ok', service: 'schedule-service' }));
  await fastify.register(scheduleRoutes, { prefix: '/schedules' });
  fastify.setErrorHandler((error, request, reply) => {
    logger.error('Error', error, { path: request.url });
    if (error instanceof AppError) return reply.status(error.statusCode).send({ success: false, message: error.message });
    if (error.validation) return reply.status(400).send({ success: false, message: 'Validation error', details: error.validation });
    return reply.status(500).send({ success: false, message: 'Internal server error' });
  });
  const port = Number(process.env.PORT) || 3003;
  await fastify.listen({ port, host: '0.0.0.0' });
  logger.info(`Schedule service running on port ${port}`);
}


process.on('SIGTERM', async () => {
  try { await prisma.$disconnect(); } catch { /* ignore */ }
  process.exit(0);
});
process.on('SIGINT', async () => {
  try { await prisma.$disconnect(); } catch { /* ignore */ }
  process.exit(0);
});

bootstrap().catch((err) => { logger.error('Failed', err); process.exit(1); });