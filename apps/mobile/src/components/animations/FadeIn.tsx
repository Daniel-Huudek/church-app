import React, { useEffect } from 'react';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withTiming,
  withDelay,
  Easing,
} from 'react-native-reanimated';

type SlideDirection = 'up' | 'down' | 'left' | 'right' | 'none';

export interface FadeInProps {
  children: React.ReactNode;
  duration?: number;
  delay?: number;
  direction?: SlideDirection;
  distance?: number;
  className?: string;
}

export function FadeIn({
  children,
  duration = 400,
  delay = 0,
  direction = 'up',
  distance = 20,
  className = '',
}: FadeInProps) {
  const opacity = useSharedValue(0);
  const translateX = useSharedValue(0);
  const translateY = useSharedValue(0);

  useEffect(() => {
    switch (direction) {
      case 'up':
        translateY.value = distance;
        break;
      case 'down':
        translateY.value = -distance;
        break;
      case 'left':
        translateX.value = distance;
        break;
      case 'right':
        translateX.value = -distance;
        break;
      default:
        break;
    }

    opacity.value = withDelay(
      delay,
      withTiming(1, { duration, easing: Easing.out(Easing.cubic) })
    );
    translateX.value = withDelay(
      delay,
      withTiming(0, { duration, easing: Easing.out(Easing.cubic) })
    );
    translateY.value = withDelay(
      delay,
      withTiming(0, { duration, easing: Easing.out(Easing.cubic) })
    );
  }, [opacity, translateX, translateY, duration, delay, direction, distance]);

  const animatedStyle = useAnimatedStyle(() => ({
    opacity: opacity.value,
    transform: [
      { translateX: translateX.value },
      { translateY: translateY.value },
    ],
  }));

  return (
    <Animated.View style={animatedStyle} className={className}>
      {children}
    </Animated.View>
  );
}
