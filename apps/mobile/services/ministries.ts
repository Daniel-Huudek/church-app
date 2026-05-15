import { api } from './api';

export interface Ministry {
  id: string;
  name: string;
  description?: string;
  leaderId?: string;
}

export interface MinistriesResponse {
  success: boolean;
  data: {
    data: Ministry[];
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  };
}

export const ministriesService = {
  getAll: async (params?: { page?: number; limit?: number }) => {
    const response = await api.get<MinistriesResponse>('/ministries', { params });
    return response.data;
  },

  getById: async (id: string) => {
    const response = await api.get(`/ministries/${id}`);
    return response.data;
  },

  create: async (data: Partial<Ministry>) => {
    const response = await api.post('/ministries', data);
    return response.data;
  },

  update: async (id: string, data: Partial<Ministry>) => {
    const response = await api.put(`/ministries/${id}`, data);
    return response.data;
  },

  delete: async (id: string) => {
    const response = await api.delete(`/ministries/${id}`);
    return response.data;
  },
};