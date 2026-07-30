import { z } from 'zod';

/** Campos opcionais que o cliente (Flutter/JSON) pode enviar como null. */
const optionalString = z.string().nullable().optional();

export const addressSchema = z.object({
  street: z.string().min(1),
  number: optionalString,
  complement: optionalString,
  neighborhood: z.string().min(1),
  city: z.string().min(1),
  state: z.string().min(1),
  zipCode: z.string().min(1),
});

export const memberSchema = z.object({
  name: z.string().min(1),
  nickname: optionalString,
  email: z.string().email().optional(),
  phone: z.string().optional(),
  dateOfBirth: z.string().optional(),
  gender: z.string().optional(),
  maritalStatus: z.string().optional(),
  baptismDate: z.string().optional(),
  baptismChurch: z.string().optional(),
  conversionDate: z.string().optional(),
  admissionDate: z.string().optional(),
  admissionType: z.enum(['BATISMO', 'TRANSFERENCIA', 'RECONCILIACAO', 'OUTRO']).optional(),
  isBaptized: z.boolean().default(false),
  status: z.enum(['ATIVO', 'INATIVO', 'AFASTADO', 'TRANSFERIDO', 'EXCLUIDO']).default('ATIVO'),
  role: z.enum(['MEMBRO', 'DIACONO', 'PRESBITERO', 'PASTOR']).default('MEMBRO'),
  ministryId: z.string().uuid().optional(),
  ministryIds: z.array(z.string().uuid()).optional(),
  occupation: z.string().optional(),
  notes: z.string().optional(),
  userId: z.string().uuid().nullable().optional(),
  forceDuplicate: z.boolean().optional(),
  address: addressSchema.optional(),
});

export const documentSchema = z.object({
  type: z.string().min(1),
  value: z.string().min(1),
});

export const familySchema = z.object({
  name: z.string().min(1),
  kinship: z.string().min(1),
  phone: z.string().optional(),
});

export const historySchema = z.object({
  ministry: z.string().min(1),
  role: z.string().min(1),
  startDate: z.string(),
  endDate: z.string().optional(),
  description: z.string().optional(),
});

export const ministrySchema = z.object({
  name: z.string().min(1),
  description: z.string().optional(),
  leaderId: z.string().uuid().optional(),
});
