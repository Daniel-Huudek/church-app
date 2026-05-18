import { create } from 'zustand';

interface AuthState {
  user: any | null;
  accessToken: string | null;
  refreshToken: string | null;
  isAuthenticated: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  setTokens: (access: string, refresh: string) => void;
  hasRole: (roles: string[]) => boolean;
}

export const useAuthStore = create<AuthState>((set, get) => ({
  user: null,
  accessToken: null,
  refreshToken: null,
  isAuthenticated: false,

  login: async (email: string, password: string) => {
    const { api } = await import('../services/api');
    const response = await api.post('/auth/login', { email, password });
    const { accessToken, refreshToken, user } = response.data.data;
    set({ user, accessToken, refreshToken, isAuthenticated: true });
  },

  logout: () => {
    set({ user: null, accessToken: null, refreshToken: null, isAuthenticated: false });
  },

  setTokens: (access: string, refresh: string) => {
    set({ accessToken: access, refreshToken: refresh });
  },

  hasRole: (roles: string[]) => {
    const { user } = get();
    return user ? roles.includes(user.role) : false;
  },
}));