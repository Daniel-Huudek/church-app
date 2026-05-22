import React from 'react';
import { View, Text } from 'react-native';
import { useColorScheme } from '../../hooks/useColorScheme';

type DividerVariant = 'full' | 'inset' | 'middle';

export interface DividerProps {
  variant?: DividerVariant;
  label?: string;
  className?: string;
}

export function Divider({ variant = 'full', label, className = '' }: DividerProps) {
  const { isDark } = useColorScheme();

  const lineClass = `h-px flex-1 ${isDark ? 'bg-neutral-800' : 'bg-neutral-200'}`;

  const marginClass = variant === 'inset' ? 'ml-16' : variant === 'middle' ? 'mx-4' : '';

  if (label) {
    return (
      <View className={`flex-row items-center my-3 ${marginClass} ${className}`}>
        <View className={lineClass} />
        <Text
          className={`mx-3 text-xs font-medium ${
            isDark ? 'text-neutral-500' : 'text-neutral-400'
          }`}
        >
          {label}
        </Text>
        <View className={lineClass} />
      </View>
    );
  }

  return <View className={`${lineClass} my-3 ${marginClass} ${className}`} />;
}
