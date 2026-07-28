import type { FastifyRequest, FastifyReply } from 'fastify';
import jwt from 'jsonwebtoken';
import { UnauthorizedError, ForbiddenError } from './errors.js';

export const ALLOWED_ROLES = {
  ADMINISTRADOR: 'ADMINISTRADOR',
  PASTOR: 'PASTOR',
  FINANCEIRO: 'FINANCEIRO',
  LIDER: 'LIDER',
  LIDER_LOUVOR: 'LIDER_LOUVOR',
  LOUVOR: 'LOUVOR',
  LIDER_DIACONOS: 'LIDER_DIACONOS',
  DIACONO: 'DIACONO',
  MEMBRO: 'MEMBRO',
  VISITANTE: 'VISITANTE',
} as const;

export type Role = keyof typeof ALLOWED_ROLES;

export type AuthUser = {
  userId: string;
  email: string;
  role: Role;
  permissions: string[];
};

type RequestWithUser = FastifyRequest & { user?: AuthUser };

function asRequestWithUser(request: FastifyRequest): RequestWithUser {
  return request as RequestWithUser;
}

function getJwtSecret(): string {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    throw new Error('JWT_SECRET environment variable is not set');
  }
  return secret;
}

function decodeToken(authHeader: string | undefined): AuthUser {
  if (!authHeader) {
    throw new UnauthorizedError('Unauthorized');
  }

  const token = authHeader.replace(/^Bearer\s+/i, '');
  const decoded = jwt.verify(token, getJwtSecret()) as AuthUser;

  if (!decoded?.userId || !decoded?.role) {
    throw new UnauthorizedError('Invalid token');
  }

  return {
    userId: decoded.userId,
    email: decoded.email,
    role: decoded.role,
    permissions: decoded.permissions ?? [],
  };
}

/** Verifies JWT from Authorization header and attaches request.user */
export function authenticate() {
  return async (request: FastifyRequest, reply: FastifyReply) => {
    try {
      asRequestWithUser(request).user = decodeToken(request.headers.authorization);
    } catch (error) {
      if (error instanceof UnauthorizedError) {
        return reply.status(401).send({ success: false, message: error.message });
      }
      return reply.status(401).send({ success: false, message: 'Invalid token' });
    }
  };
}

/** Requires authenticated user with one of the allowed roles */
export function authorize(...allowedRoles: Role[]) {
  return async (request: FastifyRequest, reply: FastifyReply) => {
    try {
      const req = asRequestWithUser(request);
      const user = req.user?.userId
        ? req.user
        : decodeToken(request.headers.authorization);

      if (!allowedRoles.includes(user.role as Role)) {
        return reply.status(403).send({ success: false, message: 'Forbidden' });
      }

      req.user = user;
    } catch (error) {
      if (error instanceof UnauthorizedError) {
        return reply.status(401).send({ success: false, message: error.message });
      }
      return reply.status(401).send({ success: false, message: 'Invalid token' });
    }
  };
}

/**
 * Gateway helper: assumes request.user already set by @fastify/jwt authenticate.
 * Returns 403 if role is not allowed.
 */
export function requireRoles(...allowedRoles: Role[]) {
  return async (request: FastifyRequest, reply: FastifyReply) => {
    const role = asRequestWithUser(request).user?.role as Role | undefined;
    if (!role || !allowedRoles.includes(role)) {
      return reply.status(403).send({ success: false, message: 'Forbidden' });
    }
  };
}

/** Throws if request has no authenticated userId */
export function requireAuthUser(request: FastifyRequest): AuthUser {
  const user = asRequestWithUser(request).user;
  if (!user?.userId) {
    throw new UnauthorizedError('Unauthorized');
  }
  return {
    userId: user.userId,
    email: user.email ?? '',
    role: (user.role as Role) ?? 'MEMBRO',
    permissions: user.permissions ?? [],
  };
}

export function getUserId(request: FastifyRequest): string | undefined {
  return asRequestWithUser(request).user?.userId;
}

export function getUserRole(request: FastifyRequest): string | undefined {
  return asRequestWithUser(request).user?.role;
}

export function assertFinanceWriteRole(role: string) {
  const allowed: Role[] = ['ADMINISTRADOR', 'PASTOR', 'FINANCEIRO'];
  if (!allowed.includes(role as Role)) {
    throw new ForbiddenError('Insufficient permissions for finance operations');
  }
}

export function assertUserAdminRole(role: string) {
  const allowed: Role[] = ['ADMINISTRADOR', 'PASTOR'];
  if (!allowed.includes(role as Role)) {
    throw new ForbiddenError('Insufficient permissions for user administration');
  }
}

const ELEVATED_ROLES: Role[] = ['ADMINISTRADOR', 'PASTOR'];

/**
 * Requires JWT user to have at least one of the listed permissions.
 * ADMINISTRADOR / PASTOR always pass (elevated church roles).
 */
export function authorizePermissions(...requiredPermissions: string[]) {
  return async (request: FastifyRequest, reply: FastifyReply) => {
    try {
      const req = asRequestWithUser(request);
      const user = req.user?.userId
        ? req.user
        : decodeToken(request.headers.authorization);

      req.user = user;

      if (ELEVATED_ROLES.includes(user.role as Role)) {
        return;
      }

      const perms = user.permissions ?? [];
      const allowed = requiredPermissions.some((p) => perms.includes(p));
      if (!allowed) {
        return reply.status(403).send({ success: false, message: 'Forbidden' });
      }
    } catch (error) {
      if (error instanceof UnauthorizedError) {
        return reply.status(401).send({ success: false, message: error.message });
      }
      return reply.status(401).send({ success: false, message: 'Invalid token' });
    }
  };
}

/** True if user has permission or is elevated admin/pastor. */
export function userHasPermission(user: AuthUser, permission: string): boolean {
  if (ELEVATED_ROLES.includes(user.role as Role)) return true;
  return (user.permissions ?? []).includes(permission);
}
