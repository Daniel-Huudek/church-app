import React, { useEffect } from 'react';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  withDelay,
} from 'react-native-reanimated';

export interface ScaleInProps {
  children: React.ReactNode;
  delay?: number;
  from?: number;
  damping?: number;
  stiffness?: number;
  className?: string;
}

export function ScaleIn({
  children,
  delay = 0,
  from = 0.8,
  damping = 12,
  stiffness = 200,
  className = '',
}: ScaleInProps) {
  const scale = useSharedValue(from);

  useEffect(() => {
    scale.value = withDelay(
      delay,
      withSpring(1, { damping, stiffness })
    );
  }, [scale, delay, from, damping, stiffness]);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
    opacity: scale.value,
  }));

  return (
    <Animated.View style={animatedStyle} className={className}>
      {children}
    </Animated.View>
  );
}
