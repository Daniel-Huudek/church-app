import * as SecureStore from 'expo-secure-store';
import { Platform } from 'react-native';
import type { User } from '../types/auth';

const TOKEN_KEYS = {
  ACCESS: '@church_app_access_token',
  REFRESH: '@church_app_refresh_token',
  USER: '@church_app_user',
} as const;

function isSecureStoreAvailable(): boolean {
  if (Platform.OS === 'web') return false;
  try {
    return SecureStore.isAvailableAsync ? true : false;
  } catch {
    return false;
  }
}

const webStorageFallback = {
  getItem: (key: string): string | null => {
    try {
      return localStorage.getItem(key);
    } catch {
      return null;
    }
  },
  setItem: (key: string, value: string): void => {
    try {
      localStorage.setItem(key, value);
    } catch {
      // Storage full or unavailable
    }
  },
  removeItem: (key: string): void => {
    try {
      localStorage.removeItem(key);
    } catch {
      // Storage unavailable
    }
  },
};

async function getItem(key: string): Promise<string | null> {
  if (isSecureStoreAvailable()) {
    try {
      return await SecureStore.getItemAsync(key);
    } catch {
      return null;
    }
  }
  return webStorageFallback.getItem(key);
}

async function setItem(key: string, value: string): Promise<void> {
  if (isSecureStoreAvailable()) {
    try {
      await SecureStore.setItemAsync(key, value);
    } catch {
      // Fallback to web storage
      webStorageFallback.setItem(key, value);
    }
  } else {
    webStorageFallback.setItem(key, value);
  }
}

async function removeItem(key: string): Promise<void> {
  if (isSecureStoreAvailable()) {
    try {
      await SecureStore.deleteItemAsync(key);
    } catch {
      webStorageFallback.removeItem(key);
    }
  } else {
    webStorageFallback.removeItem(key);
  }
}

export async function getAccessToken(): Promise<string | null> {
  return getItem(TOKEN_KEYS.ACCESS);
}

export async function setAccessToken(token: string): Promise<void> {
  return setItem(TOKEN_KEYS.ACCESS, token);
}

export async function getRefreshToken(): Promise<string | null> {
  return getItem(TOKEN_KEYS.REFRESH);
}

export async function setRefreshToken(token: string): Promise<void> {
  return setItem(TOKEN_KEYS.REFRESH, token);
}

export async function getStoredUser(): Promise<User | null> {
  const data = await getItem(TOKEN_KEYS.USER);
  if (!data) return null;
  try {
    return JSON.parse(data) as User;
  } catch {
    return null;
  }
}

export async function setStoredUser(user: User): Promise<void> {
  return setItem(TOKEN_KEYS.USER, JSON.stringify(user));
}

export async function clearUser(): Promise<void> {
  return removeItem(TOKEN_KEYS.USER);
}

export async function clearTokens(): Promise<void> {
  await Promise.all([
    removeItem(TOKEN_KEYS.ACCESS),
    removeItem(TOKEN_KEYS.REFRESH),
  ]);
}

export async function clearAll(): Promise<void> {
  await Promise.all([
    removeItem(TOKEN_KEYS.ACCESS),
    removeItem(TOKEN_KEYS.REFRESH),
    removeItem(TOKEN_KEYS.USER),
  ]);
}

const FAB_POSITION_KEY = '@church_app_fab_position';

export async function getFabPosition(): Promise<{ x: number; y: number } | null> {
  const data = await getItem(FAB_POSITION_KEY);
  if (!data) return null;
  try {
    return JSON.parse(data);
  } catch {
    return null;
  }
}

export async function setFabPosition(position: { x: number; y: number }): Promise<void> {
  return setItem(FAB_POSITION_KEY, JSON.stringify(position));
}
