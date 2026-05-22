import { useState, useCallback } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  Switch,
  Alert,
  ScrollView,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Stack, router } from 'expo-router';
import { useColorScheme } from '../../src/hooks';
import { useAuthStore } from '../../src/store';
import { spacing, borderRadius } from '../../src/theme';

function SettingRow({
  label,
  subtitle,
  right,
  onPress,
  isLast,
}: {
  label: string;
  subtitle?: string;
  right?: React.ReactNode;
  onPress?: () => void;
  isLast?: boolean;
}) {
  const { isDark } = useColorScheme();

  return (
    <TouchableOpacity
      onPress={onPress}
      activeOpacity={onPress ? 0.7 : 1}
      style={{
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        paddingVertical: spacing.lg,
        paddingHorizontal: spacing.xl,
        borderBottomWidth: isLast ? 0 : 1,
        borderBottomColor: isDark ? '#1F2937' : '#F3F4F6',
      }}
    >
      <View style={{ flex: 1 }}>
        <Text style={{ fontSize: 16, color: isDark ? '#F9FAFB' : '#111827' }}>
          {label}
        </Text>
        {subtitle && (
          <Text style={{ fontSize: 13, color: isDark ? '#6B7280' : '#9CA3AF', marginTop: 2 }}>
            {subtitle}
          </Text>
        )}
      </View>
      {right}
    </TouchableOpacity>
  );
}

function SectionHeader({ title }: { title: string }) {
  const { isDark } = useColorScheme();
  return (
    <Text
      style={{
        fontSize: 13,
        fontWeight: '600',
        color: isDark ? '#9CA3AF' : '#6B7280',
        textTransform: 'uppercase',
        letterSpacing: 0.5,
        paddingHorizontal: spacing.xl,
        paddingTop: spacing['2xl'],
        paddingBottom: spacing.sm,
      }}
    >
      {title}
    </Text>
  );
}

export default function SettingsScreen() {
  const { isDark, toggleTheme } = useColorScheme();
  const logout = useAuthStore((s) => s.logout);
  const user = useAuthStore((s) => s.user);

  const handleLogout = useCallback(() => {
    Alert.alert(
      'Sair',
      'Tem certeza que deseja sair?',
      [
        { text: 'Cancelar', style: 'cancel' },
        {
          text: 'Sair',
          style: 'destructive',
          onPress: async () => {
            await logout();
            router.replace('/(auth)/login');
          },
        },
      ]
    );
  }, [logout]);

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: isDark ? '#0A0A0F' : '#FFFFFF' }}>
      <Stack.Screen
        options={{
          headerShown: true,
          headerTitle: 'Configurações',
          headerStyle: { backgroundColor: isDark ? '#12121A' : '#FFFFFF' },
          headerTintColor: isDark ? '#F9FAFB' : '#111827',
        }}
      />

      <ScrollView showsVerticalScrollIndicator={false}>
        {user && (
          <View
            style={{
              alignItems: 'center',
              paddingVertical: spacing['3xl'],
              borderBottomWidth: 1,
              borderBottomColor: isDark ? '#1F2937' : '#F3F4F6',
            }}
          >
            <View
              style={{
                width: 72,
                height: 72,
                borderRadius: 36,
                backgroundColor: 'rgba(139, 92, 246, 0.15)',
                alignItems: 'center',
                justifyContent: 'center',
                marginBottom: spacing.md,
              }}
            >
              <Text style={{ fontSize: 28, fontWeight: '700', color: '#66B5FF' }}>
                {user.name?.charAt(0)?.toUpperCase() || 'U'}
              </Text>
            </View>
            <Text style={{ fontSize: 18, fontWeight: '600', color: isDark ? '#F9FAFB' : '#111827' }}>
              {user.name}
            </Text>
            <Text style={{ fontSize: 14, color: isDark ? '#6B7280' : '#9CA3AF', marginTop: 2 }}>
              {user.email}
            </Text>
          </View>
        )}

        <SectionHeader title="Aparência" />
        <SettingRow
          label="Modo escuro"
          subtitle="Alterar o tema do aplicativo"
          right={
            <Switch
              value={isDark}
              onValueChange={toggleTheme}
              trackColor={{ false: '#D4D4D4', true: 'rgba(139, 92, 246, 0.3)' }}
              thumbColor={isDark ? '#008CFF' : '#A3A3A3'}
            />
          }
        />

        <SectionHeader title="Notificações" />
        <SettingRow
          label="Notificações push"
          subtitle="Receber notificações no dispositivo"
          right={
            <Switch
              value={true}
              trackColor={{ false: '#D4D4D4', true: 'rgba(139, 92, 246, 0.3)' }}
              thumbColor={'#008CFF'}
            />
          }
        />
        <SettingRow
          label="Lembretes de eventos"
          subtitle="Receber lembretes antes dos eventos"
          right={
            <Switch
              value={true}
              trackColor={{ false: '#D4D4D4', true: 'rgba(139, 92, 246, 0.3)' }}
              thumbColor={'#008CFF'}
            />
          }
          isLast
        />

        <SectionHeader title="Geral" />
        <SettingRow
          label="Idioma"
          subtitle="Português (Brasil)"
          onPress={() => Alert.alert('Idioma', 'Em breve você poderá alterar o idioma.')}
        />
        <SettingRow
          label="Versão"
          subtitle="1.0.0"
          isLast
        />

        <SectionHeader title="Sobre" />
        <SettingRow
          label="Ajuda e suporte"
          onPress={() => Alert.alert('Suporte', 'Entre em contato pelo email: suporte@churchapp.com')}
        />
        <SettingRow
          label="Termos de uso"
          onPress={() => Alert.alert('Termos', 'Funcionalidade em breve')}
        />
        <SettingRow
          label="Política de privacidade"
          onPress={() => Alert.alert('Privacidade', 'Funcionalidade em breve')}
          isLast
        />

        <View style={{ paddingHorizontal: spacing.xl, marginTop: spacing['3xl'], marginBottom: spacing['4xl'] }}>
          <TouchableOpacity
            onPress={handleLogout}
            style={{
              backgroundColor: isDark ? 'rgba(239, 68, 68, 0.1)' : 'rgba(239, 68, 68, 0.08)',
              paddingVertical: spacing.lg,
              borderRadius: borderRadius.xl,
              alignItems: 'center',
            }}
          >
            <Text style={{ color: '#EF4444', fontSize: 16, fontWeight: '600' }}>
              Sair da conta
            </Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}
