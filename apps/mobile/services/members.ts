import { api } from './api';

export const membersService = {
  list: (params?: { page?: number; limit?: number; name?: string; status?: string }) =>
    api.get('/members', { params }),

  search: (q: string, page = 1, limit = 20) =>
    api.get('/members/search', { params: { q, page, limit } }),

  getById: (id: string) =>
    api.get(`/members/${id}`),

  create: (data: any) =>
    api.post('/members', data),

  update: (id: string, data: any) =>
    api.put(`/members/${id}`, data),

  delete: (id: string) =>
    api.delete(`/members/${id}`),

  getAddress: (id: string) =>
    api.get(`/members/${id}/address`),

  updateAddress: (id: string, data: any) =>
    api.put(`/members/${id}/address`, data),

  getDocuments: (id: string) =>
    api.get(`/members/${id}/documents`),

  addDocument: (id: string, data: any) =>
    api.post(`/members/${id}/documents`, data),

  getFamily: (id: string) =>
    api.get(`/members/${id}/family`),

  addFamilyMember: (id: string, data: any) =>
    api.post(`/members/${id}/family`, data),

  getHistory: (id: string) =>
    api.get(`/members/${id}/history`),

  addHistory: (id: string, data: any) =>
    api.post(`/members/${id}/history`, data),

  getMe: () =>
    api.get('/members/me'),

  getAudit: (id: string) =>
    api.get(`/members/${id}/audit`),
};
