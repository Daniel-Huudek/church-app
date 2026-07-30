import { describe, expect, it } from 'vitest';
import { addressSchema, memberSchema } from './schema.js';

describe('addressSchema', () => {
  const base = {
    street: 'Rua das Flores',
    neighborhood: 'Centro',
    city: 'Avaré',
    state: 'SP',
    zipCode: '18700-000',
  };

  it('accepts address without number and complement', () => {
    expect(addressSchema.parse(base)).toMatchObject(base);
  });

  it('accepts null number and complement (Flutter JSON)', () => {
    const parsed = addressSchema.parse({
      ...base,
      number: null,
      complement: null,
    });
    expect(parsed.number).toBeNull();
    expect(parsed.complement).toBeNull();
  });

  it('accepts filled optional fields', () => {
    const parsed = addressSchema.parse({
      ...base,
      number: '123',
      complement: 'Apto 2',
    });
    expect(parsed.number).toBe('123');
    expect(parsed.complement).toBe('Apto 2');
  });

  it('rejects missing required street', () => {
    expect(() =>
      addressSchema.parse({
        neighborhood: 'Centro',
        city: 'Avaré',
        state: 'SP',
        zipCode: '18700-000',
      }),
    ).toThrow();
  });
});

describe('memberSchema', () => {
  it('accepts member with address that has null optional fields', () => {
    const parsed = memberSchema.parse({
      name: 'João Silva',
      address: {
        street: 'Rua A',
        number: null,
        complement: null,
        neighborhood: 'Centro',
        city: 'Avaré',
        state: 'SP',
        zipCode: '18705-123',
      },
    });
    expect(parsed.name).toBe('João Silva');
    expect(parsed.address?.number).toBeNull();
    expect(parsed.address?.complement).toBeNull();
  });

  it('accepts member without address', () => {
    const parsed = memberSchema.parse({ name: 'Maria' });
    expect(parsed.address).toBeUndefined();
  });
});
