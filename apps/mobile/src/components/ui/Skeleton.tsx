import React, { useEffect } from 'react';
import { View } from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withRepeat,
  withTiming,
  interpolate,
  Easing,
} from 'react-native-reanimated';
import { useColorScheme } from '../../hooks/useColorScheme';

type SkeletonVariant = 'text' | 'circular' | 'rectangular' | 'card';

export interface SkeletonProps {
  variant?: SkeletonVariant;
  width?: number | string;
  height?: number;
  className?: string;
}

export function Skeleton({
  variant = 'text',
  width,
  height,
  className = '',
}: SkeletonProps) {
  const { isDark } = useColorScheme();
  const shimmer = useSharedValue(0);

  useEffect(() => {
    shimmer.value = withRepeat(
      withTiming(1, { duration: 1500, easing: Easing.ease }),
      -1,
      true
    );
  }, [shimmer]);

  const animatedStyle = useAnimatedStyle(() => ({
    opacity: interpolate(shimmer.value, [0, 0.5, 1], [0.3, 0.5, 0.3]),
  }));

  const variantStyle = (): { w: number | string; h: number; rounded: string } => {
    switch (variant) {
      case 'text':
        return { w: width || '100%', h: height || 14, rounded: 'rounded-md' };
      case 'circular':
        return { w: width || 40, h: height || 40, rounded: 'rounded-full' };
      case 'rectangular':
        return { w: width || '100%', h: height || 120, rounded: 'rounded-xl' };
      case 'card':
        return { w: width || '100%', h: height || 200, rounded: 'rounded-2xl' };
    }
  };

  const vs = variantStyle();

  return (
    <Animated.View
      style={[{ width: vs.w, height: vs.h }, animatedStyle]}
      className={`
        ${vs.rounded}
        ${isDark ? 'bg-neutral-800' : 'bg-neutral-200'}
        ${className}
      `}
    />
  );
}
