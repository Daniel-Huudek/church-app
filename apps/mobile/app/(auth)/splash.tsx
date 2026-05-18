import { useEffect } from 'react';
import { View, Text, Dimensions } from 'react-native';
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

const CROSS_SIZE = 80;
const CROSS_STROKE = 6;

function CrossIcon() {
  return (
    <View style={{ width: CROSS_SIZE, height: CROSS_SIZE, alignItems: 'center', justifyContent: 'center' }}>
      <View
        style={{
          position: 'absolute',
          width: CROSS_SIZE,
          height: CROSS_STROKE,
          backgroundColor: '#C4B5FD',
          borderRadius: CROSS_STROKE / 2,
        }}
      />
      <View
        style={{
          position: 'absolute',
          width: CROSS_STROKE,
          height: CROSS_SIZE,
          backgroundColor: '#C4B5FD',
          borderRadius: CROSS_STROKE / 2,
        }}
      />
    </View>
  );
}

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
  const crossScale = useSharedValue(0);
  const crossOpacity = useSharedValue(0);
  const titleOpacity = useSharedValue(0);
  const titleTranslateY = useSharedValue(30);
  const subtitleOpacity = useSharedValue(0);
  const subtitleTranslateY = useSharedValue(20);
  const taglineOpacity = useSharedValue(0);
  const pulseScale = useSharedValue(1);

  useEffect(() => {
    crossScale.value = withTiming(1, { duration: 600, easing: Easing.out(Easing.back(1.5)) });
    crossOpacity.value = withTiming(1, { duration: 400 });

    titleOpacity.value = withDelay(400, withTiming(1, { duration: 500 }));
    titleTranslateY.value = withDelay(400, withTiming(0, { duration: 500 }));

    subtitleOpacity.value = withDelay(700, withTiming(1, { duration: 400 }));
    subtitleTranslateY.value = withDelay(700, withTiming(0, { duration: 400 }));

    taglineOpacity.value = withDelay(1000, withTiming(1, { duration: 400 }));

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

  const crossStyle = useAnimatedStyle(() => ({
    transform: [{ scale: crossScale.value }],
    opacity: crossOpacity.value,
  }));

  const pulseStyle = useAnimatedStyle(() => ({
    transform: [{ scale: pulseScale.value }],
  }));

  const titleStyle = useAnimatedStyle(() => ({
    opacity: titleOpacity.value,
    transform: [{ translateY: titleTranslateY.value }],
  }));

  const subtitleStyle = useAnimatedStyle(() => ({
    opacity: subtitleOpacity.value,
    transform: [{ translateY: subtitleTranslateY.value }],
  }));

  return (
    <View style={{ flex: 1, backgroundColor: '#0A0A0F', alignItems: 'center', justifyContent: 'center' }}>
      <DecorativeCircle size={200} left={width * 0.05} top={height * 0.08} delay={200} />
      <DecorativeCircle size={140} left={width * 0.7} top={height * 0.15} delay={400} />
      <DecorativeCircle size={100} left={width * 0.1} top={height * 0.6} delay={600} />
      <DecorativeCircle size={160} left={width * 0.65} top={height * 0.65} delay={300} />

      <View style={{ alignItems: 'center', gap: 16 }}>
        <Animated.View style={[crossStyle, pulseStyle]}>
          <CrossIcon />
        </Animated.View>

        <View style={{ alignItems: 'center', gap: 8 }}>
          <Animated.View style={titleStyle}>
            <Text
              style={{
                fontSize: 36,
                fontWeight: '700',
                color: '#F9FAFB',
                letterSpacing: 2,
                textAlign: 'center',
              }}
            >
              Church App
            </Text>
          </Animated.View>

          <Animated.View style={subtitleStyle}>
            <Text
              style={{
                fontSize: 16,
                color: '#9CA3AF',
                textAlign: 'center',
                letterSpacing: 0.5,
              }}
            >
              Sua igreja conectada
            </Text>
          </Animated.View>

          <Animated.View style={[{ opacity: taglineOpacity, marginTop: 24 }]}>
            <Text
              style={{
                fontSize: 13,
                color: '#6B7280',
                textAlign: 'center',
                letterSpacing: 1,
                textTransform: 'uppercase',
              }}
            >
              Fé • Comunhão • Serviço
            </Text>
          </Animated.View>
        </View>
      </View>
    </View>
  );
}
