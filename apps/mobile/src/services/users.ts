import { api } from './api';

interface UserResponse {
  id: string;
  email: string;
  name: string;
  role: string;
  permissions?: string[];
  avatar?: string;
  createdAt: string;
}

interface ApiResponse<T> {
  success: boolean;
  data: T;
}

export const usersService = {
  getAll: async (): Promise<UserResponse[]> => {
    const response = await api.get<ApiResponse<UserResponse[]>>('/users');
    return response.data.data;
  },

  getById: async (id: string): Promise<UserResponse> => {
    const response = await api.get<ApiResponse<UserResponse>>(`/users/${id}`);
    return response.data.data;
  },

  updateRole: async (id: string, role: string): Promise<UserResponse> => {
    const response = await api.put<ApiResponse<UserResponse>>(`/users/${id}`, { role });
    return response.data.data;
  },

  updatePermissions: async (id: string, permissions: string[]): Promise<UserResponse> => {
    const response = await api.put<ApiResponse<UserResponse>>(`/users/${id}/permissions`, { permissions });
    return response.data.data;
  },
};