import { api } from './api';

export const prayersService = {
  list: (params?: { page?: number; limit?: number; categoryId?: string; isUrgent?: boolean }) =>
    api.get('/prayers', { params }),

  getMy: (page = 1, limit = 20) =>
    api.get('/prayers/my', { params: { page, limit } }),

  getUrgent: (page = 1, limit = 20) =>
    api.get('/prayers/urgent', { params: { page, limit } }),

  getFavorites: (page = 1, limit = 20) =>
    api.get('/prayers/favorites', { params: { page, limit } }),

  getById: (id: string) =>
    api.get(`/prayers/${id}`),

  create: (data: any) =>
    api.post('/prayers', data),

  update: (id: string, data: any) =>
    api.put(`/prayers/${id}`, data),

  delete: (id: string) =>
    api.delete(`/prayers/${id}`),

  markAnswered: (id: string) =>
    api.post(`/prayers/${id}/answer`),

  addComment: (id: string, content: string) =>
    api.post(`/prayers/${id}/comments`, { content }),

  toggleReaction: (id: string, type: string) =>
    api.post(`/prayers/${id}/react`, { type }),

  intercede: (id: string) =>
    api.post(`/prayers/${id}/intercede`),

  getIntercessors: (id: string) =>
    api.get(`/prayers/${id}/intercessors`),

  toggleFavorite: (id: string) =>
    api.post(`/prayers/${id}/favorite`),

  getCategories: () =>
    api.get('/prayers/categories'),
};
