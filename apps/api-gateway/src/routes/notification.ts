import { FastifyInstance } from 'fastify';
import { notificationClient } from '../http-client';
import { parsePagination, validate, getAuthHeader } from '@church-app/shared';
import { z } from 'zod';

const notificationSchema = z.object({
  type: z.enum(['SCHEDULE_REMINDER', 'ATTENDANCE_CONFIRMATION', 'GENERAL']),
  recipientId: z.string().uuid(),
  message: z.string().min(1),
  phone: z.string(),
});

const bulkNotificationSchema = z.object({
  type: z.enum(['SCHEDULE_REMINDER', 'ATTENDANCE_CONFIRMATION', 'GENERAL']),
  recipients: z.array(z.object({
    recipientId: z.string().uuid(),
    phone: z.string().min(1),
  })).min(1),
  message: z.string().min(1),
});

export async function notificationRoutes(fastify: FastifyInstance) {
  fastify.get('/', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const { page, limit } = parsePagination(request.query);
    try {
      const data = await notificationClient.get(`/notifications?page=${page}&limit=${limit}`, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/unread-count', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const { recipientId } = request.query as Record<string, string | undefined>;
    const targetRecipientId = recipientId || request.user.userId;
    try {
      const data = await notificationClient.get(`/notifications/unread-count?recipientId=${encodeURIComponent(targetRecipientId)}`, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/read-all', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = request.body as { recipientId?: string } | undefined;
    const targetRecipientId = body?.recipientId || request.user.userId;
    try {
      const data = await notificationClient.post('/notifications/read-all', { recipientId: targetRecipientId }, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = validate(notificationSchema, request.body);
    try {
      const data = await notificationClient.post('/notifications', body, getAuthHeader(request));
      await reply.status(201).send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/bulk', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = validate(bulkNotificationSchema, request.body);
    try {
      const data = await notificationClient.post('/notifications/bulk', body, getAuthHeader(request));
      await reply.status(201).send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post<{ Params: { scheduleId: string } }>('/schedule-reminder/:scheduleId', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await notificationClient.post(`/notifications/schedule/${request.params.scheduleId}/reminder`, {}, getAuthHeader(request));
      await reply.status(201).send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get<{ Params: { recipientId: string } }>('/history/:recipientId', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await notificationClient.get(`/notifications/history/${request.params.recipientId}`, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });
}

