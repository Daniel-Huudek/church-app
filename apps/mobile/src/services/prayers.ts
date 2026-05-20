import type { Prayer, PrayerCategory, PrayerComment, PrayerFilter, PrayerReaction, PrayerReactionType, PrayerIntercessor, PaginatedResponse } from '../types/prayer';
import { api } from './api';

interface ApiResponse<T> {
  success: boolean;
  data: T;
}

interface RawPrayer {
  id: string;
  title: string;
  content: string;
  categoryId?: string;
  isUrgent: boolean;
  isAnswered: boolean;
  isAnonymous: boolean;
  authorId: string;
  createdAt: string;
  updatedAt: string;
  answeredAt?: string;
  answerDescription?: string;
  category?: any;
  comments?: any[];
  reactions?: any[];
  intercessors?: any[];
  _count?: { comments?: number; reactions?: number; intercessors?: number; favoritedBy?: number };
}

function mapPrayer(raw: RawPrayer): Prayer {
  return {
    id: raw.id,
    title: raw.title,
    content: raw.content,
    description: raw.content,
    category: raw.category || null as any,
    categoryName: raw.category?.name,
    isUrgent: raw.isUrgent,
    isAnswered: raw.isAnswered,
    isAnonymous: raw.isAnonymous,
    commentsCount: raw._count?.comments || raw.comments?.length || 0,
    reactionsCount: raw._count?.reactions || raw.reactions?.length || 0,
    intercessionCount: raw._count?.intercessors || raw.intercessors?.length || 0,
    authorId: raw.authorId,
    authorName: '',
    authorAvatar: undefined,
    comments: (raw.comments || []) as PrayerComment[],
    reactions: (raw.reactions || []) as PrayerReaction[],
    intercessors: (raw.intercessors || []) as PrayerIntercessor[],
    createdAt: raw.createdAt,
    updatedAt: raw.updatedAt,
    answeredAt: raw.answeredAt,
    answerDescription: raw.answerDescription,
  };
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

function mapListData(res: PaginatedResponse<RawPrayer>): PaginatedResponse<Prayer> {
  return { ...res, data: (res.data || []).map(mapPrayer) };
}

export const prayersService = {
  list: async (filters?: PrayerFilter): Promise<PaginatedResponse<Prayer>> => {
    const response = await api.get<ApiResponse<PaginatedResponse<RawPrayer>>>('/prayers', {
      params: filters,
    });
    return mapListData(response.data.data);
  },

  getMy: async (page = 1, limit = 20): Promise<PaginatedResponse<Prayer>> => {
    const response = await api.get<ApiResponse<PaginatedResponse<RawPrayer>>>('/prayers/my', {
      params: { page, limit },
    });
    return mapListData(response.data.data);
  },

  getUrgent: async (page = 1, limit = 20): Promise<PaginatedResponse<Prayer>> => {
    const response = await api.get<ApiResponse<PaginatedResponse<RawPrayer>>>('/prayers/urgent', {
      params: { page, limit },
    });
    return mapListData(response.data.data);
  },

  getFavorites: async (page = 1, limit = 20): Promise<PaginatedResponse<Prayer>> => {
    const response = await api.get<ApiResponse<PaginatedResponse<RawPrayer>>>('/prayers/favorites', {
      params: { page, limit },
    });
    return mapListData(response.data.data);
  },

  getById: async (id: string): Promise<Prayer> => {
    const response = await api.get<ApiResponse<RawPrayer>>(`/prayers/${id}`);
    return mapPrayer(response.data.data);
  },

  create: async (data: Partial<Prayer>): Promise<Prayer> => {
    const response = await api.post<ApiResponse<RawPrayer>>('/prayers', data);
    return mapPrayer(response.data.data);
  },

  update: async (id: string, data: Partial<Prayer>): Promise<Prayer> => {
    const response = await api.put<ApiResponse<RawPrayer>>(`/prayers/${id}`, data);
    return mapPrayer(response.data.data);
  },

  delete: async (id: string): Promise<void> => {
    await api.delete(`/prayers/${id}`);
  },

  markAnswered: async (id: string, answerDescription?: string): Promise<Prayer> => {
    const response = await api.post<ApiResponse<RawPrayer>>(`/prayers/${id}/answer`, { answerDescription });
    return mapPrayer(response.data.data);
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
