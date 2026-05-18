import React from 'react';
import { View, Text, TouchableOpacity } from 'react-native';
import { useColorScheme } from '../../hooks/useColorScheme';

type ChipVariant = 'filled' | 'outlined';
type ChipSize = 'sm' | 'md';

export interface ChipProps {
  label: string;
  variant?: ChipVariant;
  size?: ChipSize;
  selected?: boolean;
  onPress?: () => void;
  onClose?: () => void;
  icon?: React.ReactNode;
  avatar?: React.ReactNode;
  className?: string;
}

const sizeStyles: Record<ChipSize, { py: string; px: string; text: string }> = {
  sm: { py: 'py-1', px: 'px-2.5', text: 'text-xs' },
  md: { py: 'py-1.5', px: 'px-3', text: 'text-sm' },
};

export function Chip({
  label,
  variant = 'filled',
  size = 'md',
  selected = false,
  onPress,
  onClose,
  icon,
  avatar,
  className = '',
}: ChipProps) {
  const { isDark } = useColorScheme();
  const ss = sizeStyles[size];

  const isFilled = variant === 'filled';
  const isSelected = selected;

  const bgColor = isFilled
    ? isDark
      ? isSelected ? 'bg-purple-900/50' : 'bg-neutral-800'
      : isSelected ? 'bg-purple-100' : 'bg-neutral-100'
    : 'bg-transparent';

  const textColor = isFilled
    ? isDark
      ? isSelected ? 'text-purple-300' : 'text-neutral-200'
      : isSelected ? 'text-purple-700' : 'text-neutral-700'
    : isDark
    ? isSelected ? 'text-purple-300' : 'text-neutral-300'
    : isSelected ? 'text-purple-700' : 'text-neutral-600';

  const borderColor = isDark
    ? isSelected ? 'border-purple-600' : 'border-neutral-700'
    : isSelected ? 'border-purple-400' : 'border-neutral-300';

  const Container = onPress ? TouchableOpacity : View;

  return (
    <Container
      onPress={onPress}
      activeOpacity={0.7}
      className={`
        flex-row items-center rounded-full border ${borderColor}
        ${bgColor} ${ss.py} ${ss.px} ${className}
      `}
    >
      {avatar && <View className="mr-1.5">{avatar}</View>}
      {icon && !avatar && <View className="mr-1">{icon}</View>}
      <Text className={`font-medium ${ss.text} ${textColor}`}>{label}</Text>
      {onClose && (
        <TouchableOpacity
          onPress={onClose}
          className="ml-1.5"
          hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
        >
          <Text className={`${isDark ? 'text-neutral-400' : 'text-neutral-500'} text-xs`}>
            ✕
          </Text>
        </TouchableOpacity>
      )}
    </Container>
  );
}
