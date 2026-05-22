export interface Schedule {
  id: string;
  eventId: string;
  eventName?: string;
  ministryId: string;
  ministryName?: string;
  date: string;
  startTime: string;
  endTime: string;
  positions: SchedulePosition[];
  notes?: string;
  status: ScheduleStatus;
  createdAt: string;
  updatedAt: string;
}

export interface SchedulePosition {
  id: string;
  scheduleId: string;
  memberId: string;
  memberName?: string;
  memberAvatar?: string;
  position: string;
  status: 'CONFIRMADO' | 'PENDENTE' | 'SUBSTITUIDO' | 'AUSENTE';
  substituteId?: string;
  substituteName?: string;
  notes?: string;
  createdAt: string;
  updatedAt: string;
}

export type ScheduleStatus =
  | 'AGENDADO'
  | 'CONFIRMADO'
  | 'EM_ANDAMENTO'
  | 'CONCLUIDO'
  | 'CANCELADO';

export interface ScheduleFilter {
  page?: number;
  limit?: number;
  startDate?: string;
  endDate?: string;
  ministryId?: string;
  eventId?: string;
  memberId?: string;
  status?: ScheduleStatus;
  position?: string;
  search?: string;
}

export interface ScheduleConflict {
  memberId: string;
  memberName: string;
  conflictingDate: string;
  conflictingTime: string;
  existingScheduleId: string;
  existingScheduleName: string;
}
