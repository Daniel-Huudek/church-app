import type { Prayer, PrayerCategory, PrayerComment, PrayerFilter, PrayerReactionType, PaginatedResponse } from '../types/prayer';
import { api } from './api';

interface ApiResponse<T> {
  success: boolean;
  data: T;
}

export const prayerKeys = {
  all: ['prayers'] as const,
  lists: () => [...prayerKeys.all, 'list'] as const,
  list: (filters: PrayerFilter) => [...prayerKeys.lists(), filters] as const,
  details: () => [...prayerKeys.all, 'detail'] as const,
  detail: (id: string) => [...prayerKeys.details(), id] as const,
  my: () => [...prayerKeys.all, 'my'] as const,
  urgent: () => [...prayerKeys.all, 'urgent'] as const,
  favorites: () => [...prayerKeys.all, 'favorites'] as const,
  categories: () => [...prayerKeys.all, 'categories'] as const,
};

export const prayersService = {
  list: async (filters?: PrayerFilter): Promise<PaginatedResponse<Prayer>> => {
    const response = await api.get<ApiResponse<PaginatedResponse<Prayer>>>('/prayers', {
      params: filters,
    });
    return response.data.data;
  },

  getMy: async (page = 1, limit = 20): Promise<PaginatedResponse<Prayer>> => {
    const response = await api.get<ApiResponse<PaginatedResponse<Prayer>>>('/prayers/my', {
      params: { page, limit },
    });
    return response.data.data;
  },

  getUrgent: async (page = 1, limit = 20): Promise<PaginatedResponse<Prayer>> => {
    const response = await api.get<ApiResponse<PaginatedResponse<Prayer>>>('/prayers/urgent', {
      params: { page, limit },
    });
    return response.data.data;
  },

  getFavorites: async (page = 1, limit = 20): Promise<PaginatedResponse<Prayer>> => {
    const response = await api.get<ApiResponse<PaginatedResponse<Prayer>>>('/prayers/favorites', {
      params: { page, limit },
    });
    return response.data.data;
  },

  getById: async (id: string): Promise<Prayer> => {
    const response = await api.get<ApiResponse<Prayer>>(`/prayers/${id}`);
    return response.data.data;
  },

  create: async (data: Partial<Prayer>): Promise<Prayer> => {
    const response = await api.post<ApiResponse<Prayer>>('/prayers', data);
    return response.data.data;
  },

  update: async (id: string, data: Partial<Prayer>): Promise<Prayer> => {
    const response = await api.put<ApiResponse<Prayer>>(`/prayers/${id}`, data);
    return response.data.data;
  },

  delete: async (id: string): Promise<void> => {
    await api.delete(`/prayers/${id}`);
  },

  markAnswered: async (id: string, answerDescription?: string): Promise<Prayer> => {
    const response = await api.post<ApiResponse<Prayer>>(`/prayers/${id}/answer`, { answerDescription });
    return response.data.data;
  },

  addComment: async (id: string, content: string): Promise<PrayerComment> => {
    const response = await api.post<ApiResponse<PrayerComment>>(`/prayers/${id}/comments`, { content });
    return response.data.data;
  },

  deleteComment: async (prayerId: string, commentId: string): Promise<void> => {
    await api.delete(`/prayers/${prayerId}/comments/${commentId}`);
  },

  toggleReaction: async (id: string, type: PrayerReactionType): Promise<void> => {
    await api.post(`/prayers/${id}/react`, { type });
  },

  intercede: async (id: string): Promise<void> => {
    await api.post(`/prayers/${id}/intercede`);
  },

  getIntercessors: async (id: string): Promise<Prayer['intercessors']> => {
    const response = await api.get<ApiResponse<Prayer['intercessors']>>(`/prayers/${id}/intercessors`);
    return response.data.data;
  },

  toggleFavorite: async (id: string): Promise<void> => {
    await api.post(`/prayers/${id}/favorite`);
  },

  getCategories: async (): Promise<PrayerCategory[]> => {
    const response = await api.get<ApiResponse<PrayerCategory[]>>('/prayers/categories');
    return response.data.data;
  },

  createCategory: async (data: Partial<PrayerCategory>): Promise<PrayerCategory> => {
    const response = await api.post<ApiResponse<PrayerCategory>>('/prayers/categories', data);
    return response.data.data;
  },

  updateCategory: async (id: string, data: Partial<PrayerCategory>): Promise<PrayerCategory> => {
    const response = await api.put<ApiResponse<PrayerCategory>>(`/prayers/categories/${id}`, data);
    return response.data.data;
  },

  deleteCategory: async (id: string): Promise<void> => {
    await api.delete(`/prayers/categories/${id}`);
  },
};
