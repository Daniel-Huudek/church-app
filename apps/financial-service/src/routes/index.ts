import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { validate, parsePagination, authenticate, authorize, requireAuthUser, assertFinanceWriteRole } from '@church-app/shared';
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
  status: z.enum(['PENDING', 'CONFIRMED', 'CANCELLED']).default('CONFIRMED'),
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

const financeRoles = ['ADMINISTRADOR', 'PASTOR', 'FINANCEIRO'] as const;

export async function financeRoutes(fastify: FastifyInstance) {
  const service = new FinanceService(fastify.prisma);

  // All finance routes require a valid JWT; writes require finance roles
  fastify.addHook('preHandler', authenticate());

  // Transactions
  fastify.get('/transactions', async (request: FastifyRequest, reply: FastifyReply) => {
    assertFinanceWriteRole(requireAuthUser(request).role);
    const { page, limit } = parsePagination(request.query);
    const { type, status, categoryId, costCenterId, startDate, endDate, search } = request.query as Record<string, string | undefined>;
    const data = await service.findAllTransactions({
      page, limit, type, status, categoryId, costCenterId, startDate, endDate, search,
    });
    return reply.send(data);
  });

  fastify.get('/transactions/:id', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    assertFinanceWriteRole(requireAuthUser(request).role);
    const data = await service.findTransactionById(request.params.id);
    return reply.send(data);
  });

  fastify.post('/transactions', { preHandler: [authorize(...financeRoles)] }, async (request: FastifyRequest, reply: FastifyReply) => {
    const body = validate(transactionSchema, request.body);
    const { userId, role } = requireAuthUser(request);
    const data = await service.createTransaction(body, userId, role);
    return reply.status(201).send(data);
  });

  fastify.put('/transactions/:id', { preHandler: [authorize(...financeRoles)] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const body = validate(transactionSchema.partial(), request.body);
    const { userId, role } = requireAuthUser(request);
    const data = await service.updateTransaction(request.params.id, body, userId, role);
    return reply.send(data);
  });

  fastify.delete('/transactions/:id', { preHandler: [authorize(...financeRoles)] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const { userId, role } = requireAuthUser(request);
    await service.deleteTransaction(request.params.id, userId, role);
    return reply.send({ success: true });
  });

  fastify.post('/transactions/:id/confirm', { preHandler: [authorize(...financeRoles)] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const { userId, role } = requireAuthUser(request);
    const data = await service.confirmTransaction(request.params.id, userId, role);
    return reply.send(data);
  });

  fastify.post('/transactions/:id/cancel', { preHandler: [authorize(...financeRoles)] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const { userId, role } = requireAuthUser(request);
    const data = await service.cancelTransaction(request.params.id, userId, role);
    return reply.send(data);
  });

  fastify.post('/transactions/:id/attachments', { preHandler: [authorize(...financeRoles)] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const file = await request.file();
    if (!file) {
      return reply.status(400).send({ success: false, message: 'No file uploaded' });
    }
    const buffer = await file.toBuffer();
    const { userId } = requireAuthUser(request);
    const data = await service.addAttachment(request.params.id, { filename: file.filename, buffer, mimetype: file.mimetype }, userId);
    return reply.status(201).send(data);
  });

  fastify.get('/transactions/:id/audit', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    assertFinanceWriteRole(requireAuthUser(request).role);
    const { page, limit } = parsePagination(request.query);
    const data = await service.getAuditLogs({ page, limit, transactionId: request.params.id });
    return reply.send(data);
  });

  // Categories
  fastify.get('/categories', async (request: FastifyRequest, reply: FastifyReply) => {
    assertFinanceWriteRole(requireAuthUser(request).role);
    const data = await service.findAllCategories();
    return reply.send(data);
  });

  fastify.post('/categories', { preHandler: [authorize(...financeRoles)] }, async (request: FastifyRequest, reply: FastifyReply) => {
    const body = validate(categorySchema, request.body);
    const data = await service.createCategory(body);
    return reply.status(201).send(data);
  });

  fastify.put('/categories/:id', { preHandler: [authorize(...financeRoles)] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const body = validate(categorySchema.partial(), request.body);
    const data = await service.updateCategory(request.params.id, body);
    return reply.send(data);
  });

  // Cost Centers
  fastify.get('/cost-centers', async (request: FastifyRequest, reply: FastifyReply) => {
    assertFinanceWriteRole(requireAuthUser(request).role);
    const data = await service.findAllCostCenters();
    return reply.send(data);
  });

  fastify.post('/cost-centers', { preHandler: [authorize(...financeRoles)] }, async (request: FastifyRequest, reply: FastifyReply) => {
    const body = validate(costCenterSchema, request.body);
    const data = await service.createCostCenter(body);
    return reply.status(201).send(data);
  });

  fastify.put('/cost-centers/:id', { preHandler: [authorize(...financeRoles)] }, async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const body = validate(costCenterSchema.partial(), request.body);
    const data = await service.updateCostCenter(request.params.id, body);
    return reply.send(data);
  });

  // Dashboard
  fastify.get('/dashboard', async (request: FastifyRequest, reply: FastifyReply) => {
    assertFinanceWriteRole(requireAuthUser(request).role);
    const data = await service.getDashboard();
    return reply.send(data);
  });

  fastify.get('/dashboard/balance', async (request: FastifyRequest, reply: FastifyReply) => {
    assertFinanceWriteRole(requireAuthUser(request).role);
    const data = await service.getBalance();
    return reply.send(data);
  });

  fastify.get('/dashboard/cash-flow', async (request: FastifyRequest, reply: FastifyReply) => {
    assertFinanceWriteRole(requireAuthUser(request).role);
    const data = await service.getCashFlow();
    return reply.send(data);
  });

  // Reports
  fastify.get('/reports/monthly', async (request: FastifyRequest, reply: FastifyReply) => {
    assertFinanceWriteRole(requireAuthUser(request).role);
    const { year, month } = request.query as Record<string, string | undefined>;
    const data = await service.getMonthlyReport(parseInt(year!) || new Date().getFullYear(), parseInt(month!) || new Date().getMonth() + 1);
    return reply.send(data);
  });

  // Monthly Close
  fastify.post('/monthly-close', { preHandler: [authorize(...financeRoles)] }, async (request: FastifyRequest, reply: FastifyReply) => {
    const body = validate(monthlyCloseSchema, request.body);
    const { userId, role } = requireAuthUser(request);
    const data = await service.createMonthlyClose(body.referenceDate, userId, role, body.notes);
    return reply.status(201).send(data);
  });

  fastify.get('/monthly-close', async (request: FastifyRequest, reply: FastifyReply) => {
    assertFinanceWriteRole(requireAuthUser(request).role);
    const data = await service.getMonthlyCloses();
    return reply.send(data);
  });

  // Audit
  fastify.get('/audit', async (request: FastifyRequest, reply: FastifyReply) => {
    assertFinanceWriteRole(requireAuthUser(request).role);
    const { page, limit } = parsePagination(request.query);
    const data = await service.getAuditLogs({ page, limit });
    return reply.send(data);
  });
}
