import type { Member, MemberFilter, MemberHistory, MemberDocument, MemberFamily, PaginatedResponse } from '../types/member';
import type { Address } from '../types/member';
import { api } from './api';

interface ApiResponse<T> {
  success: boolean;
  data: T;
}

export const memberKeys = {
  all: ['members'] as const,
  lists: () => [...memberKeys.all, 'list'] as const,
  list: (filters: MemberFilter) => [...memberKeys.lists(), filters] as const,
  details: () => [...memberKeys.all, 'detail'] as const,
  detail: (id: string) => [...memberKeys.details(), id] as const,
};

export const membersService = {
  list: async (filters?: MemberFilter): Promise<PaginatedResponse<Member>> => {
    const response = await api.get<ApiResponse<PaginatedResponse<Member>>>('/members', {
      params: filters,
    });
    return response.data.data;
  },

  search: async (q: string, page = 1, limit = 20): Promise<PaginatedResponse<Member>> => {
    const response = await api.get<ApiResponse<PaginatedResponse<Member>>>('/members/search', {
      params: { q, page, limit },
    });
    return response.data.data;
  },

  getById: async (id: string): Promise<Member> => {
    const response = await api.get<ApiResponse<Member>>(`/members/${id}`);
    return response.data.data;
  },

  create: async (data: Partial<Member>): Promise<Member> => {
    const response = await api.post<ApiResponse<Member>>('/members', data);
    return response.data.data;
  },

  update: async (id: string, data: Partial<Member>): Promise<Member> => {
    const response = await api.put<ApiResponse<Member>>(`/members/${id}`, data);
    return response.data.data;
  },

  delete: async (id: string): Promise<void> => {
    await api.delete(`/members/${id}`);
  },

  getMe: async (): Promise<Member> => {
    const response = await api.get<ApiResponse<Member>>('/members/me');
    return response.data.data;
  },

  getAddress: async (id: string): Promise<Address> => {
    const response = await api.get<ApiResponse<Address>>(`/members/${id}/address`);
    return response.data.data;
  },

  updateAddress: async (id: string, data: Partial<Address>): Promise<Address> => {
    const response = await api.put<ApiResponse<Address>>(`/members/${id}/address`, data);
    return response.data.data;
  },

  getHistory: async (id: string, page = 1, limit = 20): Promise<PaginatedResponse<MemberHistory>> => {
    const response = await api.get<ApiResponse<PaginatedResponse<MemberHistory>>>(
      `/members/${id}/history`,
      { params: { page, limit } }
    );
    return response.data.data;
  },

  addHistory: async (id: string, data: { action: string; description: string }): Promise<MemberHistory> => {
    const response = await api.post<ApiResponse<MemberHistory>>(`/members/${id}/history`, data);
    return response.data.data;
  },

  getDocuments: async (id: string): Promise<MemberDocument[]> => {
    const response = await api.get<ApiResponse<MemberDocument[]>>(`/members/${id}/documents`);
    return response.data.data;
  },

  addDocument: async (id: string, data: FormData): Promise<MemberDocument> => {
    const response = await api.post<ApiResponse<MemberDocument>>(`/members/${id}/documents`, data, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
    return response.data.data;
  },

  deleteDocument: async (memberId: string, documentId: string): Promise<void> => {
    await api.delete(`/members/${memberId}/documents/${documentId}`);
  },

  getFamily: async (id: string): Promise<MemberFamily[]> => {
    const response = await api.get<ApiResponse<MemberFamily[]>>(`/members/${id}/family`);
    return response.data.data;
  },

  addFamilyMember: async (id: string, data: Partial<MemberFamily>): Promise<MemberFamily> => {
    const response = await api.post<ApiResponse<MemberFamily>>(`/members/${id}/family`, data);
    return response.data.data;
  },

  removeFamilyMember: async (memberId: string, familyId: string): Promise<void> => {
    await api.delete(`/members/${memberId}/family/${familyId}`);
  },

  updateStatus: async (id: string, status: string): Promise<Member> => {
    const response = await api.put<ApiResponse<Member>>(`/members/${id}/status`, { status });
    return response.data.data;
  },

  getAudit: async (id: string, page = 1, limit = 20): Promise<PaginatedResponse<{ action: string; description: string; authorName: string; createdAt: string }>> => {
    const response = await api.get<ApiResponse<PaginatedResponse<{ action: string; description: string; authorName: string; createdAt: string }>>>(
      `/members/${id}/audit`,
      { params: { page, limit } }
    );
    return response.data.data;
  },
};
