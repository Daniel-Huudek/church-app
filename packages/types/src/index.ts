export type Role = 'ADMIN' | 'LEADER' | 'MEMBER';

export type Permission =
  | 'users:read'
  | 'users:write'
  | 'users:delete'
  | 'schedules:read'
  | 'schedules:write'
  | 'schedules:delete'
  | 'events:read'
  | 'events:write'
  | 'events:delete'
  | 'ministries:read'
  | 'ministries:write'
  | 'ministries:delete'
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
  userId: string;
  name: string;
  email: string;
  phone: string;
  avatar?: string;
  role: Role;
  ministryId?: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
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