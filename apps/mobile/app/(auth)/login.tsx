import { useState, useCallback, useEffect } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  Image,
} from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  withDelay,
  Easing,
  withSequence,
} from 'react-native-reanimated';
import { SafeAreaView } from 'react-native-safe-area-context';
import { router } from 'expo-router';
import { GoogleSignin } from '@react-native-google-signin/google-signin';
import Constants from 'expo-constants';
import { useAuth } from '../../src/hooks';

export default function LoginScreen() {
  const { loginWithGoogle } = useAuth();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleGoogleLogin = useCallback(async (idToken: string) => {
    setLoading(true);
    setError('');
    try {
      await loginWithGoogle(idToken);
      router.replace('/(app)/(tabs)');
    } catch (err: any) {
      const message =
        err?.response?.data?.message ||
        err?.message ||
        'Erro ao fazer login com Google. Tente novamente.';
      setError(message);
    } finally {
      setLoading(false);
    }
  }, [loginWithGoogle]);

  const handleGooglePress = useCallback(async () => {
    setError('');
    try {
      await GoogleSignin.hasPlayServices({ showPlayServicesUpdateDialog: true });
      const response = await GoogleSignin.signIn();
      const idToken = response.data?.idToken;

      if (idToken) {
        await handleGoogleLogin(idToken);
      } else {
        setError('Token não encontrado na resposta do Google.');
      }
    } catch (err: any) {
      if (err?.code === '-5') {
        setError('Login com Google cancelado.');
      } else {
        setError('Não foi possível iniciar o login com Google.');
      }
    }
  }, [handleGoogleLogin]);

  // Animations
  const logoScale = useSharedValue(0);
  const logoOpacity = useSharedValue(0);

  useEffect(() => {
    logoScale.value = withDelay(200, withSequence(
      withTiming(1.1, { duration: 400, easing: Easing.out(Easing.back) }),
      withTiming(1, { duration: 200 })
    ));
    logoOpacity.value = withDelay(200, withTiming(1, { duration: 400 }));
  }, []);

  const logoStyle = useAnimatedStyle(() => ({
    transform: [{ scale: logoScale.value }],
    opacity: logoOpacity.value,
  }));

  return (
    <View style={{ flex: 1, backgroundColor: '#008CFF' }}>
      <SafeAreaView style={{ flex: 1 }}>
        <View style={{ flex: 1, justifyContent: 'center', paddingHorizontal: 24 }}>
          <Animated.View style={[{ alignItems: 'center', marginBottom: 64 }, logoStyle]}>
            <Image
              source={require('../../assets/logo.png')}
              style={{ width: 180, height: 180 }}
              resizeMode="contain"
            />
            <Text style={{ fontSize: 15, color: '#9CA3AF', marginTop: 6 }}>
              Sua igreja conectada
            </Text>
          </Animated.View>

          <FadeSlideIn delay={500}>
            <TouchableOpacity
              onPress={handleGooglePress}
              disabled={loading}
              activeOpacity={0.8}
              style={{
                flexDirection: 'row',
                alignItems: 'center',
                justifyContent: 'center',
                alignSelf: 'center',
                backgroundColor: '#FFFFFF',
                borderRadius: 28,
                paddingVertical: 16,
                paddingHorizontal: 48,
                shadowColor: '#000',
                shadowOffset: { width: 0, height: 4 },
                shadowOpacity: 0.3,
                shadowRadius: 8,
                elevation: 6,
              }}
            >
              <GoogleIcon />
              <Text style={{ color: '#1F2937', fontSize: 16, fontWeight: '600', marginLeft: 12 }}>
                {loading ? 'Entrando...' : 'Entrar com Google'}
              </Text>
            </TouchableOpacity>
          </FadeSlideIn>

          {loading && (
            <FadeSlideIn delay={600}>
              <Text
                style={{
                  color: '#9CA3AF',
                  fontSize: 13,
                  textAlign: 'center',
                  marginTop: 16,
                }}
              >
                Aguarde enquanto verificamos sua conta...
              </Text>
            </FadeSlideIn>
          )}

          {error ? (
            <FadeSlideIn delay={0}>
              <Text
                style={{
                  color: '#F87171',
                  fontSize: 13,
                  textAlign: 'center',
                  marginTop: 16,
                  backgroundColor: 'rgba(248, 113, 113, 0.1)',
                  paddingVertical: 10,
                  paddingHorizontal: 16,
                  borderRadius: 8,
                  overflow: 'hidden',
                }}
              >
                {error}
              </Text>
            </FadeSlideIn>
          ) : null}
        </View>

        <FadeSlideIn delay={800}>
          <Text
            style={{
              color: '#FFFFFF',
              fontSize: 11,
              textAlign: 'center',
              paddingBottom: 24,
              paddingHorizontal: 32,
            }}
          >
            Ao continuar, você concorda com nossos Termos de Serviço e Política de Privacidade.
          </Text>
        </FadeSlideIn>
      </SafeAreaView>
    </View>
  );
}

function GoogleIcon() {
  return (
    <Image
      source={require('../../assets/google.png')}
      style={{ width: 16, height: 16 }}
      resizeMode="contain"
    />
  );
}

function FadeSlideIn({ children, delay, style: containerStyle }: {
  children: React.ReactNode;
  delay: number;
  style?: any;
}) {
  const opacity = useSharedValue(0);
  const translateY = useSharedValue(20);

  useEffect(() => {
    opacity.value = withDelay(delay, withTiming(1, { duration: 500, easing: Easing.out(Easing.cubic) }));
    translateY.value = withDelay(delay, withTiming(0, { duration: 500, easing: Easing.out(Easing.cubic) }));
  }, []);

  const animatedStyle = useAnimatedStyle(() => ({
    opacity: opacity.value,
    transform: [{ translateY: translateY.value }],
  }));

  return <Animated.View style={[animatedStyle, containerStyle]}>{children}</Animated.View>;
}
