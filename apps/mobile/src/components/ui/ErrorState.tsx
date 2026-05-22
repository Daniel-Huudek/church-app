import React from 'react';
import { View, Text } from 'react-native';
import { useColorScheme } from '../../hooks/useColorScheme';
import { Button } from './Button';

export interface ErrorStateProps {
  icon?: React.ReactNode;
  title?: string;
  message?: string;
  retryLabel?: string;
  onRetry?: () => void;
  className?: string;
}

export function ErrorState({
  icon,
  title = 'Something went wrong',
  message,
  retryLabel = 'Try Again',
  onRetry,
  className = '',
}: ErrorStateProps) {
  const { isDark } = useColorScheme();

  return (
    <View className={`flex-1 items-center justify-center px-8 py-12 ${className}`}>
      {icon ? (
        <View className="mb-5">{icon}</View>
      ) : (
        <View
          className={`w-20 h-20 rounded-full items-center justify-center mb-5 ${
            isDark ? 'bg-red-900/30' : 'bg-red-50'
          }`}
        >
          <Text className="text-3xl">⚠️</Text>
        </View>
      )}
      <Text
        className={`text-xl font-bold text-center mb-2 ${
          isDark ? 'text-neutral-100' : 'text-neutral-900'
        }`}
      >
        {title}
      </Text>
      {message && (
        <Text
          className={`text-sm text-center leading-5 mb-6 max-w-xs ${
            isDark ? 'text-neutral-400' : 'text-neutral-500'
          }`}
        >
          {message}
        </Text>
      )}
      {onRetry && (
        <Button variant="primary" size="md" onPress={onRetry}>
          {retryLabel}
        </Button>
      )}
    </View>
  );
}
