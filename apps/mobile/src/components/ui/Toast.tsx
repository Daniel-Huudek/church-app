import React, { useEffect, useCallback } from 'react';
import { Text, TouchableOpacity } from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withTiming,
  withDelay,
  runOnJS,
  Easing,
} from 'react-native-reanimated';
type ToastType = 'success' | 'error' | 'warning' | 'info';
type ToastPosition = 'top' | 'bottom';

interface ToastData {
  id: string;
  message: string;
  type?: ToastType;
  duration?: number;
  position?: ToastPosition;
}

export interface ToastProps {
  toast: ToastData;
  onDismiss: (id: string) => void;
}

const typeConfig: Record<ToastType, { icon: string; bg: string }> = {
  success: { icon: '✅', bg: 'bg-green-600' },
  error: { icon: '❌', bg: 'bg-red-600' },
  warning: { icon: '⚠️', bg: 'bg-amber-500' },
  info: { icon: 'ℹ️', bg: 'bg-blue-600' },
};

export function Toast({ toast, onDismiss }: ToastProps) {
  const translateY = useSharedValue(toast.position === 'bottom' ? 100 : -100);
  const opacity = useSharedValue(0);

  const config = typeConfig[toast.type || 'info'];
  const pos = toast.position || 'top';

  const dismiss = useCallback(() => {
    onDismiss(toast.id);
  }, [onDismiss, toast.id]);

  useEffect(() => {
    translateY.value = withTiming(0, {
      duration: 400,
      easing: Easing.out(Easing.cubic),
    });
    opacity.value = withTiming(1, { duration: 300 });

    const dur = toast.duration || 3000;
    const timeout = setTimeout(() => {
      translateY.value = withTiming(pos === 'bottom' ? 100 : -100, {
        duration: 300,
        easing: Easing.in(Easing.cubic),
      });
      opacity.value = withTiming(0, { duration: 250 }, () => {
        runOnJS(dismiss)();
      });
    }, dur);

    return () => clearTimeout(timeout);
  }, [translateY, opacity, pos, toast.duration, dismiss]);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ translateY: translateY.value }],
    opacity: opacity.value,
  }));

  return (
    <Animated.View
      style={animatedStyle}
      className={`
        absolute left-4 right-4 z-50
        ${pos === 'top' ? 'top-12' : 'bottom-12'}
      `}
    >
      <TouchableOpacity
        activeOpacity={0.9}
        onPress={dismiss}
        className={`
          flex-row items-center px-4 py-3.5 rounded-2xl shadow-xl
          ${config.bg}
        `}
      >
        <Text className="text-lg mr-2.5">{config.icon}</Text>
        <Text className="text-white text-sm font-medium flex-1">{toast.message}</Text>
        <Text className="text-white/70 text-xs ml-2">✕</Text>
      </TouchableOpacity>
    </Animated.View>
  );
}
