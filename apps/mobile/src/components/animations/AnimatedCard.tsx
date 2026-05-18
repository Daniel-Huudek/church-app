import React, { useCallback } from 'react';
import { TouchableOpacity, ViewStyle } from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  interpolate,
} from 'react-native-reanimated';

export interface AnimatedCardProps {
  children: React.ReactNode;
  onPress?: () => void;
  scaleTo?: number;
  liftAmount?: number;
  className?: string;
  style?: ViewStyle;
  disabled?: boolean;
}

export function AnimatedCard({
  children,
  onPress,
  scaleTo = 0.97,
  liftAmount = 4,
  className = '',
  style,
  disabled = false,
}: AnimatedCardProps) {
  const pressProgress = useSharedValue(0);

  const handlePressIn = useCallback(() => {
    pressProgress.value = withSpring(1, { damping: 18, stiffness: 250 });
  }, [pressProgress]);

  const handlePressOut = useCallback(() => {
    pressProgress.value = withSpring(0, { damping: 18, stiffness: 250 });
  }, [pressProgress]);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [
      { scale: interpolate(pressProgress.value, [0, 1], [1, scaleTo]) },
      {
        translateY: interpolate(pressProgress.value, [0, 1], [0, -liftAmount]),
      },
    ],
  }));

  if (!onPress) {
    return (
      <Animated.View style={[animatedStyle, style]} className={className}>
        {children}
      </Animated.View>
    );
  }

  return (
    <Animated.View style={[animatedStyle, style]} className={className}>
      <TouchableOpacity
        onPress={onPress}
        onPressIn={handlePressIn}
        onPressOut={handlePressOut}
        activeOpacity={1}
        disabled={disabled}
      >
        {children}
      </TouchableOpacity>
    </Animated.View>
  );
}
