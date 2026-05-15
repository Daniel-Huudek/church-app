import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { validate, parsePagination } from '../shared';
import { z } from 'zod';
import { MemberService } from '../services/member.service';

const memberSchema = z.object({ name: z.string().min(1), email: z.string().email(), phone: z.string().min(10), ministryId: z.string().uuid().optional(), role: z.enum(['ADMIN', 'LEADER', 'MEMBER']).default('MEMBER') });
const ministrySchema = z.object({ name: z.string().min(1), description: z.string().optional(), leaderId: z.string().uuid() });

export async function memberRoutes(fastify: FastifyInstance) {
  const service = new MemberService(fastify.prisma);

  fastify.get('/', async (_request: FastifyRequest, reply: FastifyReply) => {
    const { page, limit } = parsePagination(_request.query);
    const data = await service.findAll({ page, limit });
    return reply.send(data);
  });

  fastify.get('/:id', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const data = await service.findById(request.params.id);
    return reply.send(data);
  });

  fastify.post('/', async (request: FastifyRequest, reply: FastifyReply) => {
    const body = validate(memberSchema, request.body);
    const data = await service.create(body);
    return reply.status(201).send(data);
  });

  fastify.put('/:id', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    const body = validate(memberSchema.partial(), request.body);
    const data = await service.update(request.params.id, body);
    return reply.send(data);
  });

  fastify.delete('/:id', async (request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
    await service.delete(request.params.id);
    return reply.send({ success: true });
  });

  fastify.get('/user/:userId', async (request: FastifyRequest<{ Params: { userId: string } }>, reply: FastifyReply) => {
    const data = await service.findByUserId(request.params.userId);
    return reply.send(data);
  });
}

export async function ministryRoutes(fastify: FastifyInstance) {
  const service = new MemberService(fastify.prisma);

  fastify.get('/', async (_request: FastifyRequest, reply: FastifyReply) => {
    const data = await service.findAllMinistries();
    return reply.send(data);
  });

  fastify.post('/', async (request: FastifyRequest, reply: FastifyReply) => {
    const body = validate(ministrySchema, request.body);
    const data = await service.createMinistry(body);
    return reply.status(201).send(data);
  });
}