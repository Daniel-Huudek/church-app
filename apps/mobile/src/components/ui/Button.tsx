import React, { useCallback } from 'react';
import {
  TouchableOpacity,
  Text,
  ActivityIndicator,
  View,
  Platform,
} from 'react-native';
import Animated, {
  useAnimatedStyle,
  withSpring,
  useSharedValue,
  withTiming,
} from 'react-native-reanimated';
import { useColorScheme } from '../../hooks/useColorScheme';

type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'danger' | 'success';
type ButtonSize = 'sm' | 'md' | 'lg';

export interface ButtonProps {
  variant?: ButtonVariant;
  size?: ButtonSize;
  fullWidth?: boolean;
  loading?: boolean;
  disabled?: boolean;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
  onPress?: () => void;
  children: React.ReactNode;
  className?: string;
  haptic?: boolean;
}

const sizeConfig: Record<ButtonSize, { py: string; px: string; text: string; icon: string }> = {
  sm: { py: 'py-2', px: 'px-4', text: 'text-sm', icon: 'text-sm' },
  md: { py: 'py-3', px: 'px-6', text: 'text-base', icon: 'text-base' },
  lg: { py: 'py-4', px: 'px-8', text: 'text-lg', icon: 'text-lg' },
};

export function Button({
  variant = 'primary',
  size = 'md',
  fullWidth = false,
  loading = false,
  disabled = false,
  leftIcon,
  rightIcon,
  onPress,
  children,
  className = '',
  haptic = false,
}: ButtonProps) {
  const { isDark } = useColorScheme();
  const scale = useSharedValue(1);
  const opacity = useSharedValue(1);

  const variantStyles: Record<ButtonVariant, { bg: string; text: string; border: string }> = {
    primary: {
      bg: 'bg-purple-600',
      text: 'text-white',
      border: 'border-purple-600',
    },
    secondary: {
      bg: isDark ? 'bg-neutral-800' : 'bg-neutral-100',
      text: isDark ? 'text-neutral-100' : 'text-neutral-900',
      border: isDark ? 'border-neutral-700' : 'border-neutral-300',
    },
    ghost: {
      bg: 'bg-transparent',
      text: isDark ? 'text-purple-400' : 'text-purple-600',
      border: 'border-transparent',
    },
    danger: {
      bg: 'bg-red-600',
      text: 'text-white',
      border: 'border-red-600',
    },
    success: {
      bg: 'bg-green-600',
      text: 'text-white',
      border: 'border-green-600',
    },
  };

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
    opacity: opacity.value,
  }));

  const handlePressIn = useCallback(() => {
    scale.value = withSpring(0.96, { damping: 15, stiffness: 300 });
    if (haptic && Platform.OS !== 'web') {
      try {
        const Haptics = require('expo-haptics');
        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      } catch {}
    }
  }, [haptic, scale]);

  const handlePressOut = useCallback(() => {
    scale.value = withSpring(1, { damping: 15, stiffness: 300 });
  }, [scale]);

  const vs = variantStyles[variant];
  const sc = sizeConfig[size];

  const isDisabled = disabled || loading;

  return (
    <Animated.View style={animatedStyle} className={fullWidth ? 'w-full' : ''}>
      <TouchableOpacity
        onPress={onPress}
        onPressIn={handlePressIn}
        onPressOut={handlePressOut}
        disabled={isDisabled}
        activeOpacity={0.8}
        className={`
          flex-row items-center justify-center rounded-full border
          ${vs.bg} ${vs.border} ${sc.py} ${sc.px}
          ${fullWidth ? 'w-full' : ''}
          ${isDisabled ? 'opacity-50' : ''}
          ${className}
        `}
      >
        {loading ? (
          <ActivityIndicator
            size="small"
            color={variant === 'primary' || variant === 'danger' || variant === 'success' ? '#FFFFFF' : isDark ? '#A78BFA' : '#7C3AED'}
          />
        ) : (
          <>
            {leftIcon && <View className="mr-2">{leftIcon}</View>}
            <Text
              className={`font-semibold ${sc.text} ${vs.text}`}
              style={{ letterSpacing: 0.3 }}
            >
              {children}
            </Text>
            {rightIcon && <View className="ml-2">{rightIcon}</View>}
          </>
        )}
      </TouchableOpacity>
    </Animated.View>
  );
}
