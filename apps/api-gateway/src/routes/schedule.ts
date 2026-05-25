import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { scheduleClient } from '../http-client';
import { parsePagination, validate } from '@church-app/shared';
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

export async function scheduleRoutes(fastify: FastifyInstance) {
  fastify.get('/', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest, reply: FastifyReply) => {
    const { page, limit } = parsePagination(request.query);
    try {
      const data = await scheduleClient.get(`/schedules?page=${page}&limit=${limit}`, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/:id', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    try {
      const data = await scheduleClient.get(`/schedules/${request.params.id}`, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest, reply: FastifyReply) => {
    const body = validate(scheduleSchema, request.body);
    try {
      const data = await scheduleClient.post('/schedules', body, getAuthHeader(request));
      return reply.status(201).send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.put('/:id', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const body = validate(scheduleSchema.partial(), request.body);
    try {
      const data = await scheduleClient.put(`/schedules/${request.params.id}`, body, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.delete('/:id', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    try {
      const data = await scheduleClient.delete(`/schedules/${request.params.id}`, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/confirm', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest, reply: FastifyReply) => {
    const body = validate(confirmSchema, request.body);
    try {
      const data = await scheduleClient.post('/schedules/confirm', body, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/substitute', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest, reply: FastifyReply) => {
    const { scheduleId, positionId, substituteMemberId } = request.body as {
      scheduleId: string;
      positionId: string;
      substituteMemberId: string;
    };
    try {
      const data = await scheduleClient.post('/schedules/substitute', { scheduleId, positionId, substituteMemberId }, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/my-schedules', { preHandler: [fastify.authenticate] }, async (request: any, reply: FastifyReply) => {
    const userId = request.user.userId;
    try {
      const data = await scheduleClient.get(`/schedules/member/${userId}`, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/conflicts/:memberId', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest<{ Params: { memberId: string } }>, reply: FastifyReply) => {
    try {
      const data = await scheduleClient.get(`/schedules/conflicts/${request.params.memberId}`, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });
}

function getAuthHeader(request: FastifyRequest): Record<string, string> {
  return { Authorization: request.headers.authorization as string };
}