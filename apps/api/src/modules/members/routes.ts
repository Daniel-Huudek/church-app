import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import {
  validate,
  parsePagination,
  authenticate,
  requireAuthUser,
  authorizePermissions,
} from '@church-app/shared';
import { z } from 'zod';
import { createReadStream } from 'fs';
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
  ministryIds: z.array(z.string().uuid()).optional(),
  occupation: z.string().optional(),
  notes: z.string().optional(),
  userId: z.string().uuid().nullable().optional(),
  forceDuplicate: z.boolean().optional(),
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

const canRead = authorizePermissions('members_read');
const canWrite = authorizePermissions('members_write');
const canDelete = authorizePermissions('members_delete');
const canExport = authorizePermissions('members_export', 'members_read');
const canImport = authorizePermissions('members_import', 'members_write');

export async function memberRoutes(fastify: FastifyInstance) {
  const service = new MemberService(fastify.prisma);

  fastify.addHook('preHandler', authenticate());

  // Self profile — any authenticated user
  fastify.get('/me', async (request: FastifyRequest, reply: FastifyReply) => {
    const { userId } = requireAuthUser(request);
    const data = await service.findByUserId(userId);
    return reply.send(data);
  });

  fastify.get('/', { preHandler: [canRead] }, async (request: FastifyRequest, reply: FastifyReply) => {
    const { page, limit } = parsePagination(request.query);
    const { name, email, status, role, ministryId, birthdayMonth } = request.query as Record<string, string | undefined>;
    const data = await service.findAll({
      page, limit, name, email, status, role, ministryId,
      birthdayMonth: birthdayMonth ? parseInt(birthdayMonth, 10) : undefined,
    });
    return reply.send(data);
  });

  fastify.get('/search', { preHandler: [canRead] }, async (request: FastifyRequest, reply: FastifyReply) => {
    const { q, page, limit } = request.query as Record<string, string | undefined>;
    const pagination = parsePagination({ page, limit });
    const data = await service.search(q || '', pagination);
    return reply.send(data);
  });

  fastify.get('/export', { preHandler: [canExport] }, async (_request, reply: FastifyReply) => {
    const data = await service.exportCsv();
    return reply.send({ success: true, data });
  });

  // Visible to any authenticated user (hook above). Returns a public summary only.
  // Member detail remains gated by members_read.
  fastify.get('/birthdays', async (request: FastifyRequest, reply: FastifyReply) => {
    const { period } = request.query as { period?: string };
    const allowed = ['today', 'week', 'month'] as const;
    const selected = allowed.includes(period as typeof allowed[number])
      ? (period as typeof allowed[number])
      : 'week';
    const data = await service.findBirthdays(selected);
    return reply.send(data);
  });

  fastify.post('/import', { preHandler: [canImport] }, async (request: FastifyRequest, reply: FastifyReply) => {
    const body = request.body as { records?: unknown[] };
    const { userId } = requireAuthUser(request);
    const data = await service.importCsv(body?.records || [], userId);
    return reply.status(201).send(data);
  });

  // Avatar stream (auth already applied by hook) — must be before /:id catch-all patterns that conflict? 
  // Actually /:id/avatar is fine after /:id if registered carefully; register before generic /:id handlers that might consume
  fastify.get('/:id/avatar', { preHandler: [canRead] }, async (request, reply: FastifyReply) => {
    const { filePath, contentType } = await service.getAvatarFile((request.params as any).id);
    reply.header('Content-Type', contentType);
    reply.header('Cache-Control', 'private, max-age=3600');
    return reply.send(createReadStream(filePath));
  });

  fastify.get('/:id', { preHandler: [canRead] }, async (request, reply: FastifyReply) => {
    const data = await service.findById((request.params as any).id);
    return reply.send(data);
  });

  fastify.post('/', { preHandler: [canWrite] }, async (request: FastifyRequest, reply: FastifyReply) => {
    const body = validate(memberSchema, request.body);
    const { userId } = requireAuthUser(request);
    const data = await service.create(body, userId);
    return reply.status(201).send(data);
  });

  fastify.put('/:id', { preHandler: [canWrite] }, async (request, reply: FastifyReply) => {
    const body = validate(memberSchema.partial(), request.body);
    const { userId } = requireAuthUser(request);
    const data = await service.update((request.params as any).id, body, userId);
    return reply.send(data);
  });

  fastify.delete('/:id', { preHandler: [canDelete] }, async (request, reply: FastifyReply) => {
    const { userId } = requireAuthUser(request);
    await service.delete((request.params as any).id, userId);
    return reply.send({ success: true });
  });

  fastify.get('/user/:userId', { preHandler: [canRead] }, async (request, reply: FastifyReply) => {
    const data = await service.findByUserId((request.params as any).userId);
    return reply.send(data);
  });

  fastify.get('/:id/address', { preHandler: [canRead] }, async (request, reply: FastifyReply) => {
    const data = await service.getAddress((request.params as any).id);
    return reply.send(data);
  });

  fastify.put('/:id/address', { preHandler: [canWrite] }, async (request, reply: FastifyReply) => {
    const body = validate(addressSchema, request.body);
    const data = await service.upsertAddress((request.params as any).id, body);
    return reply.send(data);
  });

  fastify.get('/:id/documents', { preHandler: [canRead] }, async (request, reply: FastifyReply) => {
    const data = await service.getDocuments((request.params as any).id);
    return reply.send(data);
  });

  fastify.post('/:id/documents', { preHandler: [canWrite] }, async (request, reply: FastifyReply) => {
    const body = validate(documentSchema, request.body);
    const data = await service.addDocument((request.params as any).id, body);
    return reply.status(201).send(data);
  });

  fastify.delete('/:id/documents/:docId', { preHandler: [canWrite] }, async (request, reply: FastifyReply) => {
    await service.deleteDocument((request.params as any).id, (request.params as any).docId);
    return reply.send({ success: true });
  });

  fastify.get('/:id/family', { preHandler: [canRead] }, async (request, reply: FastifyReply) => {
    const data = await service.getFamilyMembers((request.params as any).id);
    return reply.send(data);
  });

  fastify.post('/:id/family', { preHandler: [canWrite] }, async (request, reply: FastifyReply) => {
    const body = validate(familySchema, request.body);
    const data = await service.addFamilyMember((request.params as any).id, body);
    return reply.status(201).send(data);
  });

  fastify.delete('/:id/family/:familyId', { preHandler: [canWrite] }, async (request, reply: FastifyReply) => {
    await service.deleteFamilyMember((request.params as any).id, (request.params as any).familyId);
    return reply.send({ success: true });
  });

  fastify.get('/:id/history', { preHandler: [canRead] }, async (request, reply: FastifyReply) => {
    const data = await service.getMinisterialHistory((request.params as any).id);
    return reply.send(data);
  });

  fastify.post('/:id/history', { preHandler: [canWrite] }, async (request, reply: FastifyReply) => {
    const body = validate(historySchema, request.body);
    const data = await service.addMinisterialHistory((request.params as any).id, body);
    return reply.status(201).send(data);
  });

  fastify.post('/:id/photo', { preHandler: [canWrite] }, async (request, reply: FastifyReply) => {
    const data = await request.file();
    if (!data) {
      return reply.status(400).send({ success: false, message: 'No file uploaded' });
    }
    const buffer = await data.toBuffer();
    const result = await service.uploadPhoto((request.params as any).id, data.filename, buffer, data.mimetype);
    return reply.send(result);
  });

  fastify.get('/:id/audit', { preHandler: [canRead] }, async (request, reply: FastifyReply) => {
    const data = await service.getAuditLogs((request.params as any).id);
    return reply.send(data);
  });
}

const canMinistryRead = authorizePermissions('ministries_read', 'members_read');
const canMinistryWrite = authorizePermissions('ministries_write', 'members_write');
const canMinistryDelete = authorizePermissions('ministries_delete', 'members_delete');

export async function ministryRoutes(fastify: FastifyInstance) {
  const service = new MemberService(fastify.prisma);

  fastify.addHook('preHandler', authenticate());

  fastify.get('/', { preHandler: [canMinistryRead] }, async (_request: FastifyRequest, reply: FastifyReply) => {
    const data = await service.findAllMinistries();
    return reply.send(data);
  });

  fastify.post('/', { preHandler: [canMinistryWrite] }, async (request: FastifyRequest, reply: FastifyReply) => {
    const body = validate(ministrySchema, request.body);
    const data = await service.createMinistry(body);
    return reply.status(201).send(data);
  });

  fastify.put('/:id', { preHandler: [canMinistryWrite] }, async (request, reply: FastifyReply) => {
    const body = validate(ministrySchema.partial(), request.body);
    const data = await service.updateMinistry((request.params as any).id, body);
    return reply.send(data);
  });

  fastify.delete('/:id', { preHandler: [canMinistryDelete] }, async (request, reply: FastifyReply) => {
    await service.deleteMinistry((request.params as any).id);
    return reply.send({ success: true });
  });
}
