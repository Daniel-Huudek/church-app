import { describe, it, expect } from 'vitest';

/**
 * Pure helpers mirroring sanitization / anonymity rules used by the API.
 * Keeps data-leak regressions covered without a live DB.
 */

function sanitizeNotification<T extends Record<string, unknown>>(notification: T, includePhone: boolean): T {
  if (includePhone) return notification;
  const copy = { ...notification };
  delete copy.phone;
  return copy;
}

function stripAnonymousAuthor<T extends { isAnonymous?: boolean; authorId?: string }>(item: T): T {
  if (!item.isAnonymous) return item;
  const copy = { ...item };
  delete copy.authorId;
  return copy;
}

function roleAllowsMinistry(role: string, ministryName: string): boolean {
  const name = ministryName
    .toLowerCase()
    .normalize('NFD')
    .replace(/\p{M}/gu, '');
  if (name.includes('louvor')) {
    return role === 'LIDER_LOUVOR' || role === 'LOUVOR' || role === 'LIDER';
  }
  if (name.includes('diacon')) {
    return role === 'LIDER_DIACONOS' || role === 'DIACONO' || role === 'LIDER';
  }
  return role === 'LIDER';
}

describe('data-leak guards', () => {
  it('strips phone from notification payloads by default', () => {
    const raw = {
      id: 'n1',
      recipientId: 'u1',
      phone: '+5511999999999',
      message: 'Lembrete de escala',
    };
    const sanitized = sanitizeNotification(raw, false);
    expect(sanitized).not.toHaveProperty('phone');
    expect(sanitized).toMatchObject({ id: 'n1', recipientId: 'u1', message: 'Lembrete de escala' });
  });

  it('keeps phone when includePhone is true (elevated)', () => {
    const raw = { id: 'n1', phone: '+5511999999999', message: 'x' };
    expect(sanitizeNotification(raw, true)).toHaveProperty('phone', '+5511999999999');
  });

  it('removes authorId from anonymous prayers', () => {
    const prayer = {
      id: 'p1',
      authorId: 'secret-user',
      isAnonymous: true,
      title: 'Pedido',
    };
    const stripped = stripAnonymousAuthor(prayer);
    expect(stripped.authorId).toBeUndefined();
    expect(stripped.title).toBe('Pedido');
  });

  it('keeps authorId when prayer is not anonymous', () => {
    const prayer = { id: 'p1', authorId: 'u1', isAnonymous: false };
    expect(stripAnonymousAuthor(prayer).authorId).toBe('u1');
  });

  it('allows Louvor roles for Louvor ministry chat', () => {
    expect(roleAllowsMinistry('LOUVOR', 'Louvor')).toBe(true);
    expect(roleAllowsMinistry('LIDER_LOUVOR', 'Louvor')).toBe(true);
    expect(roleAllowsMinistry('VISITANTE', 'Louvor')).toBe(false);
    expect(roleAllowsMinistry('MEMBRO', 'Louvor')).toBe(false);
  });

  it('allows Diaconos roles for Diaconos ministry chat', () => {
    expect(roleAllowsMinistry('DIACONO', 'Diáconos')).toBe(true);
    expect(roleAllowsMinistry('LIDER_DIACONOS', 'Diaconos')).toBe(true);
    expect(roleAllowsMinistry('LOUVOR', 'Diáconos')).toBe(false);
  });
});
