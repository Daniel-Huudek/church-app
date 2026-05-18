import type { Event, EventFilter, PaginatedResponse } from '../types/event';
import { api } from './api';

interface ApiResponse<T> {
  success: boolean;
  data: T;
}

export const eventKeys = {
  all: ['events'] as const,
  lists: () => [...eventKeys.all, 'list'] as const,
  list: (filters: EventFilter) => [...eventKeys.lists(), filters] as const,
  details: () => [...eventKeys.all, 'detail'] as const,
  detail: (id: string) => [...eventKeys.details(), id] as const,
};

export const eventsService = {
  getAll: async (filters?: EventFilter): Promise<PaginatedResponse<Event>> => {
    const response = await api.get<ApiResponse<PaginatedResponse<Event>>>('/events', {
      params: filters,
    });
    return response.data.data;
  },

  getById: async (id: string): Promise<Event> => {
    const response = await api.get<ApiResponse<Event>>(`/events/${id}`);
    return response.data.data;
  },

  create: async (data: Partial<Event>): Promise<Event> => {
    const response = await api.post<ApiResponse<Event>>('/events', data);
    return response.data.data;
  },

  update: async (id: string, data: Partial<Event>): Promise<Event> => {
    const response = await api.put<ApiResponse<Event>>(`/events/${id}`, data);
    return response.data.data;
  },

  delete: async (id: string): Promise<void> => {
    await api.delete(`/events/${id}`);
  },

  getParticipants: async (id: string): Promise<PaginatedResponse<Event['participants'][0]>> => {
    const response = await api.get<ApiResponse<PaginatedResponse<Event['participants'][0]>>>(
      `/events/${id}/participants`
    );
    return response.data.data;
  },

  addParticipant: async (
    eventId: string,
    data: { memberId: string; role: string }
  ): Promise<Event['participants'][0]> => {
    const response = await api.post<ApiResponse<Event['participants'][0]>>(
      `/events/${eventId}/participants`,
      data
    );
    return response.data.data;
  },

  updateParticipantStatus: async (
    eventId: string,
    participantId: string,
    status: string
  ): Promise<void> => {
    await api.put(`/events/${eventId}/participants/${participantId}`, { status });
  },

  removeParticipant: async (eventId: string, participantId: string): Promise<void> => {
    await api.delete(`/events/${eventId}/participants/${participantId}`);
  },

  getTypes: async (): Promise<string[]> => {
    const response = await api.get<ApiResponse<string[]>>('/events/types');
    return response.data.data;
  },
};
