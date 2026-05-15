import { api } from './api';

export interface Event {
  id: string;
  title: string;
  description: string;
  date: string;
  time: string;
  type: string;
  location?: string;
}

export interface EventsResponse {
  success: boolean;
  data: {
    data: Event[];
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  };
}

export const eventsService = {
  getAll: async (params?: { page?: number; limit?: number; startDate?: string; endDate?: string; type?: string }) => {
    const response = await api.get<EventsResponse>('/events', { params });
    return response.data;
  },

  getById: async (id: string) => {
    const response = await api.get(`/events/${id}`);
    return response.data;
  },

  create: async (data: Partial<Event>) => {
    const response = await api.post('/events', data);
    return response.data;
  },

  update: async (id: string, data: Partial<Event>) => {
    const response = await api.put(`/events/${id}`, data);
    return response.data;
  },

  delete: async (id: string) => {
    const response = await api.delete(`/events/${id}`);
    return response.data;
  },
};