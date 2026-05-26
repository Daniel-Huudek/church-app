import { FastifyInstance } from 'fastify';
import { financialClient } from '../http-client';
import { getAuthHeader, validate } from '@church-app/shared';
import { z } from 'zod';

const transactionSchema = z.object({
  type: z.enum(['RECEITA', 'DESPESA']),
  value: z.number().positive(),
  description: z.string().min(1),
  date: z.string(),
  categoryId: z.string().uuid(),
  costCenterId: z.string().uuid().optional(),
  paymentMethod: z.string().optional(),
  notes: z.string().optional(),
  status: z.enum(['PENDENTE', 'CONFIRMADO', 'CANCELADO']).optional(),
});

const categorySchema = z.object({
  name: z.string().min(1),
  type: z.enum(['RECEITA', 'DESPESA']),
  color: z.string().optional(),
  icon: z.string().optional(),
});

const costCenterSchema = z.object({
  name: z.string().min(1),
  description: z.string().optional(),
});

const monthlyCloseSchema = z.object({
  referenceDate: z.string(),
  notes: z.string().optional(),
});

export async function financeRoutes(fastify: FastifyInstance) {
  fastify.get('/transactions', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const { page, limit, type, status, categoryId, costCenterId, startDate, endDate, search } = request.query as Record<string, string>;
    let url = `/finance/transactions?page=${page || 1}&limit=${limit || 20}`;
    if (type) url += `&type=${type}`;
    if (status) url += `&status=${status}`;
    if (categoryId) url += `&categoryId=${categoryId}`;
    if (costCenterId) url += `&costCenterId=${costCenterId}`;
    if (startDate) url += `&startDate=${startDate}`;
    if (endDate) url += `&endDate=${endDate}`;
    if (search) url += `&search=${search}`;
    try {
      const data = await financialClient.get(url, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get<{ Params: { id: string } }>('/transactions/:id', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await financialClient.get(`/finance/transactions/${request.params.id}`, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/transactions', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = validate(transactionSchema, request.body);
    try {
      const data = await financialClient.post('/finance/transactions', body, getAuthHeader(request));
      await reply.status(201).send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.put<{ Params: { id: string } }>('/transactions/:id', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = validate(transactionSchema.partial(), request.body);
    try {
      const data = await financialClient.put(`/finance/transactions/${request.params.id}`, body, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.delete<{ Params: { id: string } }>('/transactions/:id', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await financialClient.delete(`/finance/transactions/${request.params.id}`, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post<{ Params: { id: string } }>('/transactions/:id/confirm', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await financialClient.post(`/finance/transactions/${request.params.id}/confirm`, {}, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post<{ Params: { id: string } }>('/transactions/:id/cancel', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await financialClient.post(`/finance/transactions/${request.params.id}/cancel`, {}, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post<{ Params: { id: string } }>('/transactions/:id/attachments', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await financialClient.post(`/finance/transactions/${request.params.id}/attachments`, request.body, getAuthHeader(request));
      await reply.status(201).send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get<{ Params: { id: string } }>('/transactions/:id/audit', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const { page, limit } = request.query as Record<string, string>;
    try {
      const data = await financialClient.get(`/finance/transactions/${request.params.id}/audit?page=${page || 1}&limit=${limit || 20}`, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/categories', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await financialClient.get('/finance/categories', getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/categories', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = validate(categorySchema, request.body);
    try {
      const data = await financialClient.post('/finance/categories', body, getAuthHeader(request));
      await reply.status(201).send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.put<{ Params: { id: string } }>('/categories/:id', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = validate(categorySchema.partial(), request.body);
    try {
      const data = await financialClient.put(`/finance/categories/${request.params.id}`, body, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/cost-centers', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await financialClient.get('/finance/cost-centers', getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/cost-centers', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = validate(costCenterSchema, request.body);
    try {
      const data = await financialClient.post('/finance/cost-centers', body, getAuthHeader(request));
      await reply.status(201).send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.put<{ Params: { id: string } }>('/cost-centers/:id', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = validate(costCenterSchema.partial(), request.body);
    try {
      const data = await financialClient.put(`/finance/cost-centers/${request.params.id}`, body, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/dashboard', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await financialClient.get('/finance/dashboard', getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/dashboard/balance', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await financialClient.get('/finance/dashboard/balance', getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/dashboard/cash-flow', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await financialClient.get('/finance/dashboard/cash-flow', getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/reports/monthly', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const { year, month } = request.query as Record<string, string>;
    try {
      const data = await financialClient.get(`/finance/reports/monthly?year=${year || new Date().getFullYear()}&month=${month || new Date().getMonth() + 1}`, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/monthly-close', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = validate(monthlyCloseSchema, request.body);
    try {
      const data = await financialClient.post('/finance/monthly-close', body, getAuthHeader(request));
      await reply.status(201).send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/monthly-close', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      const data = await financialClient.get('/finance/monthly-close', getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/audit', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const { page, limit } = request.query as Record<string, string>;
    try {
      const data = await financialClient.get(`/finance/audit?page=${page || 1}&limit=${limit || 20}`, getAuthHeader(request));
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });
}
