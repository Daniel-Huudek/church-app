import { ZodSchema } from 'zod';
import { AppError } from './errors';
export function validate<T>(schema: ZodSchema<T>, data: unknown): T {
  const result = schema.safeParse(data);
  if (!result.success) throw new AppError(result.error.errors.map(e => e.message).join(', '), 400, 'VALIDATION_ERROR');
  return result.data;
}
