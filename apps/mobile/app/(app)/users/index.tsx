import { useState, useEffect, useCallback } from 'react';
import { View, Text, ScrollView, TouchableOpacity, RefreshControl, Alert, TextInput } from 'react-native';
import { useRouter } from 'expo-router';
import { useColorScheme } from '../../../src/hooks/useColorScheme';
import { usePermission } from '../../../src/hooks/usePermission';
import { useAuthStore } from '../../../src/store/auth';
import { API_URL } from '../../../src/services/api';

interface User {
  id: string;
  email: string;
  name: string;
  role: string;
  permissions?: string[];
  avatar?: string;
  createdAt: string;
}

const roleLabels: Record<string, { label: string; color: string }> = {
  ADMINISTRADOR: { label: 'Admin', color: '#EF4444' },
  PASTOR: { label: 'Pastor', color: '#008CFF' },
  FINANCEIRO: { label: 'Financeiro', color: '#3B82F6' },
  LIDER: { label: 'Líder', color: '#F59E0B' },
  MEMBRO: { label: 'Membro', color: '#10B981' },
  VISITANTE: { label: 'Visitante', color: '#6B7280' },
};

export default function UsersScreen() {
  const router = useRouter();
  const { isDark } = useColorScheme();
  const { canEditEvent } = usePermission();
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [search, setSearch] = useState('');

  const loadUsers = useCallback(async () => {
    try {
      const token = useAuthStore.getState().accessToken;
      
      if (!token) {
        Alert.alert('Erro', 'Você precisa estar logado para acessar esta página');
        return;
      }
      
      const response = await fetch(`${API_URL}/users`, {
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        }
      });
      const json = await response.json();
      if (json.success) {
        setUsers(json.data);
      } else {
        Alert.alert('Erro', json.message || 'Falha ao carregar');
      }
    } catch (error: any) {
      Alert.alert('Erro', 'Falha ao carregar usuários: ' + (error?.message || 'Erro desconhecido'));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadUsers();
  }, [loadUsers]);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await loadUsers();
    setRefreshing(false);
  }, [loadUsers]);

  const handleUserPress = (user: User) => {
    router.push(`/(app)/users/edit?id=${user.id}`);
  };

  const bgColor = isDark ? '#0A0A0F' : '#F8FAFC';
  const cardBg = isDark ? '#1A1A2E' : '#FFFFFF';
  const textPrimary = isDark ? '#F9FAFB' : '#111827';
  const textSecondary = isDark ? '#9CA3AF' : '#6B7280';
  const borderColor = isDark ? '#1F2937' : '#E5E7EB';

  const getInitials = (name: string) => {
    return name.split(' ').filter(Boolean).slice(0, 2).map(n => n[0]).join('').toUpperCase();
  };

  const filteredUsers = users.filter(user => 
    user.email.toLowerCase().includes(search.toLowerCase()) ||
    user.name.toLowerCase().includes(search.toLowerCase())
  );

  if (loading) {
    return (
      <View style={{ flex: 1, backgroundColor: bgColor, alignItems: 'center', justifyContent: 'center' }}>
        <Text style={{ color: textSecondary }}>Carregando...</Text>
      </View>
    );
  }

  return (
    <View style={{ flex: 1, backgroundColor: bgColor }}>
      <View style={{ flexDirection: 'row', alignItems: 'center', paddingHorizontal: 20, paddingTop: 50, paddingBottom: 16 }}>
        <TouchableOpacity onPress={() => router.navigate('/(app)')}>
          <Text style={{ fontSize: 24, color: textPrimary }}>☰</Text>
        </TouchableOpacity>
        <Text style={{ fontSize: 28, fontWeight: 'bold', color: textPrimary, marginLeft: 16 }}>Users</Text>
      </View>
      <View style={{ paddingHorizontal: 20, marginBottom: 8 }}>
        <Text style={{ fontSize: 14, color: textSecondary }}>{filteredUsers.length} de {users.length} usuários</Text>
      </View>

      <View style={{ paddingHorizontal: 20, marginBottom: 16 }}>
        <TextInput
          value={search}
          onChangeText={setSearch}
          placeholder="Buscar por email..."
          placeholderTextColor={textSecondary}
          style={{
            backgroundColor: cardBg,
            borderRadius: 12,
            paddingHorizontal: 16,
            paddingVertical: 12,
            fontSize: 15,
            color: textPrimary,
            borderWidth: 1,
            borderColor: borderColor,
          }}
        />
      </View>

      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={{ paddingHorizontal: 20, paddingBottom: 40 }}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={onRefresh}
            tintColor={isDark ? '#66B5FF' : '#0066CC'}
          />
        }
      >
        {filteredUsers.map((user) => {
          const roleConfig = roleLabels[user.role] || roleLabels.MEMBRO;
          
          return (
            <TouchableOpacity
              key={user.id}
              onPress={() => handleUserPress(user)}
              style={{
                backgroundColor: cardBg,
                borderRadius: 16,
                padding: 16,
                marginBottom: 12,
                flexDirection: 'row',
                alignItems: 'center',
                borderWidth: 1,
                borderColor: borderColor,
              }}
            >
              <View style={{ width: 48, height: 48, borderRadius: 24, backgroundColor: '#008CFF', alignItems: 'center', justifyContent: 'center' }}>
                <Text style={{ fontSize: 18, fontWeight: 'bold', color: '#FFFFFF' }}>{getInitials(user.name)}</Text>
              </View>
              
              <View style={{ flex: 1, marginLeft: 12 }}>
                <Text style={{ fontSize: 16, fontWeight: '600', color: textPrimary }}>{user.name}</Text>
                <Text style={{ fontSize: 13, color: textSecondary, marginTop: 2 }}>{user.email}</Text>
                <View style={{ flexDirection: 'row', marginTop: 8, gap: 6 }}>
                  <View style={{ backgroundColor: `${roleConfig.color}20`, paddingHorizontal: 10, paddingVertical: 2, borderRadius: 10 }}>
                    <Text style={{ fontSize: 12, color: roleConfig.color, fontWeight: '500' }}>{roleConfig.label}</Text>
                  </View>
                  {user.permissions && user.permissions.length > 0 && (
                    <View style={{ backgroundColor: '#3B82F620', paddingHorizontal: 10, paddingVertical: 2, borderRadius: 10 }}>
                      <Text style={{ fontSize: 12, color: '#3B82F6' }}>{user.permissions.length} permissões</Text>
                    </View>
                  )}
                </View>
              </View>
              
              <Text style={{ fontSize: 20, color: textSecondary }}>›</Text>
            </TouchableOpacity>
          );
        })}

        {filteredUsers.length === 0 && (
          <View style={{ padding: 40, alignItems: 'center' }}>
            <Text style={{ fontSize: 48 }}>👥</Text>
            <Text style={{ fontSize: 18, fontWeight: 'bold', color: textPrimary, marginTop: 16 }}>
              {search ? 'Nenhum usuário encontrado' : 'Nenhum usuário'}
            </Text>
          </View>
        )}
      </ScrollView>
    </View>
  );
}