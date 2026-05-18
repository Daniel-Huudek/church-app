import React, { useEffect } from 'react';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withTiming,
  withDelay,
  Easing,
} from 'react-native-reanimated';

export interface SlideUpProps {
  children: React.ReactNode;
  distance?: number;
  duration?: number;
  delay?: number;
  className?: string;
}

export function SlideUp({
  children,
  distance = 40,
  duration = 500,
  delay = 0,
  className = '',
}: SlideUpProps) {
  const translateY = useSharedValue(distance);
  const opacity = useSharedValue(0);

  useEffect(() => {
    translateY.value = withDelay(
      delay,
      withTiming(0, { duration, easing: Easing.out(Easing.cubic) })
    );
    opacity.value = withDelay(
      delay,
      withTiming(1, { duration: duration * 0.8, easing: Easing.out(Easing.cubic) })
    );
  }, [translateY, opacity, distance, duration, delay]);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ translateY: translateY.value }],
    opacity: opacity.value,
  }));

  return (
    <Animated.View style={animatedStyle} className={className}>
      {children}
    </Animated.View>
  );
}
