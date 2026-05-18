import React from 'react';
import { View, Text, ActivityIndicator, Modal } from 'react-native';
import { useColorScheme } from '../../hooks/useColorScheme';

export interface LoadingProps {
  visible?: boolean;
  fullScreen?: boolean;
  message?: string;
  size?: 'small' | 'large';
  color?: string;
  className?: string;
}

export function Loading({
  visible = true,
  fullScreen = false,
  message,
  size = 'large',
  color,
  className = '',
}: LoadingProps) {
  const { isDark } = useColorScheme();
  const spinnerColor = color || (isDark ? '#A78BFA' : '#7C3AED');

  if (!visible) return null;

  if (fullScreen) {
    return (
      <Modal transparent animationType="fade" visible={visible}>
        <View className="flex-1 items-center justify-center bg-black/50">
          <View
            className={`
              items-center justify-center px-8 py-8 rounded-3xl
              ${isDark ? 'bg-[#1A1A2E]' : 'bg-white'}
            `}
          >
            <ActivityIndicator size={size} color={spinnerColor} />
            {message && (
              <Text
                className={`mt-4 text-sm font-medium ${
                  isDark ? 'text-neutral-300' : 'text-neutral-600'
                }`}
              >
                {message}
              </Text>
            )}
          </View>
        </View>
      </Modal>
    );
  }

  return (
    <View className={`flex-row items-center justify-center py-4 ${className}`}>
      <ActivityIndicator size={size} color={spinnerColor} />
      {message && (
        <Text
          className={`ml-3 text-sm font-medium ${
            isDark ? 'text-neutral-300' : 'text-neutral-600'
          }`}
        >
          {message}
        </Text>
      )}
    </View>
  );
}
