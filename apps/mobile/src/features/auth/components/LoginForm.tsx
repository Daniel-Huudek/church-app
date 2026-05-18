import React, { useState, useCallback } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
} from 'react-native';
import { useForm, Controller } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withTiming,
  withDelay,
  Easing,
} from 'react-native-reanimated';
import { useColorScheme } from '../../../hooks/useColorScheme';
import { Button } from '../../../components/ui/Button';
import { loginSchema, LoginFormData } from '../../../utils/validation';

interface LoginFormProps {
  onSubmit: (data: LoginFormData) => Promise<void>;
  onForgotPassword?: () => void;
  onGoogleLogin?: () => void;
}

export function LoginForm({
  onSubmit,
  onForgotPassword,
  onGoogleLogin,
}: LoginFormProps) {
  const { isDark, colors } = useColorScheme();
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const {
    control,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<LoginFormData>({
    resolver: zodResolver(loginSchema),
    defaultValues: { email: '', password: '' },
  });

  const formOpacity = useSharedValue(0);
  const formTranslate = useSharedValue(30);

  React.useEffect(() => {
    formOpacity.value = withDelay(
      200,
      withTiming(1, { duration: 600, easing: Easing.out(Easing.cubic) })
    );
    formTranslate.value = withDelay(
      200,
      withTiming(0, { duration: 600, easing: Easing.out(Easing.cubic) })
    );
  }, []);

  const animatedStyle = useAnimatedStyle(() => ({
    opacity: formOpacity.value,
    transform: [{ translateY: formTranslate.value }],
  }));

  const handleFormSubmit = useCallback(
    async (data: LoginFormData) => {
      setError(null);
      try {
        await onSubmit(data);
      } catch (err: any) {
        setError(err?.message || 'Erro ao fazer login. Tente novamente.');
      }
    },
    [onSubmit]
  );

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      className="flex-1"
    >
      <ScrollView
        contentContainerStyle={{ flexGrow: 1 }}
        keyboardShouldPersistTaps="handled"
        showsVerticalScrollIndicator={false}
      >
        <Animated.View style={animatedStyle} className="px-6 pt-8">
          <View className="items-center mb-8">
            <View className="w-16 h-16 rounded-2xl bg-purple-600 items-center justify-center mb-4">
              <Text className="text-3xl text-white">✝</Text>
            </View>
            <Text
              className="text-2xl font-bold"
              style={{ color: isDark ? '#F9FAFB' : '#111827' }}
            >
              Bem-vindo
            </Text>
            <Text
              className="text-base mt-1"
              style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}
            >
              Faça login para continuar
            </Text>
          </View>

          {error && (
            <View className="bg-red-500/10 border border-red-500/30 rounded-xl px-4 py-3 mb-4">
              <Text className="text-red-500 text-sm font-medium">{error}</Text>
            </View>
          )}

          <Controller
            control={control}
            name="email"
            render={({ field: { onChange, onBlur, value } }) => (
              <View className="mb-4">
                <Text
                  className="text-sm font-medium mb-1.5"
                  style={{ color: isDark ? '#D4D4D4' : '#525252' }}
                >
                  Email
                </Text>
                <View
                  className={`
                    flex-row items-center rounded-xl px-4 py-3.5 border
                    ${errors.email ? 'border-red-500' : isDark ? 'border-[#1F2937]' : 'border-[#E5E7EB]'}
                  `}
                  style={{
                    backgroundColor: isDark ? '#1A1A2E' : '#F9FAFB',
                  }}
                >
                  <Text
                    className="mr-3 text-base"
                    style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}
                  >
                    ✉
                  </Text>
                  <TextInput
                    className="flex-1 text-base"
                    style={{
                      color: isDark ? '#F9FAFB' : '#111827',
                      fontFamily: Platform.OS === 'ios' ? 'System' : 'Roboto',
                    }}
                    placeholder="seu@email.com"
                    placeholderTextColor={isDark ? '#6B7280' : '#9CA3AF'}
                    autoCapitalize="none"
                    autoCorrect={false}
                    keyboardType="email-address"
                    value={value}
                    onChangeText={onChange}
                    onBlur={onBlur}
                  />
                </View>
                {errors.email && (
                  <Text className="text-red-500 text-xs mt-1 ml-1">
                    {errors.email.message}
                  </Text>
                )}
              </View>
            )}
          />

          <Controller
            control={control}
            name="password"
            render={({ field: { onChange, onBlur, value } }) => (
              <View className="mb-2">
                <Text
                  className="text-sm font-medium mb-1.5"
                  style={{ color: isDark ? '#D4D4D4' : '#525252' }}
                >
                  Senha
                </Text>
                <View
                  className={`
                    flex-row items-center rounded-xl px-4 py-3.5 border
                    ${errors.password ? 'border-red-500' : isDark ? 'border-[#1F2937]' : 'border-[#E5E7EB]'}
                  `}
                  style={{
                    backgroundColor: isDark ? '#1A1A2E' : '#F9FAFB',
                  }}
                >
                  <Text
                    className="mr-3 text-base"
                    style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}
                  >
                    🔒
                  </Text>
                  <TextInput
                    className="flex-1 text-base"
                    style={{
                      color: isDark ? '#F9FAFB' : '#111827',
                      fontFamily: Platform.OS === 'ios' ? 'System' : 'Roboto',
                    }}
                    placeholder="Sua senha"
                    placeholderTextColor={isDark ? '#6B7280' : '#9CA3AF'}
                    secureTextEntry={!showPassword}
                    value={value}
                    onChangeText={onChange}
                    onBlur={onBlur}
                  />
                  <TouchableOpacity
                    onPress={() => setShowPassword(!showPassword)}
                    className="ml-2 p-1"
                    hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
                  >
                    <Text
                      className="text-base"
                      style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}
                    >
                      {showPassword ? '🙈' : '👁️'}
                    </Text>
                  </TouchableOpacity>
                </View>
                {errors.password && (
                  <Text className="text-red-500 text-xs mt-1 ml-1">
                    {errors.password.message}
                  </Text>
                )}
              </View>
            )}
          />

          {onForgotPassword && (
            <TouchableOpacity onPress={onForgotPassword} className="self-end mb-6">
              <Text className="text-sm font-medium text-purple-600">
                Esqueceu a senha?
              </Text>
            </TouchableOpacity>
          )}

          <Button
            variant="primary"
            fullWidth
            size="lg"
            loading={isSubmitting}
            onPress={handleSubmit(handleFormSubmit)}
            className="mb-3"
          >
            Entrar
          </Button>

          {onGoogleLogin && (
            <>
              <View className="flex-row items-center my-4">
                <View
                  className="flex-1 h-px"
                  style={{ backgroundColor: isDark ? '#1F2937' : '#E5E7EB' }}
                />
                <Text
                  className="mx-3 text-sm"
                  style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}
                >
                  ou
                </Text>
                <View
                  className="flex-1 h-px"
                  style={{ backgroundColor: isDark ? '#1F2937' : '#E5E7EB' }}
                />
              </View>

              <TouchableOpacity
                onPress={onGoogleLogin}
                className={`
                  flex-row items-center justify-center rounded-full border py-4
                  ${isDark ? 'border-[#1F2937]' : 'border-[#D1D5DB]'}
                `}
                style={{
                  backgroundColor: isDark ? '#12121A' : '#FFFFFF',
                }}
                activeOpacity={0.7}
              >
                <Text className="text-lg mr-3">G</Text>
                <Text
                  className="text-base font-semibold"
                  style={{ color: isDark ? '#F9FAFB' : '#111827' }}
                >
                  Entrar com Google
                </Text>
              </TouchableOpacity>
            </>
          )}
        </Animated.View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}
