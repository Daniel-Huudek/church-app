export type Role = 'ADMINISTRADOR' | 'PASTOR' | 'FINANCEIRO' | 'LIDER' | 'MEMBRO';

export type Permission =
  | 'users:read'
  | 'users:write'
  | 'users:delete'
  | 'members:read'
  | 'members:write'
  | 'members:delete'
  | 'members:export'
  | 'members:import'
  | 'ministries:read'
  | 'ministries:write'
  | 'ministries:delete'
  | 'schedules:read'
  | 'schedules:write'
  | 'schedules:delete'
  | 'events:read'
  | 'events:write'
  | 'events:delete'
  | 'prayers:read'
  | 'prayers:write'
  | 'prayers:delete'
  | 'prayers:comment'
  | 'prayers:react'
  | 'finance:read'
  | 'finance:write'
  | 'finance:delete'
  | 'finance:export'
  | 'finance:audit'
  | 'finance:close'
  | 'finance:reports'
  | 'notifications:send';

export interface User {
  id: string;
  email: string;
  name: string;
  avatar?: string;
  role: Role;
  permissions: Permission[];
  createdAt: Date;
  updatedAt: Date;
}

export interface Member {
  id: string;
  userId?: string;
  name: string;
  email?: string;
  phone?: string;
  avatar?: string;
  dateOfBirth?: Date;
  gender?: string;
  maritalStatus?: string;
  baptismDate?: Date;
  baptismChurch?: string;
  conversionDate?: Date;
  isBaptized: boolean;
  status: MemberStatus;
  role: MemberRole;
  ministryId?: string;
  occupation?: string;
  notes?: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export type MemberStatus = 'ATIVO' | 'INATIVO' | 'AFASTADO' | 'TRANSFERIDO' | 'EXCLUIDO';
export type MemberRole = 'MEMBRO' | 'DIACONO' | 'PRESBITERO' | 'PASTOR';

export interface Address {
  id: string;
  memberId: string;
  street: string;
  number?: string;
  complement?: string;
  neighborhood: string;
  city: string;
  state: string;
  zipCode: string;
}

export interface Document {
  id: string;
  memberId: string;
  type: string;
  value: string;
}

export interface FamilyMember {
  id: string;
  memberId: string;
  name: string;
  kinship: string;
  phone?: string;
}

export interface MinisterialHistory {
  id: string;
  memberId: string;
  ministry: string;
  role: string;
  startDate: Date;
  endDate?: Date;
  description?: string;
}

export interface Ministry {
  id: string;
  name: string;
  description?: string;
  leaderId: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface Schedule {
  id: string;
  eventId: string;
  ministryId: string;
  date: Date;
  startTime: string;
  endTime: string;
  positions: SchedulePosition[];
  createdAt: Date;
  updatedAt: Date;
}

export interface SchedulePosition {
  id: string;
  scheduleId: string;
  memberId: string;
  position: string;
  isConfirmed: boolean;
  isSubstituted: boolean;
  substitutedById?: string;
}

export interface Event {
  id: string;
  title: string;
  description?: string;
  type: 'WORSHIP' | 'EVENT' | 'REHEARSAL';
  date: Date;
  startTime: string;
  endTime: string;
  location?: string;
  isRecurring: boolean;
  recurrenceRule?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface PrayerRequest {
  id: string;
  authorId: string;
  title: string;
  content: string;
  categoryId?: string;
  isPublic: boolean;
  isAnonymous: boolean;
  isUrgent: boolean;
  isAnswered: boolean;
  answeredAt?: Date;
  viewsCount: number;
  createdAt: Date;
  updatedAt: Date;
  comments?: PrayerComment[];
  reactions?: PrayerReaction[];
  intercessorsCount?: number;
}

export interface PrayerCategory {
  id: string;
  name: string;
  color?: string;
  icon?: string;
}

export interface PrayerComment {
  id: string;
  prayerId: string;
  authorId: string;
  content: string;
  createdAt: Date;
}

export interface PrayerReaction {
  id: string;
  prayerId: string;
  userId: string;
  type: 'PRAYING' | 'AMEN' | 'THANKS';
  createdAt: Date;
}

export interface FinancialTransaction {
  id: string;
  type: TransactionType;
  value: number;
  description?: string;
  date: Date;
  dueDate?: Date;
  paymentDate?: Date;
  categoryId?: string;
  costCenterId?: string;
  createdById: string;
  status: TransactionStatus;
  paymentMethod?: string;
  isRecurring: boolean;
  recurrenceRule?: string;
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
  category?: TransactionCategory;
  costCenter?: CostCenter;
  attachments?: Attachment[];
}

export type TransactionType = 'INCOME' | 'EXPENSE' | 'TITHE' | 'OFFERING';
export type TransactionStatus = 'PENDING' | 'CONFIRMED' | 'CANCELLED';

export interface TransactionCategory {
  id: string;
  name: string;
  type: TransactionType;
  description?: string;
  color?: string;
}

export interface CostCenter {
  id: string;
  name: string;
  description?: string;
  budget?: number;
}

export interface Attachment {
  id: string;
  transactionId: string;
  filename: string;
  originalName: string;
  mimeType: string;
  size: number;
  url: string;
  type: 'RECEIPT' | 'PROOF' | 'DOCUMENT' | 'OTHER';
  createdAt: Date;
}

export interface FinancialAuditLog {
  id: string;
  transactionId: string;
  action: string;
  changedById: string;
  changedByRole?: string;
  oldValue?: unknown;
  newValue?: unknown;
  createdAt: Date;
}

export interface MonthlyClose {
  id: string;
  referenceDate: Date;
  totalIncome: number;
  totalExpense: number;
  balance: number;
  closedById: string;
  closedAt: Date;
  status: 'OPEN' | 'CLOSED' | 'REOPENED';
  notes?: string;
}

export interface FinancialDashboard {
  balance: number;
  totalIncome: number;
  totalExpense: number;
  incomeByCategory: { category: string; value: number }[];
  expenseByCategory: { category: string; value: number }[];
  monthlyHistory: { month: string; income: number; expense: number; balance: number }[];
}

export interface Notification {
  id: string;
  type: 'SCHEDULE_REMINDER' | 'ATTENDANCE_CONFIRMATION' | 'GENERAL';
  recipientId: string;
  message: string;
  status: 'PENDING' | 'SENT' | 'FAILED';
  sentAt?: Date;
  createdAt: Date;
}

export interface TokenPayload {
  userId: string;
  email: string;
  role: Role;
  permissions: Permission[];
  iat: number;
  exp: number;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}

export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export interface HttpError {
  statusCode: number;
  message: string;
  code?: string;
  details?: unknown;
}
