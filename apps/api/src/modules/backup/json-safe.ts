export const BACKUP_VERSION = 1;

/** Detecta Decimal do Prisma sem importar o client gerado. */
function isDecimalLike(value: object): value is { toString(): string } {
  const ctor = (value as { constructor?: { name?: string } }).constructor?.name;
  return (
    ctor === 'Decimal' &&
    typeof (value as { toFixed?: unknown }).toFixed === 'function' &&
    typeof (value as { toString?: unknown }).toString === 'function'
  );
}

/** Converte Decimal/Date/BigInt para JSON seguro. */
export function jsonSafe(value: unknown): unknown {
  if (value === null || value === undefined) return value;
  if (typeof value === 'bigint') return value.toString();
  if (value instanceof Date) return value.toISOString();
  if (typeof value === 'object' && !Array.isArray(value) && isDecimalLike(value)) {
    return value.toString();
  }
  if (Array.isArray(value)) return value.map(jsonSafe);
  if (typeof value === 'object') {
    const out: Record<string, unknown> = {};
    for (const [key, nested] of Object.entries(value as Record<string, unknown>)) {
      out[key] = jsonSafe(nested);
    }
    return out;
  }
  return value;
}
