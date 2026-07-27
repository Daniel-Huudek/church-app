import { FastifyInstance } from 'fastify';
import { authClient } from '../http-client';
import { validate, getAuthHeader } from '@church-app/shared';
import { z } from 'zod';

const loginSchema = z.object({ email: z.string().email(), password: z.string().min(6) });
const registerSchema = z.object({ name: z.string().min(1), email: z.string().email(), password: z.string().min(6) });
const refreshSchema = z.object({ refreshToken: z.string().min(1) });
const googleTokenSchema = z.object({ token: z.string().min(1) });

export async function authRoutes(fastify: FastifyInstance) {
  fastify.get('/google', async (_request, reply) => {
    const googleAuthUrl = `https://accounts.google.com/o/oauth2/v2/auth?client_id=${process.env.GOOGLE_CLIENT_ID}&redirect_uri=${encodeURIComponent(process.env.GOOGLE_REDIRECT_URI || '')}&response_type=code&scope=openid%20profile%20email&access_type=offline&state=${crypto.randomUUID()}`;
    return reply.redirect(googleAuthUrl);
  });

  fastify.get('/google/callback', async (request, reply) => {
    const { code } = request.query as { code?: string };
    if (!code) {
      return reply.status(400).send({ success: false, message: 'Code not provided' });
    }
    try {
      // Auth service expects code in query string
      const data = await authClient.post(`/auth/google/callback?code=${encodeURIComponent(code)}`, {});
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({
        success: false,
        message: error.message || 'Authentication failed',
      });
    }
  });

  fastify.post('/google', async (request, reply) => {
    const body = validate(googleTokenSchema, request.body);
    try {
      const data = await authClient.post('/auth/google', { token: body.token });
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({
        success: false,
        message: error.message || 'Google authentication failed',
      });
    }
  });

  fastify.post('/login', async (request, reply) => {
    const body = validate(loginSchema, request.body);
    try {
      const data = await authClient.post('/auth/login', { email: body.email, password: body.password });
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({
        success: false,
        message: error.message || 'Login failed',
      });
    }
  });

  fastify.post('/register', async (request, reply) => {
    const body = validate(registerSchema, request.body);
    try {
      const data = await authClient.post('/auth/register', { name: body.name, email: body.email, password: body.password });
      await reply.status(201).send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({
        success: false,
        message: error.message || 'Registration failed',
      });
    }
  });

  fastify.post('/refresh', async (request, reply) => {
    const body = validate(refreshSchema, request.body);
    try {
      const data = await authClient.post('/auth/refresh', { refreshToken: body.refreshToken });
      await reply.send(data);
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({
        success: false,
        message: error.message || 'Token refresh failed',
      });
    }
  });

  fastify.post('/logout', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      await authClient.post('/auth/logout', {}, getAuthHeader(request));
      await reply.send({ success: true, message: 'Logged out successfully' });
    } catch (error: any) {
      await reply.status(error.statusCode || 500).send({
        success: false,
        message: error.message || 'Logout failed',
      });
    }
  });
}
