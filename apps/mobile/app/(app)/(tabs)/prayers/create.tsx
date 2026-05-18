import { View, Text, TouchableOpacity, KeyboardAvoidingView, Platform, Alert } from 'react-native';
import { useState, useEffect, useCallback } from 'react';
import { router } from 'expo-router';
import { useColorScheme } from '../../../../src/hooks/useColorScheme';
import { prayersService } from '../../../../src/services/prayers';
import type { PrayerCategory } from '../../../../src/types';
import { PrayerForm } from '../../../../src/features/prayers/components/PrayerForm';
import { SlideUp } from '../../../../src/components/animations';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

function ArrowLeftIcon() {
  return <Text className="text-xl">‹</Text>;
}

export default function CreatePrayerScreen() {
  const { isDark, colors: themeColors } = useColorScheme();
  const insets = useSafeAreaInsets();
  const [categories, setCategories] = useState<PrayerCategory[]>([]);

  useEffect(() => {
    prayersService.getCategories()
      .then(setCategories)
      .catch(() => {});
  }, []);

  const handleSubmit = useCallback(async (data: any) => {
    try {
      await prayersService.create({
        title: data.title,
        description: data.description,
        category: categories.find((c) => c.id === data.category),
        isUrgent: data.isUrgent,
        isAnonymous: data.isAnonymous,
      } as any);
      Alert.alert('✅', 'Pedido de oração criado com sucesso!', [
        { text: 'OK', onPress: () => router.back() },
      ]);
    } catch (err: any) {
      throw new Error(err?.message || 'Erro ao criar pedido de oração.');
    }
  }, [categories]);

  return (
    <KeyboardAvoidingView
      className="flex-1"
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      style={{ backgroundColor: isDark ? '#0A0A0F' : '#F9FAFB' }}
    >
      <View className="flex-1" style={{ paddingTop: insets.top }}>
        <SlideUp distance={15} duration={400}>
          <View className="flex-row items-center justify-between px-4 pb-2 pt-2">
            <TouchableOpacity
              onPress={() => router.back()}
              className="w-9 h-9 items-center justify-center rounded-full"
              style={{ backgroundColor: isDark ? '#1A1A2E' : '#F3F4F6' }}
            >
              <ArrowLeftIcon />
            </TouchableOpacity>
            <Text
              className="text-lg font-semibold"
              style={{ color: isDark ? '#F9FAFB' : '#111827' }}
            >
              Novo Pedido
            </Text>
            <View style={{ width: 36 }} />
          </View>
        </SlideUp>

        <View className="flex-1">
          <SlideUp distance={30} delay={100} duration={500}>
            <PrayerForm
              categories={categories}
              onSubmit={handleSubmit}
            />
          </SlideUp>
        </View>
      </View>
    </KeyboardAvoidingView>
  );
}
