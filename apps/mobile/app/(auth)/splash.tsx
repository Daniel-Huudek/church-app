import { useEffect } from 'react';
import { View, Dimensions, Image } from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  withDelay,
  withRepeat,
  withSequence,
  Easing,
} from 'react-native-reanimated';
import { router } from 'expo-router';

const { width, height } = Dimensions.get('window');

function DecorativeCircle({ size, left, top, delay: d }: { size: number; left: number; top: number; delay: number }) {
  const opacity = useSharedValue(0);
  const scale = useSharedValue(0);

  useEffect(() => {
    opacity.value = withDelay(d, withTiming(0.15, { duration: 800, easing: Easing.out(Easing.cubic) }));
    scale.value = withDelay(d, withTiming(1, { duration: 800, easing: Easing.out(Easing.cubic) }));
  }, []);

  const style = useAnimatedStyle(() => ({
    opacity: opacity.value,
    transform: [{ scale: scale.value }],
  }));

  return (
    <Animated.View
      style={[
        style,
        {
          position: 'absolute',
          width: size,
          height: size,
          borderRadius: size / 2,
          borderWidth: 1,
          borderColor: 'rgba(196, 181, 253, 0.3)',
          left,
          top,
        },
      ]}
    />
  );
}

export default function SplashScreen() {
  const logoSuffixle = useSharedValue(0);
  const logoOpacity = useSharedValue(0);
  const pulseScale = useSharedValue(1);

  useEffect(() => {
    logoSuffixle.value = withTiming(1, { duration: 600, easing: Easing.out(Easing.back(1.5)) });
    logoOpacity.value = withTiming(1, { duration: 400 });

    pulseScale.value = withDelay(300, withRepeat(
      withSequence(
        withTiming(1.08, { duration: 1500, easing: Easing.inOut(Easing.sin) }),
        withTiming(1, { duration: 1500, easing: Easing.inOut(Easing.sin) })
      ),
      -1,
      true
    ));
  }, []);

  useEffect(() => {
    const timer = setTimeout(() => {
      router.replace('/(auth)/login');
    }, 2800);
    return () => clearTimeout(timer);
  }, []);

  const logoStyle = useAnimatedStyle(() => ({
    transform: [{ scale: logoSuffixle.value }],
    opacity: logoOpacity.value,
  }));

  const pulseStyle = useAnimatedStyle(() => ({
    transform: [{ scale: pulseScale.value }],
  }));

  return (
    <View style={{ flex: 1, backgroundColor: '#0A0A0F', alignItems: 'center', justifyContent: 'center' }}>
      <DecorativeCircle size={200} left={width * 0.05} top={height * 0.08} delay={200} />
      <DecorativeCircle size={140} left={width * 0.7} top={height * 0.15} delay={400} />
      <DecorativeCircle size={100} left={width * 0.1} top={height * 0.6} delay={600} />
      <DecorativeCircle size={160} left={width * 0.65} top={height * 0.65} delay={300} />

      <View style={{ alignItems: 'center', gap: 16 }}>
        <Animated.View style={[logoStyle, pulseStyle]}>
          <Image
            source={require('../../assets/logo.png')}
            style={{ width: 160, height: 160 }}
            resizeMode="contain"
          />
        </Animated.View>
      </View>
    </View>
  );
}
