import { FastifyInstance } from 'fastify';
import { scheduleClient } from '../http-client';
import { parsePagination, validate, getAuthHeader } from '@church-app/shared';
import { z } from 'zod';

const scheduleSchema = z.object({
  eventId: z.string().uuid(),
  ministryId: z.string().uuid(),
  date: z.string(),
  startTime: z.string(),
  endTime: z.string(),
  positions: z.array(z.object({
    memberId: z.string().uuid(),
    position: z.string(),
  })),
});

const confirmSchema = z.object({
  scheduleId: z.string().uuid(),
  positionId: z.string().uuid(),
  confirmed: z.boolean(),
});

const substituteSchema = z.object({
  scheduleId: z.string().uuid(),
  positionId: z.string().uuid(),
  substituteMemberId: z.string().uuid(),
});

export async function scheduleRoutes(fastify: FastifyInstance) {
  fastify.get('/', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const { page, limit } = parsePagination(request.query);
    try {
      const data = await scheduleClient.get(`/schedules?page=${page}&limit=${limit}`, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get<{ Params: { id: string } }>('/:id', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await scheduleClient.get(`/schedules/${request.params.id}`, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = validate(scheduleSchema, request.body);
    try {
      const data = await scheduleClient.post('/schedules', body, getAuthHeader(request));
      await reply.status(201).send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.put<{ Params: { id: string } }>('/:id', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = validate(scheduleSchema.partial(), request.body);
    try {
      const data = await scheduleClient.put(`/schedules/${request.params.id}`, body, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.delete<{ Params: { id: string } }>('/:id', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await scheduleClient.delete(`/schedules/${request.params.id}`, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/confirm', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = validate(confirmSchema, request.body);
    try {
      const data = await scheduleClient.post('/schedules/confirm', body, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/substitute', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = validate(substituteSchema, request.body);
    try {
      const data = await scheduleClient.post('/schedules/substitute', body, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/my-schedules', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const userId = request.user.userId;
    try {
      const data = await scheduleClient.get(`/schedules/member/${userId}`, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get<{ Params: { memberId: string } }>('/conflicts/:memberId', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await scheduleClient.get(`/schedules/conflicts/${request.params.memberId}`, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });
}

