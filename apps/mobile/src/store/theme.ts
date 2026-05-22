import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import * as SecureStore from 'expo-secure-store';
import { Platform } from 'react-native';

type ColorScheme = 'light' | 'dark' | 'system';

interface ThemeState {
  colorScheme: ColorScheme;
  isDark: boolean;
  setColorScheme: (scheme: ColorScheme) => void;
  toggleTheme: () => void;
}

const secureStorage = {
  getItem: async (name: string): Promise<string | null> => {
    if (Platform.OS === 'web') {
      return localStorage.getItem(name);
    }
    try {
      return await SecureStore.getItemAsync(name);
    } catch {
      return null;
    }
  },
  setItem: async (name: string, value: string): Promise<void> => {
    if (Platform.OS === 'web') {
      localStorage.setItem(name, value);
      return;
    }
    try {
      await SecureStore.setItemAsync(name, value);
    } catch {
      // storage unavailable
    }
  },
  removeItem: async (name: string): Promise<void> => {
    if (Platform.OS === 'web') {
      localStorage.removeItem(name);
      return;
    }
    try {
      await SecureStore.deleteItemAsync(name);
    } catch {
      // storage unavailable
    }
  },
};

function computeIsDark(scheme: ColorScheme): boolean {
  if (scheme === 'dark') return true;
  if (scheme === 'light') return false;
  return false;
}

export const useThemeStore = create<ThemeState>()(
  persist(
    (set, get) => ({
      colorScheme: 'system',
      isDark: false,
      setColorScheme: (scheme) => {
        set({ colorScheme: scheme, isDark: computeIsDark(scheme) });
      },
      toggleTheme: () => {
        const current = get().colorScheme;
        const order: ColorScheme[] = ['light', 'dark', 'system'];
        const nextIndex = (order.indexOf(current) + 1) % order.length;
        const next = order[nextIndex];
        set({ colorScheme: next, isDark: computeIsDark(next) });
      },
    }),
    {
      name: '@church_app_theme',
      storage: createJSONStorage(() => secureStorage),
    }
  )
);
