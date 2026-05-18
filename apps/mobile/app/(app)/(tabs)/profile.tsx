import { useState, useCallback } from 'react';
import { View, Text, ScrollView, TouchableOpacity, Alert } from 'react-native';
import { useRouter } from 'expo-router';
import { useAuth } from '../../../src/hooks/useAuth';
import { useColorScheme } from '../../../src/hooks/useColorScheme';
import { Header, Avatar, Badge, Card, Chip, Divider, Button } from '../../../src/components/ui';
import { FadeIn, SlideUp } from '../../../src/components/animations';

const roleLabels: Record<string, { label: string; color: string }> = {
  ADMINISTRADOR: { label: 'Administrador', color: '#EF4444' },
  PASTOR: { label: 'Pastor', color: '#8B5CF6' },
  FINANCEIRO: { label: 'Financeiro', color: '#3B82F6' },
  MEMBRO: { label: 'Membro', color: '#10B981' },
  VISITANTE: { label: 'Visitante', color: '#F59E0B' },
};

export default function Profile() {
  const router = useRouter();
  const { user, logout, isDark: isAuthDark } = useAuth();
  const { isDark, colors, toggleTheme, colorScheme } = useColorScheme();
  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false);

  const handleLogout = useCallback(() => {
    Alert.alert(
      'Sair da conta',
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
      ],
      { cancelable: true }
    );
  }, [logout, router]);

  const initials = user?.name
    ? user.name.split(' ').filter(Boolean).slice(0, 2).map(n => n[0]).join('').toUpperCase()
    : '?';

  const roleConfig = user?.role ? roleLabels[user.role] : { label: 'Membro', color: '#10B981' };

  const menuItems = [
    {
      icon: '✏️',
      label: 'Editar Perfil',
      onPress: () => {},
      color: '#8B5CF6',
    },
    {
      icon: '⚙️',
      label: 'Configurações',
      onPress: () => router.push('/(app)/settings'),
      color: '#3B82F6',
    },
    {
      icon: '🔔',
      label: 'Central de Notificações',
      badge: 3,
      onPress: () => router.push('/(app)/notifications'),
      color: '#F59E0B',
    },
  ];

  return (
    <View className="flex-1" style={{ backgroundColor: isDark ? '#0A0A0F' : '#FFFFFF' }}>
      <ScrollView showsVerticalScrollIndicator={false}>
        <View className="items-center pt-20 pb-6 px-6">
          <FadeIn direction="down" distance={20} duration={500}>
            <View className="items-center">
              <Avatar
                initials={initials}
                size="xl"
                ring
                badge={
                  <View
                    className="rounded-full px-2 py-0.5"
                    style={{ backgroundColor: roleConfig.color }}
                  >
                    <Text className="text-xs font-bold text-white">{roleConfig.label}</Text>
                  </View>
                }
              />
              <Text
                className="text-2xl font-bold mt-4"
                style={{ color: isDark ? '#F9FAFB' : '#111827' }}
              >
                {user?.name || 'Usuário'}
              </Text>
              {user?.email && (
                <Text
                  className="text-sm mt-1"
                  style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}
                >
                  {user.email}
                </Text>
              )}
              {user?.phone && (
                <Text
                  className="text-sm"
                  style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}
                >
                  {user.phone}
                </Text>
              )}
            </View>
          </FadeIn>
        </View>

        {user?.ministries && user.ministries.length > 0 && (
          <SlideUp distance={20} delay={150}>
            <Card variant="elevated" padding="lg" className="mx-6 mb-4">
              <Text
                className="text-sm font-semibold mb-3"
                style={{ color: isDark ? '#F9FAFB' : '#111827' }}
              >
                Ministérios
              </Text>
              <View className="flex-row flex-wrap" style={{ gap: 8 }}>
                {user.ministries.map((ministry) => (
                  <Chip key={ministry} label={ministry} variant="outlined" size="sm" />
                ))}
              </View>
            </Card>
          </SlideUp>
        )}

        <SlideUp distance={20} delay={200}>
          <Card variant="elevated" padding="lg" className="mx-6 mb-4">
            <Text
              className="text-sm font-semibold mb-4"
              style={{ color: isDark ? '#F9FAFB' : '#111827' }}
            >
              Estatísticas
            </Text>
            <View className="flex-row" style={{ gap: 12 }}>
              <View className="flex-1 items-center p-3 rounded-xl" style={{ backgroundColor: isDark ? '#12121A' : '#F9FAFB' }}>
                <Text className="text-2xl font-bold" style={{ color: isDark ? '#A78BFA' : '#7C3AED' }}>0</Text>
                <Text className="text-xs mt-1" style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}>Escalas</Text>
              </View>
              <View className="flex-1 items-center p-3 rounded-xl" style={{ backgroundColor: isDark ? '#12121A' : '#F9FAFB' }}>
                <Text className="text-2xl font-bold" style={{ color: isDark ? '#60A5FA' : '#3B82F6' }}>0</Text>
                <Text className="text-xs mt-1" style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}>Eventos</Text>
              </View>
              <View className="flex-1 items-center p-3 rounded-xl" style={{ backgroundColor: isDark ? '#12121A' : '#F9FAFB' }}>
                <Text className="text-2xl font-bold" style={{ color: isDark ? '#34D399' : '#10B981' }}>0</Text>
                <Text className="text-xs mt-1" style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}>Orações</Text>
              </View>
            </View>
          </Card>
        </SlideUp>

        <SlideUp distance={20} delay={250}>
          <Card variant="elevated" padding="none" className="mx-6 mb-4 overflow-hidden">
            {menuItems.map((item, index) => (
              <TouchableOpacity
                key={item.label}
                activeOpacity={0.7}
                onPress={item.onPress}
                className="flex-row items-center px-4 py-4"
                style={{
                  borderBottomWidth: index < menuItems.length - 1 ? 1 : 0,
                  borderBottomColor: isDark ? '#1F2937' : '#F3F4F6',
                }}
              >
                <View
                  className="w-9 h-9 rounded-xl items-center justify-center mr-3"
                  style={{ backgroundColor: `${item.color}15` }}
                >
                  <Text className="text-base">{item.icon}</Text>
                </View>
                <Text
                  className="flex-1 text-base font-medium"
                  style={{ color: isDark ? '#F9FAFB' : '#111827' }}
                >
                  {item.label}
                </Text>
                {'badge' in item && item.badge ? (
                  <View className="mr-2">
                    <Badge variant="error" count={item.badge} position="top-right" />
                  </View>
                ) : null}
                <Text style={{ color: isDark ? '#525252' : '#D4D4D4' }}>›</Text>
              </TouchableOpacity>
            ))}
          </Card>
        </SlideUp>

        <SlideUp distance={20} delay={300}>
          <Card variant="elevated" padding="none" className="mx-6 mb-4 overflow-hidden">
            <TouchableOpacity
              activeOpacity={0.7}
              onPress={toggleTheme}
              className="flex-row items-center px-4 py-4"
            >
              <View
                className="w-9 h-9 rounded-xl items-center justify-center mr-3"
                style={{ backgroundColor: isDark ? '#F59E0B15' : '#6366F115' }}
              >
                <Text className="text-base">{isDark ? '🌙' : '☀️'}</Text>
              </View>
              <Text
                className="flex-1 text-base font-medium"
                style={{ color: isDark ? '#F9FAFB' : '#111827' }}
              >
                Tema
              </Text>
              <Text
                className="text-sm font-medium mr-2"
                style={{ color: isDark ? '#A78BFA' : '#7C3AED' }}
              >
                {isDark ? 'Escuro' : 'Claro'}
              </Text>
              <Text style={{ color: isDark ? '#525252' : '#D4D4D4' }}>›</Text>
            </TouchableOpacity>
          </Card>
        </SlideUp>

        <SlideUp distance={20} delay={350}>
          <View className="px-6 mb-10">
            <Button
              variant="danger"
              size="lg"
              fullWidth
              onPress={handleLogout}
              leftIcon={<Text className="text-white">🚪</Text>}
            >
              Sair
            </Button>
          </View>
        </SlideUp>
      </ScrollView>
    </View>
  );
}
