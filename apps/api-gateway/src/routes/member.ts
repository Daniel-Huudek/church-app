import { FastifyInstance } from 'fastify';
import { memberClient } from '../http-client';
import { validate, getAuthHeader } from '@church-app/shared';
import { z } from 'zod';

const memberSchema = z.object({
  name: z.string().min(1),
  email: z.string().email().optional(),
  phone: z.string().optional(),
  dateOfBirth: z.string().optional(),
  gender: z.string().optional(),
  maritalStatus: z.string().optional(),
  baptismDate: z.string().optional(),
  baptismChurch: z.string().optional(),
  conversionDate: z.string().optional(),
  isBaptized: z.boolean().default(false),
  status: z.enum(['ATIVO', 'INATIVO', 'AFASTADO', 'TRANSFERIDO', 'EXCLUIDO']).default('ATIVO'),
  role: z.enum(['MEMBRO', 'DIACONO', 'PRESBITERO', 'PASTOR']).default('MEMBRO'),
  ministryId: z.string().uuid().optional(),
  occupation: z.string().optional(),
  notes: z.string().optional(),
});

const importSchema = z.object({ records: z.array(z.record(z.string(), z.unknown())) });

const addressSchema = z.object({
  street: z.string().min(1), number: z.string().optional(), complement: z.string().optional(),
  neighborhood: z.string().min(1), city: z.string().min(1), state: z.string().min(1), zipCode: z.string().min(1),
});

const documentSchema = z.object({ type: z.string().min(1), value: z.string().min(1) });

const familySchema = z.object({
  name: z.string().min(1), kinship: z.string().min(1), phone: z.string().optional(),
});

const historySchema = z.object({
  ministry: z.string().min(1), role: z.string().min(1), startDate: z.string(),
  endDate: z.string().optional(), description: z.string().optional(),
});

export async function memberRoutes(fastify: FastifyInstance) {
  fastify.get('/', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const { page, limit, name, email, status, role, ministryId, birthdayMonth } = request.query as Record<string, string>;
    let url = `/members?page=${page || 1}&limit=${limit || 20}`;
    if (name) url += `&name=${name}`;
    if (email) url += `&email=${email}`;
    if (status) url += `&status=${status}`;
    if (role) url += `&role=${role}`;
    if (ministryId) url += `&ministryId=${ministryId}`;
    if (birthdayMonth) url += `&birthdayMonth=${birthdayMonth}`;
    try {
      const data = await memberClient.get(url, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/search', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const { q, page, limit } = request.query as Record<string, string>;
    try {
      const data = await memberClient.get(`/members/search?q=${q || ''}&page=${page || 1}&limit=${limit || 20}`, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/export', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await memberClient.get('/members/export', getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/import', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = validate(importSchema, request.body);
    try {
      const data = await memberClient.post('/members/import', body, getAuthHeader(request));
      await reply.status(201).send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get<{ Params: { id: string } }>('/:id', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await memberClient.get(`/members/${request.params.id}`, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = validate(memberSchema, request.body);
    try {
      const data = await memberClient.post('/members', body, getAuthHeader(request));
      await reply.status(201).send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.put<{ Params: { id: string } }>('/:id', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = validate(memberSchema.partial(), request.body);
    try {
      const data = await memberClient.put(`/members/${request.params.id}`, body, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.delete<{ Params: { id: string } }>('/:id', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await memberClient.delete(`/members/${request.params.id}`, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get<{ Params: { id: string } }>('/:id/address', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await memberClient.get(`/members/${request.params.id}/address`, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.put<{ Params: { id: string } }>('/:id/address', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = validate(addressSchema, request.body);
    try {
      const data = await memberClient.put(`/members/${request.params.id}/address`, body, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get<{ Params: { id: string } }>('/:id/documents', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await memberClient.get(`/members/${request.params.id}/documents`, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post<{ Params: { id: string } }>('/:id/documents', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = validate(documentSchema, request.body);
    try {
      const data = await memberClient.post(`/members/${request.params.id}/documents`, body, getAuthHeader(request));
      await reply.status(201).send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.delete<{ Params: { id: string; docId: string } }>('/:id/documents/:docId', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await memberClient.delete(`/members/${request.params.id}/documents/${request.params.docId}`, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get<{ Params: { id: string } }>('/:id/family', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await memberClient.get(`/members/${request.params.id}/family`, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post<{ Params: { id: string } }>('/:id/family', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = validate(familySchema, request.body);
    try {
      const data = await memberClient.post(`/members/${request.params.id}/family`, body, getAuthHeader(request));
      await reply.status(201).send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.delete<{ Params: { id: string; familyId: string } }>('/:id/family/:familyId', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await memberClient.delete(`/members/${request.params.id}/family/${request.params.familyId}`, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get<{ Params: { id: string } }>('/:id/history', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await memberClient.get(`/members/${request.params.id}/history`, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post<{ Params: { id: string } }>('/:id/history', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = validate(historySchema, request.body);
    try {
      const data = await memberClient.post(`/members/${request.params.id}/history`, body, getAuthHeader(request));
      await reply.status(201).send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post<{ Params: { id: string } }>('/:id/photo', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await memberClient.post(`/members/${request.params.id}/photo`, request.body, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get<{ Params: { id: string } }>('/:id/audit', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await memberClient.get(`/members/${request.params.id}/audit`, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/me', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const userId = request.user.userId;
      const data = await memberClient.get(`/members/user/${userId}`, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });
}
