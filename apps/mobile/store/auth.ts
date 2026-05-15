import { create } from 'zustand';
import { api } from '../services/api';

interface User { id: string; email: string; name: string; avatar?: string; role: string; }
interface AuthState { user: User | null; token: string | null; login: (email: string, password: string) => Promise<void>; logout: () => void; }

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  token: null,
  login: async (email, password) => {
    const response = await api.post('/auth/login', { email, password });
    const { accessToken, user } = response.data.data;
    set({ token: accessToken, user });
  },
  logout: () => set({ token: null, user: null }),
}));