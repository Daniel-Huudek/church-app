import React from 'react';
import { View, Text } from 'react-native';

type BadgeVariant = 'primary' | 'success' | 'warning' | 'error' | 'info';
type BadgePosition = 'top-right' | 'top-left' | 'bottom-right' | 'bottom-left';

export interface BadgeProps {
  variant?: BadgeVariant;
  count?: number;
  dot?: boolean;
  position?: BadgePosition;
  className?: string;
  children?: React.ReactNode;
}

const variantStyles: Record<BadgeVariant, { bg: string; text: string }> = {
  primary: { bg: 'bg-purple-600', text: 'text-white' },
  success: { bg: 'bg-green-500', text: 'text-white' },
  warning: { bg: 'bg-amber-500', text: 'text-white' },
  error: { bg: 'bg-red-500', text: 'text-white' },
  info: { bg: 'bg-blue-500', text: 'text-white' },
};

const positionStyles: Record<BadgePosition, string> = {
  'top-right': 'absolute -top-1 -right-1',
  'top-left': 'absolute -top-1 -left-1',
  'bottom-right': 'absolute -bottom-1 -right-1',
  'bottom-left': 'absolute -bottom-1 -left-1',
};

export function Badge({
  variant = 'primary',
  count,
  dot = false,
  position = 'top-right',
  className = '',
  children,
}: BadgeProps) {
  const vs = variantStyles[variant];

  if (dot) {
    return (
      <View
        className={`rounded-full ${vs.bg} ${positionStyles[position]} ${className}`}
        style={{ width: 8, height: 8 }}
      />
    );
  }

  if (count !== undefined) {
    return (
      <View
        className={`
          min-w-[20px] h-5 rounded-full px-1.5 items-center justify-center
          ${vs.bg} ${positionStyles[position]} ${className}
        `}
      >
        <Text className={`text-xs font-bold ${vs.text}`}>
          {count > 99 ? '99+' : count}
        </Text>
      </View>
    );
  }

  return (
    <View
      className={`
        rounded-full px-2.5 py-0.5 ${vs.bg} ${className}
      `}
    >
      <Text className={`text-xs font-semibold ${vs.text}`}>{children}</Text>
    </View>
  );
}
