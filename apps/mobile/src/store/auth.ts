import { create } from 'zustand';
import axios from 'axios';
import type { User, LoginCredentials, RegisterData, UpdateProfileData } from '../types';
import { authService } from '../services';
import { API_URL } from '../services/api';
import {
  getAccessToken,
  getRefreshToken,
  getStoredUser,
  setAccessToken,
  setRefreshToken,
  setStoredUser,
  clearAll,
} from '../utils/storage';

interface AuthState {
  user: User | null;
  accessToken: string | null;
  refreshToken: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<void>;
  loginWithGoogle: (idToken: string) => Promise<void>;
  register: (data: RegisterData) => Promise<void>;
  logout: () => Promise<void>;
  loadStoredAuth: () => Promise<void>;
  refreshTokens: () => Promise<void>;
  updateProfile: (data: UpdateProfileData) => Promise<void>;
  hasRole: (roles: string[]) => boolean;
}

export const useAuthStore = create<AuthState>()((set, get) => ({
  user: null,
  accessToken: null,
  refreshToken: null,
  isAuthenticated: false,
  isLoading: true,

  login: async (email: string, password: string) => {
    const response = await authService.login({ email, password });
    const { user, accessToken, refreshToken } = response;
    await Promise.all([
      setAccessToken(accessToken),
      setRefreshToken(refreshToken),
      setStoredUser(user),
    ]);
    set({
      user,
      accessToken,
      refreshToken,
      isAuthenticated: true,
      isLoading: false,
    });
  },

  loginWithGoogle: async (idToken: string) => {
    const response = await authService.googleLogin(idToken);
    const { user, accessToken, refreshToken } = response;
    await Promise.all([
      setAccessToken(accessToken),
      setRefreshToken(refreshToken),
      setStoredUser(user),
    ]);
    set({
      user,
      accessToken,
      refreshToken,
      isAuthenticated: true,
      isLoading: false,
    });
  },

  register: async (data: RegisterData) => {
    const response = await authService.register(data);
    const { user, accessToken, refreshToken } = response;
    await Promise.all([
      setAccessToken(accessToken),
      setRefreshToken(refreshToken),
      setStoredUser(user),
    ]);
    set({
      user,
      accessToken,
      refreshToken,
      isAuthenticated: true,
      isLoading: false,
    });
  },

  logout: async () => {
    const token = await getAccessToken();
    
    if (token) {
      try {
        await axios.post(`${API_URL}/auth/logout`, {}, {
          headers: { Authorization: `Bearer ${token}` }
        });
      } catch {
      }
    }
    
    await clearAll();
    set({
      user: null,
      accessToken: null,
      refreshToken: null,
      isAuthenticated: false,
      isLoading: false,
    });
  },

  loadStoredAuth: async () => {
    try {
      const [accessToken, refreshToken, user] = await Promise.all([
        getAccessToken(),
        getRefreshToken(),
        getStoredUser(),
      ]);
      if (accessToken && refreshToken && user) {
        set({
          user,
          accessToken,
          refreshToken,
          isAuthenticated: true,
          isLoading: false,
        });
        return;
      }
    } catch {
      // stored data unavailable
    }
    set({ isLoading: false });
  },

  refreshTokens: async () => {
    try {
      const currentRefreshToken = get().refreshToken;
      if (!currentRefreshToken) {
        throw new Error('No refresh token available');
      }
      const tokens = await authService.refreshToken(currentRefreshToken);
      await Promise.all([
        setAccessToken(tokens.accessToken),
        setRefreshToken(tokens.refreshToken),
      ]);
      set({
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      });
    } catch {
      await clearAll();
      set({
        user: null,
        accessToken: null,
        refreshToken: null,
        isAuthenticated: false,
        isLoading: false,
      });
    }
  },

  updateProfile: async (data: UpdateProfileData) => {
    const updatedUser = await authService.updateProfile(data);
    await setStoredUser(updatedUser);
    set({ user: updatedUser });
  },

  hasRole: (roles: string[]) => {
    const { user } = get();
    if (!user) return false;
    return roles.includes(user.role);
  },
}));
