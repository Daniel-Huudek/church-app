import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { financialClient } from '../http-client';

export async function financeRoutes(fastify: FastifyInstance) {
  fastify.get('/transactions', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest, reply: FastifyReply) => {
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
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/transactions/:id', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    try {
      const data = await financialClient.get(`/finance/transactions/${request.params.id}`, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/transactions', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest, reply: FastifyReply) => {
    try {
      const data = await financialClient.post('/finance/transactions', request.body, getAuthHeader(request));
      return reply.status(201).send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.put('/transactions/:id', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    try {
      const data = await financialClient.put(`/finance/transactions/${request.params.id}`, request.body, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.delete('/transactions/:id', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    try {
      const data = await financialClient.delete(`/finance/transactions/${request.params.id}`, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/transactions/:id/confirm', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    try {
      const data = await financialClient.post(`/finance/transactions/${request.params.id}/confirm`, {}, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/transactions/:id/cancel', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    try {
      const data = await financialClient.post(`/finance/transactions/${request.params.id}/cancel`, {}, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/transactions/:id/attachments', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    try {
      const data = await financialClient.post(`/finance/transactions/${request.params.id}/attachments`, request.body, getAuthHeader(request));
      return reply.status(201).send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/transactions/:id/audit', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const { page, limit } = request.query as Record<string, string>;
    try {
      const data = await financialClient.get(`/finance/transactions/${request.params.id}/audit?page=${page || 1}&limit=${limit || 20}`, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/categories', { preHandler: [fastify.authenticate] }, async (_request: FastifyRequest, reply: FastifyReply) => {
    try {
      const data = await financialClient.get('/finance/categories', getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/categories', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest, reply: FastifyReply) => {
    try {
      const data = await financialClient.post('/finance/categories', request.body, getAuthHeader(request));
      return reply.status(201).send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.put('/categories/:id', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    try {
      const data = await financialClient.put(`/finance/categories/${request.params.id}`, request.body, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/cost-centers', { preHandler: [fastify.authenticate] }, async (_request: FastifyRequest, reply: FastifyReply) => {
    try {
      const data = await financialClient.get('/finance/cost-centers', getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/cost-centers', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest, reply: FastifyReply) => {
    try {
      const data = await financialClient.post('/finance/cost-centers', request.body, getAuthHeader(request));
      return reply.status(201).send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.put('/cost-centers/:id', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    try {
      const data = await financialClient.put(`/finance/cost-centers/${request.params.id}`, request.body, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/dashboard', { preHandler: [fastify.authenticate] }, async (_request: FastifyRequest, reply: FastifyReply) => {
    try {
      const data = await financialClient.get('/finance/dashboard', getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/dashboard/balance', { preHandler: [fastify.authenticate] }, async (_request: FastifyRequest, reply: FastifyReply) => {
    try {
      const data = await financialClient.get('/finance/dashboard/balance', getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/dashboard/cash-flow', { preHandler: [fastify.authenticate] }, async (_request: FastifyRequest, reply: FastifyReply) => {
    try {
      const data = await financialClient.get('/finance/dashboard/cash-flow', getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/reports/monthly', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest, reply: FastifyReply) => {
    const { year, month } = request.query as Record<string, string>;
    try {
      const data = await financialClient.get(`/finance/reports/monthly?year=${year || new Date().getFullYear()}&month=${month || new Date().getMonth() + 1}`, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.post('/monthly-close', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest, reply: FastifyReply) => {
    try {
      const data = await financialClient.post('/finance/monthly-close', request.body, getAuthHeader(request));
      return reply.status(201).send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/monthly-close', { preHandler: [fastify.authenticate] }, async (_request: FastifyRequest, reply: FastifyReply) => {
    try {
      const data = await financialClient.get('/finance/monthly-close', getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });

  fastify.get('/audit', { preHandler: [fastify.authenticate] }, async (request: FastifyRequest, reply: FastifyReply) => {
    const { page, limit } = request.query as Record<string, string>;
    try {
      const data = await financialClient.get(`/finance/audit?page=${page || 1}&limit=${limit || 20}`, getAuthHeader(request));
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({ success: false, message: error.message });
    }
  });
}

function getAuthHeader(request: FastifyRequest): Record<string, string> {
  return { Authorization: request.headers.authorization as string };
}
