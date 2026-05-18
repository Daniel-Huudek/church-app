import { z, ZodSchema, ZodError } from 'zod';
import { ValidationError } from './errors.js';

export function validate<T>(schema: ZodSchema<T>, data: unknown): T {
  try {
    return schema.parse(data);
  } catch (error) {
    if (error instanceof ZodError) {
      const details = error.errors.map((e) => ({
        path: e.path.join('.'),
        message: e.message,
      }));
      throw new ValidationError('Validation failed', details);
    }
    throw error;
  }
}

export function validatePartial<T>(schema: ZodSchema<T>, data: unknown): Partial<T> {
  try {
    return schema.partial().parse(data);
  } catch (error) {
    if (error instanceof ZodError) {
      const details = error.errors.map((e) => ({
        path: e.path.join('.'),
        message: e.message,
      }));
      throw new ValidationError('Validation failed', details);
    }
    throw error;
  }
}

export const uuidSchema = z.string().uuid();
export const emailSchema = z.string().email();
export const paginationSchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
});

export function parsePagination(query: unknown) {
  return paginationSchema.parse(query ?? {});
}
