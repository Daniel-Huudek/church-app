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
type SnackbarType = 'default' | 'success' | 'error';

interface SnackbarData {
  id: string;
  message: string;
  type?: SnackbarType;
  duration?: number;
  actionLabel?: string;
  onAction?: () => void;
}

export interface SnackbarProps {
  snackbar: SnackbarData;
  onDismiss: (id: string) => void;
}

const typeStyles: Record<SnackbarType, { bg: string; text: string }> = {
  default: { bg: 'bg-neutral-800', text: 'text-white' },
  success: { bg: 'bg-green-600', text: 'text-white' },
  error: { bg: 'bg-red-600', text: 'text-white' },
};

export function Snackbar({ snackbar, onDismiss }: SnackbarProps) {
  const translateY = useSharedValue(100);
  const opacity = useSharedValue(0);

  const ts = typeStyles[snackbar.type || 'default'];

  const dismiss = useCallback(() => {
    onDismiss(snackbar.id);
  }, [onDismiss, snackbar.id]);

  useEffect(() => {
    translateY.value = withTiming(0, {
      duration: 400,
      easing: Easing.out(Easing.cubic),
    });
    opacity.value = withTiming(1, { duration: 300 });

    const dur = snackbar.duration || 4000;
    const timeout = setTimeout(() => {
      translateY.value = withTiming(100, { duration: 300 }, () => {
        runOnJS(dismiss)();
      });
      opacity.value = withTiming(0, { duration: 250 });
    }, dur);

    return () => clearTimeout(timeout);
  }, [translateY, opacity, snackbar.duration, dismiss]);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ translateY: translateY.value }],
    opacity: opacity.value,
  }));

  return (
    <Animated.View
      style={animatedStyle}
      className="absolute bottom-8 left-4 right-4 z-50"
    >
      <TouchableOpacity
        activeOpacity={0.95}
        className={`
          flex-row items-center px-4 py-3.5 rounded-2xl shadow-xl
          ${ts.bg}
        `}
      >
        <Text className={`text-sm font-medium flex-1 ${ts.text}`}>
          {snackbar.message}
        </Text>
        {snackbar.actionLabel && (
          <TouchableOpacity
            onPress={snackbar.onAction}
            className="ml-3"
          >
            <Text className="text-white font-semibold text-sm">
              {snackbar.actionLabel}
            </Text>
          </TouchableOpacity>
        )}
      </TouchableOpacity>
    </Animated.View>
  );
}
