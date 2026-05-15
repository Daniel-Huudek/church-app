import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { validate } from '../shared';
import { z } from 'zod';
import { AuthService } from '../services/auth.service';
import { UnauthorizedError, BadRequestError } from '../shared';

const loginSchema = z.object({ email: z.string().email(), password: z.string().min(6) });
const registerSchema = z.object({ name: z.string().min(1), email: z.string().email(), password: z.string().min(6) });
const googleCallbackSchema = z.object({ code: z.string() });
const refreshSchema = z.object({ refreshToken: z.string() });

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
}