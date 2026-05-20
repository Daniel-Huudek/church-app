import { Stack } from 'expo-router';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useState, createContext, useContext } from 'react';
import { StatusBar } from 'expo-status-bar';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { GoogleSignin } from '@react-native-google-signin/google-signin';
import Constants from 'expo-constants';
import { useColorScheme } from '../src/hooks';

const extra = Constants.expoConfig?.extra;
GoogleSignin.configure({
  webClientId: extra?.googleClientId,
  androidClientId: extra?.googleAndroidClientId || extra?.googleClientId,
  iosClientId: extra?.googleIosClientId || extra?.googleClientId,
});

interface ThemeContextType {
  isDark: boolean;
  colors: ReturnType<typeof useColorScheme>['colors'];
}

const ThemeContext = createContext<ThemeContextType>({
  isDark: false,
  colors: {} as ReturnType<typeof useColorScheme>['colors'],
});

export const useTheme = () => useContext(ThemeContext);

function ThemeProvider({ children }: { children: React.ReactNode }) {
  const { isDark, colors } = useColorScheme();

  return (
    <ThemeContext.Provider value={{ isDark, colors }}>
      <StatusBar style={isDark ? 'light' : 'dark'} />
      {children}
    </ThemeContext.Provider>
  );
}

export default function RootLayout() {
  const [queryClient] = useState(() => new QueryClient());

  return (
    <QueryClientProvider client={queryClient}>
      <GestureHandlerRootView style={{ flex: 1 }}>
        <SafeAreaProvider>
          <ThemeProvider>
            <Stack screenOptions={{ headerShown: false }}>
              <Stack.Screen name="index" />
              <Stack.Screen name="(auth)" />
              <Stack.Screen name="(app)" />
            </Stack>
          </ThemeProvider>
        </SafeAreaProvider>
      </GestureHandlerRootView>
    </QueryClientProvider>
  );
}
