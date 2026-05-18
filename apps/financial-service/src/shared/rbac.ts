import { FastifyRequest, FastifyReply } from 'fastify';
import { UnauthorizedError, ForbiddenError } from './errors.js';
import jwt from 'jsonwebtoken';

const ALLOWED_ROLES = {
  ADMINISTRADOR: 'ADMINISTRADOR',
  PASTOR: 'PASTOR',
  FINANCEIRO: 'FINANCEIRO',
  LIDER: 'LIDER',
  MEMBRO: 'MEMBRO',
} as const;

type Role = keyof typeof ALLOWED_ROLES;

export function authorize(...allowedRoles: Role[]) {
  return async (request: FastifyRequest, reply: FastifyReply) => {
    const authHeader = request.headers.authorization;
    if (!authHeader) {
      return reply.status(401).send({ success: false, message: 'Não autenticado' });
    }

    try {
      const token = authHeader.replace('Bearer ', '');
      const secret = process.env.JWT_SECRET || 'default-secret-change-me';
      const decoded = jwt.verify(token, secret) as { userId: string; email: string; role: Role; permissions: string[] };

      if (!allowedRoles.includes(decoded.role)) {
        return reply.status(403).send({ success: false, message: 'Acesso negado' });
      }

      (request as any).user = decoded;
    } catch (error) {
      return reply.status(401).send({ success: false, message: 'Token inválido' });
    }
  };
}

export function getUserId(request: FastifyRequest): string {
  return (request as any).user?.userId;
}

export function getUserRole(request: FastifyRequest): string {
  return (request as any).user?.role;
}
