import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import jwt from 'jsonwebtoken';
import {
  authorize,
  requireRoles,
  requireAuthUser,
  assertFinanceWriteRole,
  assertUserAdminRole,
  ALLOWED_ROLES,
} from '../src/rbac.js';
import { ForbiddenError, UnauthorizedError } from '../src/errors.js';

function mockReply() {
  return {
    statusCode: 200,
    body: null as unknown,
    status(code: number) {
      this.statusCode = code;
      return this;
    },
    send(payload: unknown) {
      this.body = payload;
      return this;
    },
  };
}

describe('rbac', () => {
  const secret = 'test-secret';

  beforeEach(() => {
    process.env.JWT_SECRET = secret;
  });

  afterEach(() => {
    delete process.env.JWT_SECRET;
  });

  it('exposes expected roles', () => {
    expect(ALLOWED_ROLES.ADMINISTRADOR).toBe('ADMINISTRADOR');
    expect(ALLOWED_ROLES.LOUVOR).toBe('LOUVOR');
  });

  it('authorize allows matching role', async () => {
    const token = jwt.sign(
      { userId: 'u1', email: 'a@b.com', role: 'FINANCEIRO', permissions: [] },
      secret,
    );
    const request: any = { headers: { authorization: `Bearer ${token}` } };
    const reply = mockReply();
    await authorize('FINANCEIRO', 'ADMINISTRADOR')(request, reply as any);
    expect(reply.statusCode).toBe(200);
    expect(request.user.userId).toBe('u1');
  });

  it('authorize rejects wrong role', async () => {
    const token = jwt.sign(
      { userId: 'u1', email: 'a@b.com', role: 'MEMBRO', permissions: [] },
      secret,
    );
    const request: any = { headers: { authorization: `Bearer ${token}` } };
    const reply = mockReply();
    await authorize('ADMINISTRADOR')(request, reply as any);
    expect(reply.statusCode).toBe(403);
  });

  it('requireRoles uses request.user from gateway', async () => {
    const request: any = { user: { userId: 'u1', role: 'PASTOR' } };
    const reply = mockReply();
    await requireRoles('ADMINISTRADOR', 'PASTOR')(request, reply as any);
    expect(reply.statusCode).toBe(200);

    const denied = mockReply();
    await requireRoles('ADMINISTRADOR')(request, denied as any);
    expect(denied.statusCode).toBe(403);
  });

  it('requireAuthUser throws when missing', () => {
    expect(() => requireAuthUser({} as any)).toThrow(UnauthorizedError);
  });

  it('assertFinanceWriteRole and assertUserAdminRole', () => {
    expect(() => assertFinanceWriteRole('FINANCEIRO')).not.toThrow();
    expect(() => assertFinanceWriteRole('MEMBRO')).toThrow(ForbiddenError);
    expect(() => assertUserAdminRole('ADMINISTRADOR')).not.toThrow();
    expect(() => assertUserAdminRole('FINANCEIRO')).toThrow(ForbiddenError);
  });
});
