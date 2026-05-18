export interface Event {
  id: string;
  title: string;
  description: string;
  date: string;
  time: string;
  endDate?: string;
  endTime?: string;
  type: EventType;
  location?: string;
  address?: string;
  ministryId?: string;
  ministryName?: string;
  organizerId?: string;
  organizerName?: string;
  bannerUrl?: string;
  status: EventStatus;
  participants: EventParticipant[];
  maxParticipants?: number;
  budget?: number;
  notes?: string;
  createdAt: string;
  updatedAt: string;
}

export type EventType =
  | 'CULTO'
  | 'REUNIAO'
  | 'ESTUDO'
  | 'EVENTO_SOCIAL'
  | 'EVENTO_ESPECIAL'
  | 'ESCOLA_DOMINICAL'
  | 'JEJUM'
  | 'VIGILIA'
  | 'RETIRO'
  | 'OUTRO';

export type EventStatus =
  | 'AGENDADO'
  | 'CONFIRMADO'
  | 'EM_ANDAMENTO'
  | 'CONCLUIDO'
  | 'CANCELADO';

export interface EventParticipant {
  id: string;
  eventId: string;
  memberId: string;
  memberName: string;
  memberAvatar?: string;
  role: 'ORGANIZADOR' | 'PALESTRANTE' | 'VOLUNTARIO' | 'PARTICIPANTE' | 'CONVIDADO';
  status: 'CONFIRMADO' | 'PENDENTE' | 'RECUSADO' | 'LISTA_ESPERA';
  confirmedAt?: string;
  notes?: string;
  createdAt: string;
}

export interface EventFilter {
  page?: number;
  limit?: number;
  startDate?: string;
  endDate?: string;
  type?: EventType;
  status?: EventStatus;
  ministryId?: string;
  organizerId?: string;
  search?: string;
}

export type { PaginatedResponse } from './member';
