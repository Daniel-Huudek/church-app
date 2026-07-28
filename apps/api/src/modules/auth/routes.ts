import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { validate, authenticate, authorize, requireAuthUser, assertUserAdminRole } from '@church-app/shared';
import { z } from 'zod';
import { AuthService } from './service';
import { UnauthorizedError, ForbiddenError } from '@church-app/shared';

const loginSchema = z.object({ email: z.string().email(), password: z.string().min(6) });
const registerSchema = z.object({ name: z.string().min(1), email: z.string().email(), password: z.string().min(6) });
const googleCallbackSchema = z.object({ code: z.string() });
const googleTokenSchema = z.object({ token: z.string() });
const refreshSchema = z.object({ refreshToken: z.string() });
const permissionsSchema = z.object({ permissions: z.array(z.string()) });
const profileUpdateSchema = z.object({
  role: z.string().optional(),
  name: z.string().min(1).optional(),
  email: z.string().email().optional(),
  avatar: z.string().optional(),
});
const roleUpdateSchema = z.object({ permissions: z.array(z.string()) });

const adminOnly = authorize('ADMINISTRADOR', 'PASTOR');
const requireAuth = authenticate();

export async function authRoutes(fastify: FastifyInstance) {
  const authService = new AuthService(fastify.prisma);

  // Browser OAuth redirect (Flutter / web)
  fastify.get('/google', async (_request, reply) => {
    const googleAuthUrl = `https://accounts.google.com/o/oauth2/v2/auth?client_id=${process.env.GOOGLE_CLIENT_ID}&redirect_uri=${encodeURIComponent(process.env.GOOGLE_REDIRECT_URI || '')}&response_type=code&scope=openid%20profile%20email&access_type=offline&state=${crypto.randomUUID()}`;
    return reply.redirect(googleAuthUrl);
  });

  fastify.get('/google/callback', async (request, reply) => {
    const { code } = request.query as { code?: string };
    if (!code) {
      return reply.status(400).send({ success: false, message: 'Code not provided' });
    }
    const result = await authService.handleGoogleCallback(code);
    return reply.send(result);
  });

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
    const raw = { ...(request.query as object), ...(request.body as object) };
    const { code } = validate(googleCallbackSchema, raw);
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
    const token = authHeader.replace(/^Bearer\s+/i, '');
    await authService.logout(token);
    return reply.send({ success: true, message: 'Logged out successfully' });
  });

  // Static admin routes BEFORE /:id
  fastify.get('/roles', { preHandler: [adminOnly] }, async (_request, reply) => {
    const result = await authService.getAllRoles();
    return reply.send({ success: true, data: result });
  });

  fastify.put('/roles/:name', { preHandler: [adminOnly] }, async (request, reply) => {
    const { permissions } = validate(roleUpdateSchema, request.body);
    const result = await authService.updateRole((request.params as any).name, permissions);
    return reply.send({ success: true, data: result });
  });

  fastify.post('/roles/reset', { preHandler: [adminOnly] }, async (_request, reply) => {
    const result = await authService.resetRoles();
    return reply.send({ success: true, data: result });
  });

  fastify.get('/', { preHandler: [adminOnly] }, async (_request: FastifyRequest, _reply: FastifyReply) => {
    const result = await authService.getAllUsers();
    return _reply.send({ success: true, data: result });
  });

  fastify.put('/:userId/permissions', { preHandler: [adminOnly] }, async (request, reply: FastifyReply) => {
    const body = validate(permissionsSchema, request.body);
    const result = await authService.setUserPermissions((request.params as any).userId, body.permissions);
    return reply.send({ success: true, data: result });
  });

  fastify.get('/:userId/permissions', { preHandler: [adminOnly] }, async (request, reply: FastifyReply) => {
    const result = await authService.getUserPermissions((request.params as any).userId);
    return reply.send({ success: true, data: result });
  });

  // Any authenticated user can fetch basic profile (prayer enrichment, etc.)
  fastify.get('/:id', { preHandler: [requireAuth] }, async (request, _reply: FastifyReply) => {
    const result = await authService.getUserById((request.params as any).id);
    return _reply.send({ success: true, data: result });
  });

  fastify.put('/:id', { preHandler: [requireAuth] }, async (request, _reply: FastifyReply) => {
    const actor = requireAuthUser(request);
    const body = validate(profileUpdateSchema, request.body);
    const isSelf = actor.userId === (request.params as any).id;
    const wantsRoleChange = body.role !== undefined;
    const isAdmin = ['ADMINISTRADOR', 'PASTOR'].includes(actor.role);

    if (!isSelf || wantsRoleChange) {
      assertUserAdminRole(actor.role);
    }

    if (isSelf && wantsRoleChange && !isAdmin) {
      throw new ForbiddenError('Cannot change own role');
    }

    const safeBody = isAdmin
      ? body
      : { name: body.name, email: body.email, avatar: body.avatar };

    const result = await authService.updateUser((request.params as any).id, safeBody);
    return _reply.send({ success: true, data: result });
  });
}
