import React from 'react';
import { View, Text } from 'react-native';
import { useColorScheme } from '../../hooks/useColorScheme';
import { Button } from './Button';

export interface EmptyStateProps {
  icon?: React.ReactNode;
  title: string;
  subtitle?: string;
  actionLabel?: string;
  onAction?: () => void;
  className?: string;
}

export function EmptyState({
  icon,
  title,
  subtitle,
  actionLabel,
  onAction,
  className = '',
}: EmptyStateProps) {
  const { isDark } = useColorScheme();

  return (
    <View className={`flex-1 items-center justify-center px-8 py-12 ${className}`}>
      {icon ? (
        <View className="mb-5 opacity-60">{icon}</View>
      ) : (
        <View
          className={`w-20 h-20 rounded-full items-center justify-center mb-5 ${
            isDark ? 'bg-neutral-800' : 'bg-neutral-100'
          }`}
        >
          <Text className="text-3xl">📭</Text>
        </View>
      )}
      <Text
        className={`text-xl font-bold text-center mb-2 ${
          isDark ? 'text-neutral-100' : 'text-neutral-900'
        }`}
      >
        {title}
      </Text>
      {subtitle && (
        <Text
          className={`text-sm text-center leading-5 mb-6 max-w-xs ${
            isDark ? 'text-neutral-400' : 'text-neutral-500'
          }`}
        >
          {subtitle}
        </Text>
      )}
      {actionLabel && onAction && (
        <Button variant="primary" size="md" onPress={onAction}>
          {actionLabel}
        </Button>
      )}
    </View>
  );
}
