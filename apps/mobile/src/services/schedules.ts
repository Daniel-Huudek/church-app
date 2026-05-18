import type { Schedule } from '../types/schedule';
import type { ScheduleFilter, ScheduleConflict } from '../types/schedule';
import { api } from './api';

interface ApiResponse<T> {
  success: boolean;
  data: T;
}

interface PaginatedResult<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export const scheduleKeys = {
  all: ['schedules'] as const,
  lists: () => [...scheduleKeys.all, 'list'] as const,
  list: (filters: ScheduleFilter) => [...scheduleKeys.lists(), filters] as const,
  details: () => [...scheduleKeys.all, 'detail'] as const,
  detail: (id: string) => [...scheduleKeys.details(), id] as const,
};

export const schedulesService = {
  getAll: async (filters?: ScheduleFilter): Promise<PaginatedResult<Schedule>> => {
    const response = await api.get<ApiResponse<PaginatedResult<Schedule>>>('/schedules', {
      params: filters,
    });
    return response.data.data;
  },

  getById: async (id: string): Promise<Schedule> => {
    const response = await api.get<ApiResponse<Schedule>>(`/schedules/${id}`);
    return response.data.data;
  },

  create: async (data: Partial<Schedule>): Promise<Schedule> => {
    const response = await api.post<ApiResponse<Schedule>>('/schedules', data);
    return response.data.data;
  },

  update: async (id: string, data: Partial<Schedule>): Promise<Schedule> => {
    const response = await api.put<ApiResponse<Schedule>>(`/schedules/${id}`, data);
    return response.data.data;
  },

  delete: async (id: string): Promise<void> => {
    await api.delete(`/schedules/${id}`);
  },

  getByDateRange: async (startDate: string, endDate: string): Promise<Schedule[]> => {
    const response = await api.get<ApiResponse<Schedule[]>>('/schedules/range', {
      params: { startDate, endDate },
    });
    return response.data.data;
  },

  getByMember: async (memberId: string): Promise<Schedule[]> => {
    const response = await api.get<ApiResponse<Schedule[]>>(`/schedules/member/${memberId}`);
    return response.data.data;
  },

  getByMinistry: async (ministryId: string, startDate?: string, endDate?: string): Promise<Schedule[]> => {
    const response = await api.get<ApiResponse<Schedule[]>>(`/schedules/ministry/${ministryId}`, {
      params: { startDate, endDate },
    });
    return response.data.data;
  },

  addPosition: async (
    scheduleId: string,
    data: { memberId: string; position: string }
  ): Promise<Schedule['positions'][0]> => {
    const response = await api.post<ApiResponse<Schedule['positions'][0]>>(
      `/schedules/${scheduleId}/positions`,
      data
    );
    return response.data.data;
  },

  updatePosition: async (
    scheduleId: string,
    positionId: string,
    data: { memberId?: string; position?: string; status?: string }
  ): Promise<Schedule['positions'][0]> => {
    const response = await api.put<ApiResponse<Schedule['positions'][0]>>(
      `/schedules/${scheduleId}/positions/${positionId}`,
      data
    );
    return response.data.data;
  },

  removePosition: async (scheduleId: string, positionId: string): Promise<void> => {
    await api.delete(`/schedules/${scheduleId}/positions/${positionId}`);
  },

  checkConflicts: async (
    memberId: string,
    date: string,
    startTime: string,
    endTime: string
  ): Promise<ScheduleConflict[]> => {
    const response = await api.get<ApiResponse<ScheduleConflict[]>>('/schedules/conflicts', {
      params: { memberId, date, startTime, endTime },
    });
    return response.data.data;
  },

  updateStatus: async (id: string, status: string): Promise<Schedule> => {
    const response = await api.put<ApiResponse<Schedule>>(`/schedules/${id}/status`, { status });
    return response.data.data;
  },
};
