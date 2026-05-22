import { useState, useCallback } from 'react';
import { View, Text, ScrollView, TouchableOpacity, Alert, Image } from 'react-native';
import { useRouter } from 'expo-router';
import { useAuth } from '../../../src/hooks/useAuth';
import { useColorScheme } from '../../../src/hooks/useColorScheme';

const roleLabels: Record<string, { label: string; color: string; icon: string }> = {
  ADMINISTRADOR: { label: 'Administrador', color: '#EF4444', icon: '👑' },
  PASTOR: { label: 'Pastor', color: '#008CFF', icon: '✝️' },
  FINANCEIRO: { label: 'Financeiro', color: '#3B82F6', icon: '💰' },
  LIDER: { label: 'Líder', color: '#F59E0B', icon: '⭐' },
  MEMBRO: { label: 'Membro', color: '#10B981', icon: '🙂' },
  VISITANTE: { label: 'Visitante', color: '#6B7280', icon: '👋' },
};

const menuItems = [
  { icon: '👤', label: 'Editar Perfil', color: '#008CFF', action: 'editProfile' },
  { icon: '⚙️', label: 'Configurações', color: '#3B82F6', action: 'settings' },
  { icon: '🔔', label: 'Notificações', color: '#F59E0B', action: 'notifications', badge: 3 },
  { icon: '📅', label: 'Minhas Escalas', color: '#10B981', action: 'schedules' },
  { icon: '🎉', label: 'Meus Eventos', color: '#EC4899', action: 'events' },
  { icon: '🙏', label: 'Minhas Orações', color: '#06B6D4', action: 'prayers' },
];

const quickActions = [
  { icon: '📱', label: 'Compartilhar App', color: '#008CFF' },
  { icon: '❓', label: 'Ajuda', color: '#3B82F6' },
  { icon: 'ℹ️', label: 'Sobre', color: '#6B7280' },
];

export default function Profile() {
  const router = useRouter();
  const { user } = useAuth();
  const { isDark, toggleTheme } = useColorScheme();

  const handleLogout = useCallback(() => {
    Alert.alert(
      'Sair da conta',
      'Tem certeza que deseja sair?',
      [
        { text: 'Cancelar', style: 'cancel' },
        {
          text: 'Sair',
          style: 'destructive',
          onPress: () => router.replace('/login'),
        },
      ],
      { cancelable: true }
    );
  }, [router]);

  const handleMenuPress = useCallback((action: string) => {
    switch (action) {
      case 'settings':
        router.push('/(app)/settings');
        break;
      case 'notifications':
        router.push('/(app)/notifications');
        break;
      case 'schedules':
        router.push('/(app)/(tabs)/schedules');
        break;
      case 'prayers':
        router.push('/(app)/(tabs)/prayers');
        break;
      case 'events':
        router.push('/(app)/(tabs)/events');
        break;
      default:
        break;
    }
  }, [router]);

  const initials = user?.name
    ? user.name.split(' ').filter(Boolean).slice(0, 2).map(n => n[0]).join('').toUpperCase()
    : '?';

  const roleConfig = user?.role ? roleLabels[user.role] : roleLabels.MEMBRO;

  const bgColor = isDark ? '#0A0A0F' : '#F8FAFC';
  const cardBg = isDark ? '#1A1A2E' : '#FFFFFF';
  const textPrimary = isDark ? '#F9FAFB' : '#111827';
  const textSecondary = isDark ? '#9CA3AF' : '#6B7280';
  const borderColor = isDark ? '#1F2937' : '#E5E7EB';

  return (
    <View style={{ flex: 1, backgroundColor: bgColor }}>
      <ScrollView showsVerticalScrollIndicator={false} className="flex-1">
        <View style={{ height: 180, backgroundColor: '#008CFF', position: 'relative' }}>
          <View style={{ position: 'absolute', bottom: -50, left: 0, right: 0, alignItems: 'center' }}>
            <View style={{ width: 100, height: 100, borderRadius: 50, backgroundColor: cardBg, padding: 4, shadowColor: '#000', shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.3, shadowRadius: 8, elevation: 8 }}>
              {user?.avatar ? (
                <Image source={{ uri: user.avatar }} style={{ width: '100%', height: '100%', borderRadius: 46 }} />
              ) : (
                <View style={{ width: '100%', height: '100%', borderRadius: 46, backgroundColor: '#008CFF', alignItems: 'center', justifyContent: 'center' }}>
                  <Text style={{ fontSize: 32, fontWeight: 'bold', color: '#FFFFFF' }}>{initials}</Text>
                </View>
              )}
            </View>
          </View>
        </View>

        <View style={{ marginTop: 60, paddingHorizontal: 20 }}>
          <View style={{ alignItems: 'center', marginBottom: 20 }}>
            <Text style={{ fontSize: 24, fontWeight: 'bold', color: textPrimary, marginBottom: 4 }}>
              {user?.name || 'Usuário'}
            </Text>
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
              <Text style={{ fontSize: 14, color: textSecondary }}>{user?.email}</Text>
            </View>
            <View style={{ flexDirection: 'row', alignItems: 'center', marginTop: 8, gap: 6, backgroundColor: `${roleConfig.color}20`, paddingHorizontal: 12, paddingVertical: 4, borderRadius: 20 }}>
              <Text>{roleConfig.icon}</Text>
              <Text style={{ fontSize: 12, fontWeight: '600', color: roleConfig.color }}>{roleConfig.label}</Text>
            </View>
          </View>

          {user?.phone && (
            <View style={{ backgroundColor: cardBg, borderRadius: 12, padding: 16, marginBottom: 16, flexDirection: 'row', alignItems: 'center', gap: 12 }}>
              <View style={{ width: 40, height: 40, borderRadius: 20, backgroundColor: '#3B82F620', alignItems: 'center', justifyContent: 'center' }}>
                <Text>📱</Text>
              </View>
              <View>
                <Text style={{ fontSize: 12, color: textSecondary }}>Telefone</Text>
                <Text style={{ fontSize: 14, color: textPrimary, fontWeight: '500' }}>{user.phone}</Text>
              </View>
            </View>
          )}

          <View style={{ marginBottom: 20 }}>
            <Text style={{ fontSize: 16, fontWeight: '600', color: textPrimary, marginBottom: 12 }}>Estatísticas</Text>
            <View style={{ flexDirection: 'row', gap: 10 }}>
              {[
                { icon: '📅', value: '0', label: 'Escalas', color: '#008CFF' },
                { icon: '🎉', value: '0', label: 'Eventos', color: '#3B82F6' },
                { icon: '🙏', value: '0', label: 'Orações', color: '#10B981' },
              ].map((stat, index) => (
                <View key={index} style={{ flex: 1, backgroundColor: cardBg, borderRadius: 12, padding: 16, alignItems: 'center' }}>
                  <Text style={{ fontSize: 24 }}>{stat.icon}</Text>
                  <Text style={{ fontSize: 20, fontWeight: 'bold', color: stat.color, marginTop: 4 }}>{stat.value}</Text>
                  <Text style={{ fontSize: 11, color: textSecondary, marginTop: 2 }}>{stat.label}</Text>
                </View>
              ))}
            </View>
          </View>

          {user?.ministries && user.ministries.length > 0 && (
            <View style={{ marginBottom: 20 }}>
              <Text style={{ fontSize: 16, fontWeight: '600', color: textPrimary, marginBottom: 12 }}>Ministérios</Text>
              <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8 }}>
                {user.ministries.map((ministry) => (
                  <View key={ministry} style={{ backgroundColor: cardBg, paddingHorizontal: 12, paddingVertical: 6, borderRadius: 20, borderWidth: 1, borderColor: borderColor }}>
                    <Text style={{ fontSize: 13, color: textPrimary }}>{ministry}</Text>
                  </View>
                ))}
              </View>
            </View>
          )}

          <View style={{ marginBottom: 20 }}>
            <Text style={{ fontSize: 16, fontWeight: '600', color: textPrimary, marginBottom: 12 }}>Menu</Text>
            <View style={{ backgroundColor: cardBg, borderRadius: 16, overflow: 'hidden' }}>
              {menuItems.map((item, index) => (
                <TouchableOpacity
                  key={item.label}
                  onPress={() => handleMenuPress(item.action)}
                  style={{
                    flexDirection: 'row',
                    alignItems: 'center',
                    padding: 16,
                    borderBottomWidth: index < menuItems.length - 1 ? 1 : 0,
                    borderBottomColor: borderColor,
                  }}
                >
                  <View style={{ width: 40, height: 40, borderRadius: 12, backgroundColor: `${item.color}20`, alignItems: 'center', justifyContent: 'center' }}>
                    <Text style={{ fontSize: 18 }}>{item.icon}</Text>
                  </View>
                  <Text style={{ flex: 1, fontSize: 15, color: textPrimary, marginLeft: 12 }}>{item.label}</Text>
                  {'badge' in item && item.badge && (
                    <View style={{ backgroundColor: '#EF4444', borderRadius: 10, paddingHorizontal: 8, paddingVertical: 2, marginRight: 8 }}>
                      <Text style={{ fontSize: 11, color: '#FFFFFF', fontWeight: '600' }}>{item.badge}</Text>
                    </View>
                  )}
                  <Text style={{ fontSize: 20, color: textSecondary }}>›</Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>

          <View style={{ marginBottom: 20 }}>
            <Text style={{ fontSize: 16, fontWeight: '600', color: textPrimary, marginBottom: 12 }}>Preferências</Text>
            <View style={{ backgroundColor: cardBg, borderRadius: 16, overflow: 'hidden' }}>
              <TouchableOpacity
                onPress={toggleTheme}
                style={{ flexDirection: 'row', alignItems: 'center', padding: 16 }}
              >
                <View style={{ width: 40, height: 40, borderRadius: 12, backgroundColor: isDark ? '#F59E0B20' : '#6366F120', alignItems: 'center', justifyContent: 'center' }}>
                  <Text style={{ fontSize: 18 }}>{isDark ? '🌙' : '☀️'}</Text>
                </View>
                <Text style={{ flex: 1, fontSize: 15, color: textPrimary, marginLeft: 12 }}>Tema</Text>
                <Text style={{ fontSize: 14, color: '#008CFF', fontWeight: '500', marginRight: 8 }}>{isDark ? 'Escuro' : 'Claro'}</Text>
                <Text style={{ fontSize: 20, color: textSecondary }}>›</Text>
              </TouchableOpacity>
            </View>
          </View>

          <TouchableOpacity
            onPress={() => router.replace('/login')}
            style={{
              backgroundColor: '#EF444420',
              borderRadius: 16,
              padding: 16,
              flexDirection: 'row',
              alignItems: 'center',
              justifyContent: 'center',
              marginBottom: 40,
            }}
          >
            <Text style={{ fontSize: 18, marginRight: 8 }}>🚪</Text>
            <Text style={{ fontSize: 16, color: '#EF4444', fontWeight: '600' }}>Sair da Conta</Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </View>
  );
}