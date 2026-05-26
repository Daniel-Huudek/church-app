import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { validate, parsePagination } from '@church-app/shared';
import jwt from 'jsonwebtoken';
import { z } from 'zod';
import { FinanceService } from '../services/finance.service';

function setUserFromToken(request: FastifyRequest) {
  const authHeader = request.headers.authorization;
  if (!authHeader) return;
  try {
    const token = authHeader.replace('Bearer ', '');
    const decoded = jwt.verify(token, process.env.JWT_SECRET || '') as { userId: string; role: string };
    (request as any).user = decoded;
  } catch {}
}

function getUser(request: FastifyRequest) {
  const user = (request as any).user;
  return { userId: user?.userId ?? '', role: user?.role ?? 'MEMBRO' };
}

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

  // Transactions
  fastify.get('/transactions', async (request: FastifyRequest, reply: FastifyReply) => {
    const { page, limit } = parsePagination(request.query);
    const { type, status, categoryId, costCenterId, startDate, endDate, search } = request.query as Record<string, string | undefined>;
    const data = await service.findAllTransactions({
      page, limit, type, status, categoryId, costCenterId, startDate, endDate, search,
    });
    return reply.send(data);
  });

  fastify.get('/transactions/:id', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const data = await service.findTransactionById(request.params.id);
    return reply.send(data);
  });

  fastify.post('/transactions', async (request: FastifyRequest, reply: FastifyReply) => {
    const body = validate(transactionSchema, request.body);
    setUserFromToken(request);
    const { userId, role } = getUser(request);
    const data = await service.createTransaction(body, userId, role);
    return reply.status(201).send(data);
  });

  fastify.put('/transactions/:id', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const body = validate(transactionSchema.partial(), request.body);
    setUserFromToken(request);
    const { userId, role } = getUser(request);
    const data = await service.updateTransaction(request.params.id, body, userId, role);
    return reply.send(data);
  });

  fastify.delete('/transactions/:id', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    setUserFromToken(request);
    const { userId, role } = getUser(request);
    await service.deleteTransaction(request.params.id, userId, role);
    return reply.send({ success: true });
  });

  fastify.post('/transactions/:id/confirm', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    setUserFromToken(request);
    const { userId, role } = getUser(request);
    const data = await service.confirmTransaction(request.params.id, userId, role);
    return reply.send(data);
  });

  fastify.post('/transactions/:id/cancel', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    setUserFromToken(request);
    const { userId, role } = getUser(request);
    const data = await service.cancelTransaction(request.params.id, userId, role);
    return reply.send(data);
  });

  fastify.post('/transactions/:id/attachments', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const file = await request.file();
    if (!file) {
      return reply.status(400).send({ success: false, message: 'No file uploaded' });
    }
    const buffer = await file.toBuffer();
    const { userId } = getAuth(request);
    const data = await service.addAttachment(request.params.id, { filename: file.filename, buffer, mimetype: file.mimetype }, userId);
    return reply.status(201).send(data);
  });

  fastify.get('/transactions/:id/audit', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const { page, limit } = parsePagination(request.query);
    const data = await service.getAuditLogs({ page, limit, transactionId: request.params.id });
    return reply.send(data);
  });

  // Categories
  fastify.get('/categories', async (_request: FastifyRequest, reply: FastifyReply) => {
    const data = await service.findAllCategories();
    return reply.send(data);
  });

  fastify.post('/categories', async (request: FastifyRequest, reply: FastifyReply) => {
    const body = validate(categorySchema, request.body);
    const data = await service.createCategory(body);
    return reply.status(201).send(data);
  });

  fastify.put('/categories/:id', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const body = validate(categorySchema.partial(), request.body);
    const data = await service.updateCategory(request.params.id, body);
    return reply.send(data);
  });

  // Cost Centers
  fastify.get('/cost-centers', async (_request: FastifyRequest, reply: FastifyReply) => {
    const data = await service.findAllCostCenters();
    return reply.send(data);
  });

  fastify.post('/cost-centers', async (request: FastifyRequest, reply: FastifyReply) => {
    const body = validate(costCenterSchema, request.body);
    const data = await service.createCostCenter(body);
    return reply.status(201).send(data);
  });

  fastify.put('/cost-centers/:id', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const body = validate(costCenterSchema.partial(), request.body);
    const data = await service.updateCostCenter(request.params.id, body);
    return reply.send(data);
  });

  // Dashboard
  fastify.get('/dashboard', async (_request: FastifyRequest, reply: FastifyReply) => {
    const data = await service.getDashboard();
    return reply.send(data);
  });

  fastify.get('/dashboard/balance', async (_request: FastifyRequest, reply: FastifyReply) => {
    const data = await service.getBalance();
    return reply.send(data);
  });

  fastify.get('/dashboard/cash-flow', async (_request: FastifyRequest, reply: FastifyReply) => {
    const data = await service.getCashFlow();
    return reply.send(data);
  });

  // Reports
  fastify.get('/reports/monthly', async (request: FastifyRequest, reply: FastifyReply) => {
    const { year, month } = request.query as Record<string, string | undefined>;
    const data = await service.getMonthlyReport(parseInt(year) || new Date().getFullYear(), parseInt(month) || new Date().getMonth() + 1);
    return reply.send(data);
  });

  // Monthly Close
  fastify.post('/monthly-close', async (request: FastifyRequest, reply: FastifyReply) => {
    const body = validate(monthlyCloseSchema, request.body);
    setUserFromToken(request);
    const { userId, role } = getUser(request);
    const data = await service.createMonthlyClose(body.referenceDate, userId, role, body.notes);
    return reply.status(201).send(data);
  });

  fastify.get('/monthly-close', async (_request: FastifyRequest, reply: FastifyReply) => {
    const data = await service.getMonthlyCloses();
    return reply.send(data);
  });

  // Audit
  fastify.get('/audit', async (request: FastifyRequest, reply: FastifyReply) => {
    const { page, limit } = parsePagination(request.query);
    const data = await service.getAuditLogs({ page, limit });
    return reply.send(data);
  });
}
