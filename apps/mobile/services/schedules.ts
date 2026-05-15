import { api } from './api';

export interface Schedule {
  id: string;
  eventId: string;
  ministryId: string;
  date: string;
  startTime: string;
  endTime: string;
  positions: SchedulePosition[];
}

export interface SchedulePosition {
  id: string;
  scheduleId: string;
  memberId: string;
  position: string;
}

export interface SchedulesResponse {
  success: boolean;
  data: {
    data: Schedule[];
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  };
}

export const schedulesService = {
  getAll: async (params?: { page?: number; limit?: number }) => {
    const response = await api.get<SchedulesResponse>('/schedules', { params });
    return response.data;
  },

  getById: async (id: string) => {
    const response = await api.get(`/schedules/${id}`);
    return response.data;
  },

  create: async (data: Partial<Schedule>) => {
    const response = await api.post('/schedules', data);
    return response.data;
  },

  update: async (id: string, data: Partial<Schedule>) => {
    const response = await api.put(`/schedules/${id}`, data);
    return response.data;
  },

  delete: async (id: string) => {
    const response = await api.delete(`/schedules/${id}`);
    return response.data;
  },
};