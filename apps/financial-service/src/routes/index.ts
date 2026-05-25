import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { validate, parsePagination, authorize } from '@church-app/shared';
import { z } from 'zod';
import { FinanceService } from '../services/finance.service';

const transactionSchema = z.object({
  type: z.enum(['INCOME', 'EXPENSE', 'TITHE', 'OFFERING']),
  value: z.number().positive(),
  description: z.string().optional(),
  date: z.string(),
  dueDate: z.string().optional(),
  paymentDate: z.string().optional(),
  categoryId: z.string().uuid().optional(),
  costCenterId: z.string().uuid().optional(),
  status: z.enum(['PENDING', 'CONFIRMED', 'CANCELLED']).default('PENDING'),
  paymentMethod: z.string().optional(),
  isRecurring: z.boolean().default(false),
  recurrenceRule: z.string().optional(),
  notes: z.string().optional(),
});

const categorySchema = z.object({
  name: z.string().min(1),
  type: z.enum(['INCOME', 'EXPENSE', 'TITHE', 'OFFERING']),
  description: z.string().optional(),
  color: z.string().optional(),
});

const costCenterSchema = z.object({
  name: z.string().min(1),
  description: z.string().optional(),
  budget: z.number().positive().optional(),
});

const monthlyCloseSchema = z.object({
  referenceDate: z.string(),
  notes: z.string().optional(),
});

export async function financeRoutes(fastify: FastifyInstance) {
  const service = new FinanceService(fastify.prisma);

  // Transactions - PASTOR can read, only ADMINISTRADOR/FINANCEIRO can write
  fastify.get('/transactions', { preHandler: [authorize('ADMINISTRADOR', 'PASTOR', 'FINANCEIRO')] }, async (request: FastifyRequest, reply: FastifyReply) => {
    const { page, limit } = parsePagination(request.query);
    const { type, status, categoryId, costCenterId, startDate, endDate, search } = request.query as any;
    const data = await service.findAllTransactions({
      page, limit, type, status, categoryId, costCenterId, startDate, endDate, search,
    });
    return reply.send(data);
  });

  fastify.get('/transactions/:id', { preHandler: [authorize('ADMINISTRADOR', 'PASTOR', 'FINANCEIRO')] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const data = await service.findTransactionById(request.params.id);
    return reply.send(data);
  });

  fastify.post('/transactions', { preHandler: [authorize('ADMINISTRADOR', 'FINANCEIRO')] }, async (request: FastifyRequest, reply: FastifyReply) => {
    const body = validate(transactionSchema, request.body);
    const userId = (request as any).user.userId;
    const userRole = (request as any).user.role;
    const data = await service.createTransaction(body, userId, userRole);
    return reply.status(201).send(data);
  });

  fastify.put('/transactions/:id', { preHandler: [authorize('ADMINISTRADOR', 'FINANCEIRO')] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const body = validate(transactionSchema.partial(), request.body);
    const userId = (request as any).user.userId;
    const userRole = (request as any).user.role;
    const data = await service.updateTransaction(request.params.id, body, userId, userRole);
    return reply.send(data);
  });

  fastify.delete('/transactions/:id', { preHandler: [authorize('ADMINISTRADOR', 'FINANCEIRO')] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const userId = (request as any).user.userId;
    const userRole = (request as any).user.role;
    await service.deleteTransaction(request.params.id, userId, userRole);
    return reply.send({ success: true });
  });

  fastify.post('/transactions/:id/confirm', { preHandler: [authorize('ADMINISTRADOR', 'FINANCEIRO')] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const userId = (request as any).user.userId;
    const userRole = (request as any).user.role;
    const data = await service.confirmTransaction(request.params.id, userId, userRole);
    return reply.send(data);
  });

  fastify.post('/transactions/:id/cancel', { preHandler: [authorize('ADMINISTRADOR', 'FINANCEIRO')] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const userId = (request as any).user.userId;
    const userRole = (request as any).user.role;
    const data = await service.cancelTransaction(request.params.id, userId, userRole);
    return reply.send(data);
  });

  fastify.post('/transactions/:id/attachments', { preHandler: [authorize('ADMINISTRADOR', 'FINANCEIRO')] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const userId = (request as any).user.userId;
    const file = await request.file();
    if (!file) {
      return reply.status(400).send({ success: false, message: 'No file uploaded' });
    }
    const buffer = await file.toBuffer();
    const data = await service.addAttachment(request.params.id, { filename: file.filename, buffer, mimetype: file.mimetype }, userId);
    return reply.status(201).send(data);
  });

  fastify.get('/transactions/:id/audit', { preHandler: [authorize('ADMINISTRADOR', 'FINANCEIRO')] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const { page, limit } = parsePagination(request.query);
    const data = await service.getAuditLogs({ page, limit, transactionId: request.params.id });
    return reply.send(data);
  });

  // Categories
  fastify.get('/categories', { preHandler: [authorize('ADMINISTRADOR', 'PASTOR', 'FINANCEIRO')] }, async (_request: FastifyRequest, reply: FastifyReply) => {
    const data = await service.findAllCategories();
    return reply.send(data);
  });

  fastify.post('/categories', { preHandler: [authorize('ADMINISTRADOR', 'FINANCEIRO')] }, async (request: FastifyRequest, reply: FastifyReply) => {
    const body = validate(categorySchema, request.body);
    const data = await service.createCategory(body);
    return reply.status(201).send(data);
  });

  fastify.put('/categories/:id', { preHandler: [authorize('ADMINISTRADOR', 'FINANCEIRO')] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const body = validate(categorySchema.partial(), request.body);
    const data = await service.updateCategory(request.params.id, body);
    return reply.send(data);
  });

  // Cost Centers
  fastify.get('/cost-centers', { preHandler: [authorize('ADMINISTRADOR', 'PASTOR', 'FINANCEIRO')] }, async (_request: FastifyRequest, reply: FastifyReply) => {
    const data = await service.findAllCostCenters();
    return reply.send(data);
  });

  fastify.post('/cost-centers', { preHandler: [authorize('ADMINISTRADOR', 'FINANCEIRO')] }, async (request: FastifyRequest, reply: FastifyReply) => {
    const body = validate(costCenterSchema, request.body);
    const data = await service.createCostCenter(body);
    return reply.status(201).send(data);
  });

  fastify.put('/cost-centers/:id', { preHandler: [authorize('ADMINISTRADOR', 'FINANCEIRO')] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const body = validate(costCenterSchema.partial(), request.body);
    const data = await service.updateCostCenter(request.params.id, body);
    return reply.send(data);
  });

  // Dashboard
  fastify.get('/dashboard', { preHandler: [authorize('ADMINISTRADOR', 'PASTOR', 'FINANCEIRO')] }, async (_request: FastifyRequest, reply: FastifyReply) => {
    const data = await service.getDashboard();
    return reply.send(data);
  });

  fastify.get('/dashboard/balance', { preHandler: [authorize('ADMINISTRADOR', 'PASTOR', 'FINANCEIRO')] }, async (_request: FastifyRequest, reply: FastifyReply) => {
    const data = await service.getBalance();
    return reply.send(data);
  });

  fastify.get('/dashboard/cash-flow', { preHandler: [authorize('ADMINISTRADOR', 'PASTOR', 'FINANCEIRO')] }, async (_request: FastifyRequest, reply: FastifyReply) => {
    const data = await service.getCashFlow();
    return reply.send(data);
  });

  // Reports
  fastify.get('/reports/monthly', { preHandler: [authorize('ADMINISTRADOR', 'PASTOR', 'FINANCEIRO')] }, async (request: FastifyRequest, reply: FastifyReply) => {
    const { year, month } = request.query as any;
    const data = await service.getMonthlyReport(parseInt(year) || new Date().getFullYear(), parseInt(month) || new Date().getMonth() + 1);
    return reply.send(data);
  });

  // Monthly Close
  fastify.post('/monthly-close', { preHandler: [authorize('ADMINISTRADOR', 'FINANCEIRO')] }, async (request: FastifyRequest, reply: FastifyReply) => {
    const body = validate(monthlyCloseSchema, request.body);
    const userId = (request as any).user.userId;
    const userRole = (request as any).user.role;
    const data = await service.createMonthlyClose(body.referenceDate, userId, userRole, body.notes);
    return reply.status(201).send(data);
  });

  fastify.get('/monthly-close', { preHandler: [authorize('ADMINISTRADOR', 'PASTOR', 'FINANCEIRO')] }, async (_request: FastifyRequest, reply: FastifyReply) => {
    const data = await service.getMonthlyCloses();
    return reply.send(data);
  });

  // Audit
  fastify.get('/audit', { preHandler: [authorize('ADMINISTRADOR', 'FINANCEIRO')] }, async (request: FastifyRequest, reply: FastifyReply) => {
    const { page, limit } = parsePagination(request.query);
    const data = await service.getAuditLogs({ page, limit });
    return reply.send(data);
  });
}
