import { useEffect } from 'react';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  withSpring,
  withDelay,
  type WithTimingConfig,
  type WithSpringConfig,
} from 'react-native-reanimated';

const defaultTimingConfig: WithTimingConfig = { duration: 400 };
const defaultSpringConfig: WithSpringConfig = { damping: 15, stiffness: 100 };

export function useAnimation(delay = 0) {
  const fadeOpacity = useSharedValue(0);
  const slideOffset = useSharedValue(50);
  const slideOpacity = useSharedValue(0);
  const scaleValue = useSharedValue(0.8);
  const scaleOpacity = useSharedValue(0);

  useEffect(() => {
    fadeOpacity.value = withDelay(delay, withTiming(1, defaultTimingConfig));
    slideOffset.value = withDelay(delay, withSpring(0, defaultSpringConfig));
    slideOpacity.value = withDelay(delay, withTiming(1, defaultTimingConfig));
    scaleValue.value = withDelay(delay, withSpring(1, { ...defaultSpringConfig, stiffness: 120 }));
    scaleOpacity.value = withDelay(delay, withTiming(1, defaultTimingConfig));
  }, [delay, fadeOpacity, slideOffset, slideOpacity, scaleValue, scaleOpacity]);

  const fadeIn = useAnimatedStyle(() => ({
    opacity: fadeOpacity.value,
  }));

  const slideUp = useAnimatedStyle(() => ({
    opacity: slideOpacity.value,
    transform: [{ translateY: slideOffset.value }],
  }));

  const scaleIn = useAnimatedStyle(() => ({
    opacity: scaleOpacity.value,
    transform: [{ scale: scaleValue.value }],
  }));

  return { fadeIn, slideUp, scaleIn } as const;
}
