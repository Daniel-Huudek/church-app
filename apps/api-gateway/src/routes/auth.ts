import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { authClient } from '../http-client';

export async function authRoutes(fastify: FastifyInstance) {
  fastify.get('/google', async (_request: FastifyRequest, reply: FastifyReply) => {
    const googleAuthUrl = `https://accounts.google.com/o/oauth2/v2/auth?client_id=${process.env.GOOGLE_CLIENT_ID}&redirect_uri=${process.env.GOOGLE_REDIRECT_URI}&response_type=code&scope=openid profile email&access_type=offline`;
    return reply.redirect(googleAuthUrl);
  });

  fastify.get('/google/callback', async (request: FastifyRequest, reply: FastifyReply) => {
    const { code } = request.query as { code?: string };
    if (!code) {
      return reply.status(400).send({ success: false, message: 'Code not provided' });
    }
    try {
      const data = await authClient.post('/auth/google/callback', { code });
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({
        success: false,
        message: error.message || 'Authentication failed',
      });
    }
  });

  fastify.post('/google', async (request: FastifyRequest, reply: FastifyReply) => {
    const { idToken } = request.body as { idToken: string };
    if (!idToken) {
      return reply.status(400).send({ success: false, message: 'idToken not provided' });
    }
    try {
      const data = await authClient.post('/auth/google', { idToken });
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({
        success: false,
        message: error.message || 'Google authentication failed',
      });
    }
  });

  fastify.post('/login', async (request: FastifyRequest, reply: FastifyReply) => {
    const { email, password } = request.body as { email: string; password: string };
    try {
      const data = await authClient.post('/auth/login', { email, password });
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({
        success: false,
        message: error.message || 'Login failed',
      });
    }
  });

  fastify.post('/register', async (request: FastifyRequest, reply: FastifyReply) => {
    const { name, email, password } = request.body as { name: string; email: string; password: string };
    try {
      const data = await authClient.post('/auth/register', { name, email, password });
      return reply.status(201).send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({
        success: false,
        message: error.message || 'Registration failed',
      });
    }
  });

  fastify.post('/refresh', async (request: FastifyRequest, reply: FastifyReply) => {
    const { refreshToken } = request.body as { refreshToken: string };
    try {
      const data = await authClient.post('/auth/refresh', { refreshToken });
      return reply.send(data);
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({
        success: false,
        message: error.message || 'Token refresh failed',
      });
    }
  });

  fastify.post('/logout', { preHandler: [fastify.authenticate] }, async (request: any, reply: FastifyReply) => {
    try {
      const token = request.headers.authorization?.replace('Bearer ', '');
      await authClient.post('/auth/logout', { token });
      return reply.send({ success: true, message: 'Logged out successfully' });
    } catch (error: any) {
      return reply.status(error.statusCode || 500).send({
        success: false,
        message: error.message || 'Logout failed',
      });
    }
  });
}