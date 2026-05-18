import { z } from 'zod';

const phoneRegex = /^\(?\d{2}\)?\s?\d{4,5}-?\d{4}$/;
const cpfRegex = /^\d{3}\.\d{3}\.\d{3}-\d{2}$|^\d{11}$/;

export const loginSchema = z.object({
  email: z
    .string()
    .min(1, 'O email é obrigatório')
    .email('Informe um email válido'),
  password: z
    .string()
    .min(6, 'A senha deve ter no mínimo 6 caracteres'),
});

export const registerSchema = z
  .object({
    name: z
      .string()
      .min(3, 'O nome deve ter no mínimo 3 caracteres')
      .max(100, 'O nome deve ter no máximo 100 caracteres'),
    email: z
      .string()
      .min(1, 'O email é obrigatório')
      .email('Informe um email válido'),
    password: z
      .string()
      .min(6, 'A senha deve ter no mínimo 6 caracteres')
      .max(50, 'A senha deve ter no máximo 50 caracteres'),
    confirmPassword: z
      .string()
      .min(1, 'A confirmação de senha é obrigatória'),
    phone: z
      .string()
      .regex(phoneRegex, 'Informe um telefone válido')
      .optional()
      .or(z.literal('')),
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: 'As senhas não conferem',
    path: ['confirmPassword'],
  });

export const prayerSchema = z.object({
  title: z
    .string()
    .min(3, 'O título deve ter no mínimo 3 caracteres')
    .max(100, 'O título deve ter no máximo 100 caracteres'),
  description: z
    .string()
    .min(10, 'A descrição deve ter no mínimo 10 caracteres')
    .max(1000, 'A descrição deve ter no máximo 1000 caracteres'),
  category: z
    .string()
    .min(1, 'Selecione uma categoria'),
  isUrgent: z.boolean().optional().default(false),
  isAnonymous: z.boolean().optional().default(false),
});

export const transactionSchema = z.object({
  description: z
    .string()
    .min(3, 'A descrição deve ter no mínimo 3 caracteres')
    .max(200, 'A descrição deve ter no máximo 200 caracteres'),
  amount: z
    .number()
    .positive('O valor deve ser positivo'),
  type: z.enum(['RECEITA', 'DESPESA'], {
    required_error: 'Selecione o tipo de transação',
  }),
  categoryId: z
    .string()
    .min(1, 'Selecione uma categoria'),
  costCenterId: z.string().optional(),
  date: z
    .string()
    .min(1, 'Informe a data'),
  paymentMethod: z
    .enum(['DINHEIRO', 'PIX', 'CARTAO_CREDITO', 'CARTAO_DEBITO', 'BOLETO', 'TRANSFERENCIA', 'DEPOSITO', 'CHEQUE', 'OUTRO'])
    .optional(),
  notes: z.string().max(500, 'As observações devem ter no máximo 500 caracteres').optional(),
});

export const memberSchema = z.object({
  name: z
    .string()
    .min(3, 'O nome deve ter no mínimo 3 caracteres')
    .max(100, 'O nome deve ter no máximo 100 caracteres'),
  email: z
    .string()
    .min(1, 'O email é obrigatório')
    .email('Informe um email válido'),
  phone: z
    .string()
    .regex(phoneRegex, 'Informe um telefone válido'),
  birthDate: z
    .string()
    .min(1, 'Informe a data de nascimento'),
  cpf: z
    .string()
    .regex(cpfRegex, 'Informe um CPF válido')
    .optional()
    .or(z.literal('')),
  gender: z.enum(['MASCULINO', 'FEMININO', 'OUTRO']).optional(),
  maritalStatus: z.enum(['SOLTEIRO', 'CASADO', 'DIVORCIADO', 'VIUVO', 'SEPARADO']).optional(),
  profession: z.string().max(100).optional(),
});

export const eventSchema = z.object({
  title: z
    .string()
    .min(3, 'O título deve ter no mínimo 3 caracteres')
    .max(100, 'O título deve ter no máximo 100 caracteres'),
  description: z
    .string()
    .min(10, 'A descrição deve ter no mínimo 10 caracteres')
    .max(2000, 'A descrição deve ter no máximo 2000 caracteres'),
  date: z
    .string()
    .min(1, 'Informe a data do evento'),
  time: z
    .string()
    .min(1, 'Informe o horário do evento'),
  type: z.enum(['CULTO', 'REUNIAO', 'ESTUDO', 'EVENTO_SOCIAL', 'EVENTO_ESPECIAL', 'ESCOLA_DOMINICAL', 'JEJUM', 'VIGILIA', 'RETIRO', 'OUTRO'], {
    required_error: 'Selecione o tipo de evento',
  }),
  location: z.string().max(200).optional(),
  endDate: z.string().optional(),
  endTime: z.string().optional(),
  maxParticipants: z.number().positive().optional(),
});

export const scheduleSchema = z.object({
  date: z
    .string()
    .min(1, 'Informe a data'),
  startTime: z
    .string()
    .min(1, 'Informe o horário de início'),
  endTime: z
    .string()
    .min(1, 'Informe o horário de término'),
  eventId: z
    .string()
    .min(1, 'Selecione um evento'),
  ministryId: z
    .string()
    .min(1, 'Selecione um ministério'),
  positions: z
    .array(
      z.object({
        memberId: z.string().min(1, 'Selecione um membro'),
        position: z.string().min(1, 'Informe a posição'),
      })
    )
    .optional(),
});

export const profileSchema = z.object({
  name: z
    .string()
    .min(3, 'O nome deve ter no mínimo 3 caracteres')
    .max(100, 'O nome deve ter no máximo 100 caracteres'),
  email: z
    .string()
    .min(1, 'O email é obrigatório')
    .email('Informe um email válido'),
  phone: z
    .string()
    .regex(phoneRegex, 'Informe um telefone válido')
    .optional()
    .or(z.literal('')),
});

export const messageSchema = z.object({
  content: z
    .string()
    .min(1, 'A mensagem não pode estar vazia')
    .max(2000, 'A mensagem deve ter no máximo 2000 caracteres'),
});

export const financeFilterSchema = z.object({
  startDate: z.string().optional(),
  endDate: z.string().optional(),
  type: z.enum(['RECEITA', 'DESPESA']).optional(),
  status: z.enum(['PENDENTE', 'CONFIRMADO', 'CANCELADO']).optional(),
  categoryId: z.string().optional(),
  costCenterId: z.string().optional(),
  minAmount: z.number().positive().optional(),
  maxAmount: z.number().positive().optional(),
  paymentMethod: z
    .enum(['DINHEIRO', 'PIX', 'CARTAO_CREDITO', 'CARTAO_DEBITO', 'BOLETO', 'TRANSFERENCIA', 'DEPOSITO', 'CHEQUE', 'OUTRO'])
    .optional(),
  search: z.string().optional(),
});

export type LoginFormData = z.infer<typeof loginSchema>;
export type RegisterFormData = z.infer<typeof registerSchema>;
export type PrayerFormData = z.infer<typeof prayerSchema>;
export type TransactionFormData = z.infer<typeof transactionSchema>;
export type MemberFormData = z.infer<typeof memberSchema>;
export type EventFormData = z.infer<typeof eventSchema>;
export type ScheduleFormData = z.infer<typeof scheduleSchema>;
export type ProfileFormData = z.infer<typeof profileSchema>;
export type MessageFormData = z.infer<typeof messageSchema>;
export type FinanceFilterFormData = z.infer<typeof financeFilterSchema>;
