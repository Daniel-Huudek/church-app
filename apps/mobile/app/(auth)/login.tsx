import { useState, useCallback, useEffect } from 'react';
import {
  View,
  Text,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  TouchableOpacity,
  Alert,
} from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  withDelay,
  Easing,
} from 'react-native-reanimated';
import { LinearGradient } from 'expo-linear-gradient';
import { SafeAreaView } from 'react-native-safe-area-context';
import { router } from 'expo-router';
import { useAuth } from '../../src/hooks';
import { Input, Button } from '../../src/components/ui';

function FadeSlideIn({ children, delay }: { children: React.ReactNode; delay: number }) {
  const opacity = useSharedValue(0);
  const translateY = useSharedValue(24);

  useEffect(() => {
    opacity.value = withDelay(delay, withTiming(1, { duration: 500, easing: Easing.out(Easing.cubic) }));
    translateY.value = withDelay(delay, withTiming(0, { duration: 500, easing: Easing.out(Easing.cubic) }));
  }, []);

  const style = useAnimatedStyle(() => ({
    opacity: opacity.value,
    transform: [{ translateY: translateY.value }],
  }));

  return <Animated.View style={style}>{children}</Animated.View>;
}

export default function LoginScreen() {
  const { login } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleLogin = useCallback(async () => {
    if (!email.trim() || !password.trim()) {
      setError('Preencha todos os campos');
      return;
    }

    setError('');
    setLoading(true);

    try {
      await login(email.trim(), password);
      router.replace('/(app)/(tabs)');
    } catch (err: any) {
      const message =
        err?.response?.data?.message ||
        err?.message ||
        'Erro ao fazer login. Verifique suas credenciais.';
      setError(message);
    } finally {
      setLoading(false);
    }
  }, [email, password, login]);

  return (
    <LinearGradient colors={['#1a0533', '#0f0f2e', '#0a0a1a']} style={{ flex: 1 }}>
      <SafeAreaView style={{ flex: 1 }}>
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
          style={{ flex: 1 }}
        >
          <ScrollView
            contentContainerStyle={{ flexGrow: 1, justifyContent: 'center', paddingHorizontal: 24 }}
            keyboardShouldPersistTaps="handled"
            showsVerticalScrollIndicator={false}
          >
            <FadeSlideIn delay={0}>
              <View style={{ alignItems: 'center', marginBottom: 48 }}>
                <View
                  style={{
                    width: 56,
                    height: 56,
                    borderRadius: 16,
                    backgroundColor: 'rgba(139, 92, 246, 0.15)',
                    alignItems: 'center',
                    justifyContent: 'center',
                    marginBottom: 16,
                  }}
                >
                  <View style={{ width: 28, height: 28, alignItems: 'center', justifyContent: 'center' }}>
                    <View
                      style={{
                        position: 'absolute',
                        width: 28,
                        height: 3,
                        backgroundColor: '#A78BFA',
                        borderRadius: 1.5,
                      }}
                    />
                    <View
                      style={{
                        position: 'absolute',
                        width: 3,
                        height: 28,
                        backgroundColor: '#A78BFA',
                        borderRadius: 1.5,
                      }}
                    />
                  </View>
                </View>
                <Text
                  style={{
                    fontSize: 28,
                    fontWeight: '700',
                    color: '#F9FAFB',
                    letterSpacing: 1,
                  }}
                >
                  Church App
                </Text>
                <Text
                  style={{
                    fontSize: 14,
                    color: '#9CA3AF',
                    marginTop: 4,
                  }}
                >
                  Faça login para continuar
                </Text>
              </View>
            </FadeSlideIn>

            <View style={{ gap: 16 }}>
              <FadeSlideIn delay={150}>
                <Input
                  label="Email"
                  placeholder="seu@email.com"
                  value={email}
                  onChangeText={setEmail}
                  keyboardType="email-address"
                  autoCapitalize="none"
                  autoCorrect={false}
                  variant="filled"
                />
              </FadeSlideIn>

              <FadeSlideIn delay={250}>
                <Input
                  label="Senha"
                  placeholder="Sua senha"
                  value={password}
                  onChangeText={setPassword}
                  secureTextEntry
                  variant="filled"
                />
              </FadeSlideIn>

              {error ? (
                <Text
                  style={{
                    color: '#F87171',
                    fontSize: 13,
                    textAlign: 'center',
                    backgroundColor: 'rgba(248, 113, 113, 0.1)',
                    paddingVertical: 8,
                    paddingHorizontal: 12,
                    borderRadius: 8,
                    overflow: 'hidden',
                  }}
                >
                  {error}
                </Text>
              ) : null}

              <FadeSlideIn delay={350}>
                <Button
                  variant="primary"
                  size="lg"
                  fullWidth
                  loading={loading}
                  onPress={handleLogin}
                >
                  Entrar
                </Button>
              </FadeSlideIn>

              <FadeSlideIn delay={450}>
                <TouchableOpacity
                  onPress={() => Alert.alert('Recuperar senha', 'Funcionalidade em breve')}
                  style={{ alignItems: 'center', paddingVertical: 8 }}
                >
                  <Text style={{ color: '#A78BFA', fontSize: 14, fontWeight: '500' }}>
                    Esqueceu sua senha?
                  </Text>
                </TouchableOpacity>
              </FadeSlideIn>

              <FadeSlideIn delay={550}>
                <View
                  style={{
                    flexDirection: 'row',
                    justifyContent: 'center',
                    alignItems: 'center',
                    marginTop: 16,
                    gap: 4,
                  }}
                >
                  <Text style={{ color: '#6B7280', fontSize: 14 }}>
                    Não tem conta?
                  </Text>
                  <TouchableOpacity
                    onPress={() => Alert.alert('Cadastro', 'Funcionalidade em breve')}
                  >
                    <Text style={{ color: '#A78BFA', fontSize: 14, fontWeight: '600' }}>
                      Cadastre-se
                    </Text>
                  </TouchableOpacity>
                </View>
              </FadeSlideIn>
            </View>
          </ScrollView>
        </KeyboardAvoidingView>
      </SafeAreaView>
    </LinearGradient>
  );
}
