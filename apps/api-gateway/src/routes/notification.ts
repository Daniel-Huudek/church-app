import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { notificationClient } from '../http-client';
import { parsePagination, validate } from '../shared';
import { z } from 'zod';

const notificationSchema = z.object({
  type: z.enum(['SCHEDULE_REMINDER', 'ATTENDANCE_CONFIRMATION', 'GENERAL']),
  recipientId: z.string().uuid(),
  message: z.string().min(1),
  phone: z.string(),
});

const bulkNotificationSchema = z.object({
  type: z.enum(['SCHEDULE_REMINDER', 'ATTENDANCE_CONFIRMATION', 'GENERAL']),
  recipientIds: z.array(z.string().uuid()),
  message: z.string().min(1),
});

export async function notificationRoutes(fastify: FastifyInstance) {
  fastify.get('/', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest, reply: FastifyReply) => {
    const { page, limit } = parsePagination(request.query);
    try {
      const data = await notificationClient.get(`/notifications?page=${page}&limit=${limit}`, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest, reply: FastifyReply) => {
    const body = validate(notificationSchema, request.body);
    try {
      const data = await notificationClient.post('/notifications', body, getAuthHeader(request));
      return reply.status(201).send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/bulk', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest, reply: FastifyReply) => {
    const body = validate(bulkNotificationSchema, request.body);
    try {
      const data = await notificationClient.post('/notifications/bulk', body, getAuthHeader(request));
      return reply.status(201).send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/schedule-reminder/:scheduleId', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest<{ Params: { scheduleId: string } }>, reply: FastifyReply) => {
    try {
      const data = await notificationClient.post(`/notifications/schedule/${request.params.scheduleId}/reminder`, {}, getAuthHeader(request));
      return reply.status(201).send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/history/:recipientId', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest<{ Params: { recipientId: string } }>, reply: FastifyReply) => {
    try {
      const data = await notificationClient.get(`/notifications/history/${request.params.recipientId}`, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });
}

function getAuthHeader(request: FastifyRequest): Record<string, string> {
  return { Authorization: request.headers.authorization as string };
}