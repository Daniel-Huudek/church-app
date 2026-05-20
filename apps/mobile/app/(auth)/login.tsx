import { useState, useCallback, useEffect } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  Platform,
  TextInput,
} from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  withDelay,
  Easing,
  withSequence,
} from 'react-native-reanimated';
import { LinearGradient } from 'expo-linear-gradient';
import { SafeAreaView } from 'react-native-safe-area-context';
import { router } from 'expo-router';
import * as WebBrowser from 'expo-web-browser';
import * as Google from 'expo-auth-session/providers/google';
import * as AuthSession from 'expo-auth-session';
import Constants from 'expo-constants';
import { useAuth } from '../../src/hooks';

WebBrowser.maybeCompleteAuthSession();

export default function LoginScreen() {
  const { login, loginWithGoogle } = useAuth();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPasswordLogin, setShowPasswordLogin] = useState(false);

  const extra = Constants.expoConfig?.extra;
  const clientId = extra?.googleClientId || '';
  
  const redirectUri = AuthSession.makeRedirectUri({
    scheme: 'churchapp',
    path: '+expo-auth-session',
  });

  const [request, response, promptAsync] = Google.useAuthRequest({
    clientId,
    redirectUri,
    scopes: ['openid', 'profile', 'email'],
    responseType: 'id_token',
  });

  useEffect(() => {
    console.log('Auth response:', response);
    if (response?.type === 'success') {
      const idToken = 
        response.params.id_token || 
        response.params.idToken || 
        response.authentication?.idToken;
      
      console.log('idToken found:', !!idToken);
      
      if (idToken) {
        handleGoogleLogin(idToken);
      } else {
        console.log('Response params:', response.params);
        console.log('Response authentication:', response.authentication);
        setError('Token não encontrado na resposta.');
      }
    } else if (response?.type === 'error') {
      setError('Login com Google cancelado ou falhou.');
    }
  }, [response]);

  const handleGoogleLogin = useCallback(async (idToken: string) => {
    setLoading(true);
    setError('');
    try {
      console.log('Sending idToken to backend:', idToken.substring(0, 50) + '...');
      await loginWithGoogle(idToken);
      router.replace('/(app)/(tabs)');
    } catch (err: any) {
      console.log('Login error:', err);
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
      await promptAsync();
    } catch {
      setError('Não foi possível iniciar o login com Google.');
    }
  }, [promptAsync]);

  const handleEmailLogin = useCallback(async () => {
    if (!email || !password) {
      setError('Por favor, preencha email e senha.');
      return;
    }
    setLoading(true);
    setError('');
    try {
      await login(email, password);
      router.replace('/(app)/(tabs)');
    } catch (err: any) {
      const message = err?.response?.data?.message || err?.message || 'Erro ao fazer login. Tente novamente.';
      setError(message);
    } finally {
      setLoading(false);
    }
  }, [email, password, login]);

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
    <LinearGradient colors={['#1a0533', '#0f0f2e', '#0a0a1a']} style={{ flex: 1 }}>
      <SafeAreaView style={{ flex: 1 }}>
        <View style={{ flex: 1, justifyContent: 'center', paddingHorizontal: 24 }}>
          <Animated.View style={[{ alignItems: 'center', marginBottom: 64 }, logoStyle]}>
            <View
              style={{
                width: 72,
                height: 72,
                borderRadius: 20,
                backgroundColor: 'rgba(139, 92, 246, 0.15)',
                alignItems: 'center',
                justifyContent: 'center',
                marginBottom: 20,
                borderWidth: 1,
                borderColor: 'rgba(139, 92, 246, 0.3)',
              }}
            >
              <View style={{ width: 32, height: 32, alignItems: 'center', justifyContent: 'center' }}>
                <View style={{ position: 'absolute', width: 32, height: 3.5, backgroundColor: '#C4B5FD', borderRadius: 2 }} />
                <View style={{ position: 'absolute', width: 3.5, height: 32, backgroundColor: '#C4B5FD', borderRadius: 2 }} />
              </View>
            </View>
            <Text style={{ fontSize: 32, fontWeight: '700', color: '#F9FAFB', letterSpacing: 1 }}>
              Church App
            </Text>
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
                backgroundColor: '#FFFFFF',
                borderRadius: 28,
                paddingVertical: 16,
                paddingHorizontal: 24,
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

          <FadeSlideIn delay={550}>
            <TouchableOpacity
              onPress={() => setShowPasswordLogin(!showPasswordLogin)}
              activeOpacity={0.8}
              style={{
                marginTop: 16,
                flexDirection: 'row',
                alignItems: 'center',
                justifyContent: 'center',
                backgroundColor: 'rgba(255,255,255,0.1)',
                borderRadius: 28,
                paddingVertical: 16,
                paddingHorizontal: 24,
                borderWidth: 1,
                borderColor: 'rgba(255,255,255,0.2)',
              }}
            >
              <Text style={{ color: '#F9FAFB', fontSize: 16, fontWeight: '600' }}>
                {showPasswordLogin ? 'Entrar com Google' : 'Entrar com Email'}
              </Text>
            </TouchableOpacity>
          </FadeSlideIn>

          {showPasswordLogin && (
            <FadeSlideIn delay={600}>
              <View style={{ marginTop: 16, width: '100%' }}>
                <TextInput
                  placeholder="Email"
                  placeholderTextColor="#9CA3AF"
                  value={email}
                  onChangeText={setEmail}
                  keyboardType="email-address"
                  autoCapitalize="none"
                  style={{
                    backgroundColor: 'rgba(255,255,255,0.1)',
                    borderRadius: 12,
                    paddingVertical: 14,
                    paddingHorizontal: 16,
                    color: '#F9FAFB',
                    fontSize: 16,
                    borderWidth: 1,
                    borderColor: 'rgba(255,255,255,0.2)',
                    marginBottom: 12,
                  }}
                />
                <TextInput
                  placeholder="Senha"
                  placeholderTextColor="#9CA3AF"
                  value={password}
                  onChangeText={setPassword}
                  secureTextEntry
                  style={{
                    backgroundColor: 'rgba(255,255,255,0.1)',
                    borderRadius: 12,
                    paddingVertical: 14,
                    paddingHorizontal: 16,
                    color: '#F9FAFB',
                    fontSize: 16,
                    borderWidth: 1,
                    borderColor: 'rgba(255,255,255,0.2)',
                    marginBottom: 16,
                  }}
                />
                <TouchableOpacity
                  onPress={handleEmailLogin}
                  disabled={loading}
                  activeOpacity={0.8}
                  style={{
                    backgroundColor: '#8B5CF6',
                    borderRadius: 28,
                    paddingVertical: 16,
                    alignItems: 'center',
                  }}
                >
                  <Text style={{ color: '#FFFFFF', fontSize: 16, fontWeight: '600' }}>
                    {loading ? 'Entrando...' : 'Entrar'}
                  </Text>
                </TouchableOpacity>
              </View>
            </FadeSlideIn>
          )}

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
              color: '#6B7280',
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
    </LinearGradient>
  );
}

function GoogleIcon() {
  return (
    <View style={{ width: 22, height: 22, alignItems: 'center', justifyContent: 'center' }}>
      <Text style={{ fontSize: 18, fontWeight: '700', color: '#4285F4' }}>G</Text>
    </View>
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
