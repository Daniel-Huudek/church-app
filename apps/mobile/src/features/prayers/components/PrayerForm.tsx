import React, { useState, useCallback } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  ScrollView,
  Switch,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { useForm, Controller } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { useColorScheme } from '../../../hooks/useColorScheme';
import { Button } from '../../../components/ui/Button';
import { prayerSchema, PrayerFormData } from '../../../utils/validation';
import { PrayerCategory } from '../../../types';

interface PrayerFormProps {
  categories: PrayerCategory[];
  onSubmit: (data: PrayerFormData & { privacy: string }) => Promise<void>;
  initialValues?: Partial<PrayerFormData>;
}

const privacyOptions = [
  { value: 'PUBLICO', label: 'Público', desc: 'Todos podem ver e orar' },
  { value: 'MEMBROS', label: 'Membros', desc: 'Apenas membros da igreja' },
  { value: 'PRIVADO', label: 'Privado', desc: 'Apenas líderes' },
];

export function PrayerForm({
  categories,
  onSubmit,
  initialValues,
}: PrayerFormProps) {
  const { isDark } = useColorScheme();
  const [privacy, setPrivacy] = useState('PUBLICO');
  const [error, setError] = useState<string | null>(null);

  const {
    control,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<PrayerFormData>({
    resolver: zodResolver(prayerSchema),
    defaultValues: {
      title: initialValues?.title || '',
      description: initialValues?.description || '',
      category: initialValues?.category || '',
      isUrgent: initialValues?.isUrgent || false,
      isAnonymous: initialValues?.isAnonymous || false,
    },
  });

  const handleFormSubmit = useCallback(
    async (data: PrayerFormData) => {
      setError(null);
      try {
        await onSubmit({ ...data, privacy });
      } catch (err: any) {
        setError(err?.message || 'Erro ao enviar pedido de oração.');
      }
    },
    [onSubmit, privacy]
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
        <View className="px-6 pt-4">
          {error && (
            <View className="bg-red-500/10 border border-red-500/30 rounded-xl px-4 py-3 mb-4">
              <Text className="text-red-500 text-sm font-medium">{error}</Text>
            </View>
          )}

          <Controller
            control={control}
            name="title"
            render={({ field: { onChange, onBlur, value } }) => (
              <View className="mb-4">
                <Text
                  className="text-sm font-medium mb-1.5"
                  style={{ color: isDark ? '#D4D4D4' : '#525252' }}
                >
                  Título
                </Text>
                <TextInput
                  className={`text-base rounded-xl px-4 py-3.5 border ${
                    errors.title
                      ? 'border-red-500'
                      : isDark
                      ? 'border-[#1F2937]'
                      : 'border-[#E5E7EB]'
                  }`}
                  style={{
                    color: isDark ? '#F9FAFB' : '#111827',
                    backgroundColor: isDark ? '#1A1A2E' : '#F9FAFB',
                  }}
                  placeholder="O que você gostaria de compartilhar?"
                  placeholderTextColor={isDark ? '#6B7280' : '#9CA3AF'}
                  value={value}
                  onChangeText={onChange}
                  onBlur={onBlur}
                />
                {errors.title && (
                  <Text className="text-red-500 text-xs mt-1 ml-1">
                    {errors.title.message}
                  </Text>
                )}
              </View>
            )}
          />

          <Controller
            control={control}
            name="description"
            render={({ field: { onChange, onBlur, value } }) => (
              <View className="mb-4">
                <Text
                  className="text-sm font-medium mb-1.5"
                  style={{ color: isDark ? '#D4D4D4' : '#525252' }}
                >
                  Descrição
                </Text>
                <TextInput
                  className={`text-base rounded-xl px-4 py-3.5 border ${
                    errors.description
                      ? 'border-red-500'
                      : isDark
                      ? 'border-[#1F2937]'
                      : 'border-[#E5E7EB]'
                  }`}
                  style={{
                    color: isDark ? '#F9FAFB' : '#111827',
                    backgroundColor: isDark ? '#1A1A2E' : '#F9FAFB',
                    minHeight: 100,
                    textAlignVertical: 'top',
                  }}
                  placeholder="Compartilhe seu pedido de oração..."
                  placeholderTextColor={isDark ? '#6B7280' : '#9CA3AF'}
                  multiline
                  numberOfLines={4}
                  value={value}
                  onChangeText={onChange}
                  onBlur={onBlur}
                />
                {errors.description && (
                  <Text className="text-red-500 text-xs mt-1 ml-1">
                    {errors.description.message}
                  </Text>
                )}
              </View>
            )}
          />

          <Controller
            control={control}
            name="category"
            render={({ field: { onChange, value } }) => (
              <View className="mb-4">
                <Text
                  className="text-sm font-medium mb-2"
                  style={{ color: isDark ? '#D4D4D4' : '#525252' }}
                >
                  Categoria
                </Text>
                <View className="flex-row flex-wrap gap-2">
                  {categories.map((cat) => {
                    const isSelected = value === cat.id;
                    return (
                      <TouchableOpacity
                        key={cat.id}
                        onPress={() => onChange(cat.id)}
                        activeOpacity={0.7}
                        className={`rounded-full px-4 py-2 ${
                          isSelected
                            ? 'bg-purple-600'
                            : isDark
                            ? 'bg-neutral-800'
                            : 'bg-neutral-100'
                        }`}
                      >
                        <Text
                          className={`text-sm font-medium ${
                            isSelected
                              ? 'text-white'
                              : isDark
                              ? 'text-neutral-200'
                              : 'text-neutral-700'
                          }`}
                        >
                          {cat.icon || '🙏'} {cat.name}
                        </Text>
                      </TouchableOpacity>
                    );
                  })}
                </View>
                {errors.category && (
                  <Text className="text-red-500 text-xs mt-1 ml-1">
                    {errors.category.message}
                  </Text>
                )}
              </View>
            )}
          />

          <Text
            className="text-sm font-medium mb-3"
            style={{ color: isDark ? '#D4D4D4' : '#525252' }}
          >
            Privacidade
          </Text>
          <View className="flex-row gap-2 mb-4">
            {privacyOptions.map((opt) => {
              const isSelected = privacy === opt.value;
              return (
                <TouchableOpacity
                  key={opt.value}
                  onPress={() => setPrivacy(opt.value)}
                  activeOpacity={0.7}
                  className={`flex-1 rounded-xl p-3 border ${
                    isSelected
                      ? 'border-purple-600'
                      : isDark
                      ? 'border-[#1F2937]'
                      : 'border-[#E5E7EB]'
                  }`}
                  style={{
                    backgroundColor: isSelected
                      ? isDark
                        ? 'rgba(139,92,246,0.15)'
                        : '#F5F3FF'
                      : 'transparent',
                  }}
                >
                  <Text
                    className={`text-xs font-semibold mb-0.5 ${
                      isSelected
                        ? 'text-purple-600'
                        : isDark
                        ? 'text-neutral-300'
                        : 'text-neutral-700'
                    }`}
                  >
                    {opt.label}
                  </Text>
                  <Text
                    className="text-[10px]"
                    style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}
                  >
                    {opt.desc}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </View>

          <Controller
            control={control}
            name="isAnonymous"
            render={({ field: { onChange, value } }) => (
              <View
                className="flex-row items-center justify-between mb-3 rounded-xl px-4 py-3"
                style={{
                  backgroundColor: isDark ? '#1A1A2E' : '#F9FAFB',
                }}
              >
                <View className="flex-1">
                  <Text
                    className="text-sm font-medium"
                    style={{ color: isDark ? '#D4D4D4' : '#525252' }}
                  >
                    Pedido anônimo
                  </Text>
                  <Text
                    className="text-xs"
                    style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}
                  >
                    Seu nome não será exibido
                  </Text>
                </View>
                <Switch
                  value={value}
                  onValueChange={onChange}
                  trackColor={{
                    false: isDark ? '#374151' : '#D1D5DB',
                    true: '#8B5CF680',
                  }}
                  thumbColor={value ? '#8B5CF6' : isDark ? '#6B7280' : '#F9FAFB'}
                />
              </View>
            )}
          />

          <Controller
            control={control}
            name="isUrgent"
            render={({ field: { onChange, value } }) => (
              <View
                className="flex-row items-center justify-between mb-6 rounded-xl px-4 py-3"
                style={{
                  backgroundColor: isDark ? '#1A1A2E' : '#F9FAFB',
                }}
              >
                <View className="flex-1">
                  <Text
                    className="text-sm font-medium"
                    style={{ color: isDark ? '#D4D4D4' : '#525252' }}
                  >
                    Pedido urgente
                  </Text>
                  <Text
                    className="text-xs"
                    style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}
                  >
                    Destacado com prioridade
                  </Text>
                </View>
                <Switch
                  value={value}
                  onValueChange={onChange}
                  trackColor={{
                    false: isDark ? '#374151' : '#D1D5DB',
                    true: '#EF444480',
                  }}
                  thumbColor={value ? '#EF4444' : isDark ? '#6B7280' : '#F9FAFB'}
                />
              </View>
            )}
          />

          <Button
            variant="primary"
            fullWidth
            size="lg"
            loading={isSubmitting}
            onPress={handleSubmit(handleFormSubmit)}
          >
            Enviar Pedido de Oração
          </Button>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}
