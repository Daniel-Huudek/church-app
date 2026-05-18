import { useCallback } from 'react';
import { useAuthStore } from '../store';
import type { RegisterData, UpdateProfileData } from '../types';

export function useAuth() {
  const user = useAuthStore((s) => s.user);
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
  const isLoading = useAuthStore((s) => s.isLoading);
  const accessToken = useAuthStore((s) => s.accessToken);
  const refreshToken = useAuthStore((s) => s.refreshToken);

  const login = useCallback(
    (email: string, password: string) => useAuthStore.getState().login(email, password),
    []
  );

  const loginWithGoogle = useCallback(
    (idToken: string) => useAuthStore.getState().loginWithGoogle(idToken),
    []
  );

  const register = useCallback(
    (data: RegisterData) => useAuthStore.getState().register(data),
    []
  );

  const logout = useCallback(
    () => useAuthStore.getState().logout(),
    []
  );

  const updateProfile = useCallback(
    (data: UpdateProfileData) => useAuthStore.getState().updateProfile(data),
    []
  );

  const hasRole = useCallback(
    (roles: string[]) => useAuthStore.getState().hasRole(roles),
    []
  );

  return {
    user,
    isAuthenticated,
    isLoading,
    accessToken,
    refreshToken,
    login,
    loginWithGoogle,
    register,
    logout,
    updateProfile,
    hasRole,
    isAdmin: user?.role === 'ADMINISTRADOR',
    isPastor: user?.role === 'PASTOR',
    isFinanceiro: user?.role === 'FINANCEIRO',
    isMembro: user?.role === 'MEMBRO',
    isVisitante: user?.role === 'VISITANTE',
  };
}
