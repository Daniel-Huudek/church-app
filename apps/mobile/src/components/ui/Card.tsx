import React from 'react';
import { View, TouchableOpacity, ViewStyle } from 'react-native';
import { useColorScheme } from '../../hooks/useColorScheme';

type CardVariant = 'elevated' | 'outlined' | 'filled';

export interface CardProps {
  variant?: CardVariant;
  padding?: 'none' | 'sm' | 'md' | 'lg';
  header?: React.ReactNode;
  footer?: React.ReactNode;
  onPress?: () => void;
  children: React.ReactNode;
  className?: string;
  style?: ViewStyle;
}

const paddingMap = {
  none: '',
  sm: 'p-3',
  md: 'p-4',
  lg: 'p-6',
};

export function Card({
  variant = 'elevated',
  padding = 'md',
  header,
  footer,
  onPress,
  children,
  className = '',
  style,
}: CardProps) {
  const { isDark } = useColorScheme();

  const variantStyles: Record<CardVariant, string> = {
    elevated: `
      ${isDark ? 'bg-[#1A1A2E]' : 'bg-white'}
      ${isDark ? 'shadow-lg shadow-black/30' : 'shadow-lg shadow-black/10'}
    `,
    outlined: `
      ${isDark ? 'bg-transparent' : 'bg-white'}
      border ${isDark ? 'border-neutral-700' : 'border-neutral-200'}
    `,
    filled: `
      ${isDark ? 'bg-[#12121A]' : 'bg-neutral-50'}
    `,
  };

  const Container = onPress ? TouchableOpacity : View;

  return (
    <Container
      onPress={onPress}
      activeOpacity={onPress ? 0.7 : 1}
      style={style}
      className={`
        rounded-2xl
        ${variantStyles[variant]}
        ${paddingMap[padding]}
        ${className}
      `}
    >
      {header && (
        <View className={`mb-3 pb-3 border-b ${isDark ? 'border-neutral-700' : 'border-neutral-200'}`}>
          {header}
        </View>
      )}
      {children}
      {footer && (
        <View className={`mt-3 pt-3 border-t ${isDark ? 'border-neutral-700' : 'border-neutral-200'}`}>
          {footer}
        </View>
      )}
    </Container>
  );
}
