import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { validate } from '../shared';
import { z } from 'zod';
import { AuthService } from '../services/auth.service';
import { UnauthorizedError, BadRequestError } from '../shared';

const loginSchema = z.object({ email: z.string().email(), password: z.string().min(6) });
const registerSchema = z.object({ name: z.string().min(1), email: z.string().email(), password: z.string().min(6) });
const googleCallbackSchema = z.object({ code: z.string() });
const googleTokenSchema = z.object({ token: z.string() });
const refreshSchema = z.object({ refreshToken: z.string() });
const permissionsSchema = z.object({ permissions: z.array(z.string()) });

export async function authRoutes(fastify: FastifyInstance) {
  const authService = new AuthService(fastify.prisma);

  fastify.post('/login', async (request: FastifyRequest, reply: FastifyReply) => {
    const body = validate(loginSchema, request.body);
    const result = await authService.login(body.email, body.password);
    return reply.send(result);
  });

  fastify.post('/register', async (request: FastifyRequest, reply: FastifyReply) => {
    const body = validate(registerSchema, request.body);
    const result = await authService.register(body.name, body.email, body.password);
    return reply.status(201).send(result);
  });

  fastify.post('/google/callback', async (request: FastifyRequest, reply: FastifyReply) => {
    const { code } = validate(googleCallbackSchema, request.query);
    const result = await authService.handleGoogleCallback(code);
    return reply.send(result);
  });

  fastify.post('/google', async (request: FastifyRequest, reply: FastifyReply) => {
    const { token } = validate(googleTokenSchema, request.body);
    const result = await authService.handleGoogleToken(token);
    return reply.send(result);
  });

  fastify.post('/refresh', async (request: FastifyRequest, reply: FastifyReply) => {
    const { refreshToken } = validate(refreshSchema, request.body);
    const result = await authService.refreshToken(refreshToken);
    return reply.send(result);
  });

  fastify.post('/logout', async (request: FastifyRequest, reply: FastifyReply) => {
    const authHeader = request.headers.authorization;
    if (!authHeader) throw new UnauthorizedError();
    const token = authHeader.replace('Bearer ', '');
    await authService.logout(token);
    return reply.send({ success: true, message: 'Logged out successfully' });
  });

  fastify.put('/:userId/permissions', async (request: FastifyRequest<{ Params: { userId: string } }>, reply: FastifyReply) => {
    const body = validate(permissionsSchema, request.body);
    const result = await authService.setUserPermissions(request.params.userId, body.permissions);
    return reply.send({ success: true, data: result });
  });

  fastify.get('/', async (_request: FastifyRequest, _reply: FastifyReply) => {
    const result = await authService.getAllUsers();
    return _reply.send({ success: true, data: result });
  });

  fastify.get('/:id', async (request: FastifyRequest<{ Params: { id: string } }>, _reply: FastifyReply) => {
    const result = await authService.getUserById(request.params.id);
    return _reply.send({ success: true, data: result });
  });

  fastify.get('/:userId/permissions', async (request: FastifyRequest<{ Params: { userId: string } }>, reply: FastifyReply) => {
    const result = await authService.getUserPermissions(request.params.userId);
    return reply.send({ success: true, data: result });
  });

  fastify.put('/:id', async (request: FastifyRequest<{ Params: { id: string } }>, _reply: FastifyReply) => {
    const { role } = request.body as { role: string };
    const result = await authService.updateUserRole(request.params.id, role);
    return _reply.send({ success: true, data: result });
  });
}