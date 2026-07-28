import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { validate, parsePagination, authenticate, requireAuthUser } from '@church-app/shared';
import { z } from 'zod';
import { MemberService } from './service';

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
  admissionDate: z.string().optional(),
  admissionType: z.enum(['BATISMO', 'TRANSFERENCIA', 'RECONCILIACAO', 'OUTRO']).optional(),
  isBaptized: z.boolean().default(false),
  status: z.enum(['ATIVO', 'INATIVO', 'AFASTADO', 'TRANSFERIDO', 'EXCLUIDO']).default('ATIVO'),
  role: z.enum(['MEMBRO', 'DIACONO', 'PRESBITERO', 'PASTOR']).default('MEMBRO'),
  ministryId: z.string().uuid().optional(),
  occupation: z.string().optional(),
  notes: z.string().optional(),
  userId: z.string().uuid().optional(),
  address: z.object({
    street: z.string().min(1),
    number: z.string().optional(),
    complement: z.string().optional(),
    neighborhood: z.string().min(1),
    city: z.string().min(1),
    state: z.string().min(1),
    zipCode: z.string().min(1),
  }).optional(),
});

const addressSchema = z.object({
  street: z.string().min(1),
  number: z.string().optional(),
  complement: z.string().optional(),
  neighborhood: z.string().min(1),
  city: z.string().min(1),
  state: z.string().min(1),
  zipCode: z.string().min(1),
});

const documentSchema = z.object({
  type: z.string().min(1),
  value: z.string().min(1),
});

const familySchema = z.object({
  name: z.string().min(1),
  kinship: z.string().min(1),
  phone: z.string().optional(),
});

const historySchema = z.object({
  ministry: z.string().min(1),
  role: z.string().min(1),
  startDate: z.string(),
  endDate: z.string().optional(),
  description: z.string().optional(),
});

const ministrySchema = z.object({
  name: z.string().min(1),
  description: z.string().optional(),
  leaderId: z.string().uuid().optional(),
});

export async function memberRoutes(fastify: FastifyInstance) {
  const service = new MemberService(fastify.prisma);

  fastify.addHook('preHandler', authenticate());

  // Alias used by Flutter / former gateway: GET /members/me
  fastify.get('/me', async (request: FastifyRequest, reply: FastifyReply) => {
    const { userId } = requireAuthUser(request);
    const data = await service.findByUserId(userId);
    return reply.send(data);
  });

  fastify.get('/', async (request: FastifyRequest, reply: FastifyReply) => {
    const { page, limit } = parsePagination(request.query);
    const { name, email, status, role, ministryId, birthdayMonth } = request.query as Record<string, string | undefined>;
    const data = await service.findAll({
      page, limit, name, email, status, role, ministryId,
      birthdayMonth: birthdayMonth ? parseInt(birthdayMonth) : undefined,
    });
    return reply.send(data);
  });

  fastify.get('/search', async (request: FastifyRequest, reply: FastifyReply) => {
    const { q, page, limit } = request.query as Record<string, string | undefined>;
    const pagination = parsePagination({ page, limit });
    const data = await service.search(q || '', pagination);
    return reply.send(data);
  });

  fastify.get('/export', async (request: FastifyRequest, reply: FastifyReply) => {
    const data = await service.exportCsv();
    return reply.send({ success: true, data });
  });

  fastify.get('/birthdays', async (request: FastifyRequest, reply: FastifyReply) => {
    const { period } = request.query as { period?: string };
    const allowed = ['today', 'week', 'month'] as const;
    const selected = allowed.includes(period as typeof allowed[number])
      ? (period as typeof allowed[number])
      : 'week';
    const data = await service.findBirthdays(selected);
    return reply.send(data);
  });

  fastify.post('/import', async (request: FastifyRequest, reply: FastifyReply) => {
    const body = request.body as { records?: unknown[] };
    const data = await service.importCsv(body?.records || []);
    return reply.status(201).send(data);
  });

  fastify.get('/:id', async (request, reply: FastifyReply) => {
    const data = await service.findById((request.params as any).id);
    return reply.send(data);
  });

  fastify.post('/', async (request: FastifyRequest, reply: FastifyReply) => {
    const body = validate(memberSchema, request.body);
    const data = await service.create(body);
    return reply.status(201).send(data);
  });

  fastify.put('/:id', async (request, reply: FastifyReply) => {
    const body = validate(memberSchema.partial(), request.body);
    const data = await service.update((request.params as any).id, body);
    return reply.send(data);
  });

  fastify.delete('/:id', async (request, reply: FastifyReply) => {
    await service.delete((request.params as any).id);
    return reply.send({ success: true });
  });

  fastify.get('/user/:userId', async (request, reply: FastifyReply) => {
    const data = await service.findByUserId((request.params as any).userId);
    return reply.send(data);
  });

  // Address
  fastify.get('/:id/address', async (request, reply: FastifyReply) => {
    const data = await service.getAddress((request.params as any).id);
    return reply.send(data);
  });

  fastify.put('/:id/address', async (request, reply: FastifyReply) => {
    const body = validate(addressSchema, request.body);
    const data = await service.upsertAddress((request.params as any).id, body);
    return reply.send(data);
  });

  // Documents
  fastify.get('/:id/documents', async (request, reply: FastifyReply) => {
    const data = await service.getDocuments((request.params as any).id);
    return reply.send(data);
  });

  fastify.post('/:id/documents', async (request, reply: FastifyReply) => {
    const body = validate(documentSchema, request.body);
    const data = await service.addDocument((request.params as any).id, body);
    return reply.status(201).send(data);
  });

  fastify.delete('/:id/documents/:docId', async (request, reply: FastifyReply) => {
    await service.deleteDocument((request.params as any).docId);
    return reply.send({ success: true });
  });

  // Family
  fastify.get('/:id/family', async (request, reply: FastifyReply) => {
    const data = await service.getFamilyMembers((request.params as any).id);
    return reply.send(data);
  });

  fastify.post('/:id/family', async (request, reply: FastifyReply) => {
    const body = validate(familySchema, request.body);
    const data = await service.addFamilyMember((request.params as any).id, body);
    return reply.status(201).send(data);
  });

  fastify.delete('/:id/family/:familyId', async (request, reply: FastifyReply) => {
    await service.deleteFamilyMember((request.params as any).familyId);
    return reply.send({ success: true });
  });

  // Ministerial History
  fastify.get('/:id/history', async (request, reply: FastifyReply) => {
    const data = await service.getMinisterialHistory((request.params as any).id);
    return reply.send(data);
  });

  fastify.post('/:id/history', async (request, reply: FastifyReply) => {
    const body = validate(historySchema, request.body);
    const data = await service.addMinisterialHistory((request.params as any).id, body);
    return reply.status(201).send(data);
  });

  // Photo
  fastify.post('/:id/photo', async (request, reply: FastifyReply) => {
    const data = await request.file();
    if (!data) {
      return reply.status(400).send({ success: false, message: 'No file uploaded' });
    }
    const buffer = await data.toBuffer();
    const result = await service.uploadPhoto((request.params as any).id, data.filename, buffer);
    return reply.send(result);
  });

  // Audit
  fastify.get('/:id/audit', async (request, reply: FastifyReply) => {
    const data = await service.getAuditLogs((request.params as any).id);
    return reply.send(data);
  });
}

export async function ministryRoutes(fastify: FastifyInstance) {
  const service = new MemberService(fastify.prisma);

  fastify.addHook('preHandler', authenticate());

  fastify.get('/', async (_request: FastifyRequest, reply: FastifyReply) => {
    const data = await service.findAllMinistries();
    return reply.send(data);
  });

  fastify.post('/', async (request: FastifyRequest, reply: FastifyReply) => {
    const body = validate(ministrySchema, request.body);
    const data = await service.createMinistry(body);
    return reply.status(201).send(data);
  });

  fastify.put('/:id', async (request, reply: FastifyReply) => {
    const body = validate(ministrySchema.partial(), request.body);
    const data = await service.updateMinistry((request.params as any).id, body);
    return reply.send(data);
  });

  fastify.delete('/:id', async (request, reply: FastifyReply) => {
    await service.deleteMinistry((request.params as any).id);
    return reply.send({ success: true });
  });
}
