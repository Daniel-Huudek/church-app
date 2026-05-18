import { useEffect, useState, useCallback } from 'react';
import { Appearance } from 'react-native';
import { useThemeStore } from '../store';
import { colors as themeColors } from '../theme';

export function useColorScheme() {
  const colorScheme = useThemeStore((s) => s.colorScheme);
  const setColorScheme = useThemeStore((s) => s.setColorScheme);

  const [isDark, setIsDark] = useState(() => {
    if (colorScheme === 'dark') return true;
    if (colorScheme === 'light') return false;
    return Appearance.getColorScheme() === 'dark';
  });

  useEffect(() => {
    if (colorScheme !== 'system') {
      setIsDark(colorScheme === 'dark');
      return;
    }

    const update = (appearanceScheme: 'light' | 'dark' | null | undefined) => {
      setIsDark(appearanceScheme === 'dark');
    };

    update(Appearance.getColorScheme());

    const subscription = Appearance.addChangeListener(({ colorScheme: cs }) => {
      update(cs);
    });

    return () => subscription.remove();
  }, [colorScheme]);

  const colors = isDark ? themeColors.dark : themeColors.light;

  const toggleTheme = useCallback(() => {
    useThemeStore.getState().toggleTheme();
  }, []);

  return {
    isDark,
    colors,
    colorScheme,
    setColorScheme,
    toggleTheme,
  };
}
