import React, { useEffect } from 'react';
import { View, Text, Dimensions } from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withTiming,
  withDelay,
  withSequence,
  Easing,
  runOnJS,
} from 'react-native-reanimated';

interface SplashAnimationProps {
  onFinish: () => void;
}

const { width, height } = Dimensions.get('window');

export function SplashAnimation({ onFinish }: SplashAnimationProps) {
  const crossScale = useSharedValue(0);
  const crossOpacity = useSharedValue(0);
  const titleOpacity = useSharedValue(0);
  const titleTranslate = useSharedValue(20);
  const subtitleOpacity = useSharedValue(0);
  const subtitleTranslate = useSharedValue(20);
  const copyrightOpacity = useSharedValue(0);

  useEffect(() => {
    crossScale.value = withSequence(
      withTiming(1.2, { duration: 400, easing: Easing.out(Easing.back) }),
      withTiming(1, { duration: 200 })
    );
    crossOpacity.value = withTiming(1, { duration: 400 });

    titleOpacity.value = withDelay(
      600,
      withTiming(1, { duration: 500, easing: Easing.out(Easing.cubic) })
    );
    titleTranslate.value = withDelay(
      600,
      withTiming(0, { duration: 500, easing: Easing.out(Easing.cubic) })
    );

    subtitleOpacity.value = withDelay(
      1000,
      withTiming(1, { duration: 500, easing: Easing.out(Easing.cubic) })
    );
    subtitleTranslate.value = withDelay(
      1000,
      withTiming(0, { duration: 500, easing: Easing.out(Easing.cubic) })
    );

    copyrightOpacity.value = withDelay(
      1500,
      withTiming(1, { duration: 400, easing: Easing.out(Easing.cubic) })
    );

    const timer = setTimeout(() => {
      runOnJS(onFinish)();
    }, 2500);

    return () => clearTimeout(timer);
  }, []);

  const crossStyle = useAnimatedStyle(() => ({
    transform: [{ scale: crossScale.value }],
    opacity: crossOpacity.value,
  }));

  const titleStyle = useAnimatedStyle(() => ({
    opacity: titleOpacity.value,
    transform: [{ translateY: titleTranslate.value }],
  }));

  const subtitleStyle = useAnimatedStyle(() => ({
    opacity: subtitleOpacity.value,
    transform: [{ translateY: subtitleTranslate.value }],
  }));

  const copyrightStyle = useAnimatedStyle(() => ({
    opacity: copyrightOpacity.value,
  }));

  return (
    <View
      className="flex-1 items-center justify-center"
      style={{
        width,
        height,
        backgroundColor: '#0066CC',
      }}
    >
      <View className="absolute top-0 left-0 right-0 bottom-0 opacity-30">
        <View
          className="absolute -top-20 -right-20 w-72 h-72 rounded-full"
          style={{ backgroundColor: '#008CFF' }}
        />
        <View
          className="absolute -bottom-32 -left-16 w-96 h-96 rounded-full"
          style={{ backgroundColor: '#6D28D9' }}
        />
        <View
          className="absolute top-1/3 -left-10 w-40 h-40 rounded-full"
          style={{ backgroundColor: '#66B5FF' }}
        />
      </View>

      <Animated.View style={crossStyle} className="items-center mb-6">
        <View className="w-24 h-24 rounded-3xl bg-white/20 items-center justify-center">
          <Text className="text-5xl text-white">✝</Text>
        </View>
      </Animated.View>

      <Animated.View style={titleStyle} className="items-center">
        <Text className="text-4xl font-bold text-white tracking-wider">
          Church App
        </Text>
      </Animated.View>

      <Animated.View style={subtitleStyle} className="items-center mt-3">
        <Text className="text-lg text-white/80 tracking-wide">
          Sua igreja conectada
        </Text>
      </Animated.View>

      <Animated.View
        style={copyrightStyle}
        className="absolute bottom-12 items-center"
      >
        <Text className="text-sm text-white/50">
          © 2024 Church App. Todos os direitos reservados.
        </Text>
      </Animated.View>
    </View>
  );
}
