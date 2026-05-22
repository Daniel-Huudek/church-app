import { useState, useEffect, useCallback } from 'react';
import { View, Text, ScrollView, TouchableOpacity, TextInput, Alert } from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { useColorScheme } from '../../../src/hooks/useColorScheme';
import { usersService } from '../../../src/services/users';

interface User {
  id: string;
  email: string;
  name: string;
  role: string;
  permissions?: string[];
}

const ROLES = [
  { value: 'ADMINISTRADOR', label: 'Administrador', color: '#EF4444' },
  { value: 'PASTOR', label: 'Pastor', color: '#008CFF' },
  { value: 'FINANCEIRO', label: 'Financeiro', color: '#3B82F6' },
  { value: 'LIDER', label: 'Líder', color: '#F59E0B' },
  { value: 'MEMBRO', label: 'Membro', color: '#10B981' },
  { value: 'VISITANTE', label: 'Visitante', color: '#6B7280' },
];

const ALL_PERMISSIONS = [
  { key: 'events_read', label: 'Ver Eventos' },
  { key: 'events_write', label: 'Criar/Editar Eventos' },
  { key: 'events_delete', label: 'Excluir Eventos' },
  { key: 'members_read', label: 'Ver Membros' },
  { key: 'members_write', label: 'Criar/Editar Membros' },
  { key: 'members_delete', label: 'Excluir Membros' },
  { key: 'prayers_read', label: 'Ver Orações' },
  { key: 'prayers_write', label: 'Criar/Editar Orações' },
  { key: 'prayers_delete', label: 'Excluir Orações' },
  { key: 'finance_read', label: 'Ver Finanças' },
  { key: 'finance_write', label: 'Criar/Editar Finanças' },
  { key: 'finance_delete', label: 'Excluir Finanças' },
];

export default function EditUser() {
  const router = useRouter();
  const { id } = useLocalSearchParams<{ id: string }>();
  const { isDark } = useColorScheme();

  const [user, setUser] = useState<User | null>(null);
  const [role, setRole] = useState('');
  const [permissions, setPermissions] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  const togglePermission = (key: string) => {
    setPermissions(prev => 
      prev.includes(key) 
        ? prev.filter(p => p !== key)
        : [...prev, key]
    );
  };

  useEffect(() => {
    loadUser();
  }, [id]);

  const loadUser = async () => {
    try {
      const data = await usersService.getById(id);
      setUser(data);
      setRole(data.role);
      setPermissions(data.permissions || []);
    } catch (error) {
      Alert.alert('Erro', 'Falha ao carregar usuário');
      router.back();
    } finally {
      setLoading(false);
    }
  };

  

  const handleSave = useCallback(async () => {
    if (!user) return;
    
    setSaving(true);
    try {
      await usersService.updatePermissions(id, permissions);
      await usersService.updateRole(id, role);
      Alert.alert('Sucesso', 'Usuário atualizado!', [
        { text: 'OK', onPress: () => router.push('/(app)/users') }
      ]);
    } catch (error: any) {
      Alert.alert('Erro', error?.message || 'Falha ao salvar');
    } finally {
      setSaving(false);
    }
  }, [id, role, permissions, router]);

  if (loading || !user) {
    return (
      <View style={{ flex: 1, backgroundColor: isDark ? '#0A0A0F' : '#F8FAFC', alignItems: 'center', justifyContent: 'center' }}>
        <Text style={{ color: isDark ? '#F9FAFB' : '#111827' }}>Carregando...</Text>
      </View>
    );
  }

  const bgColor = isDark ? '#0A0A0F' : '#F8FAFC';
  const cardBg = isDark ? '#1A1A2E' : '#FFFFFF';
  const textPrimary = isDark ? '#F9FAFB' : '#111827';
  const textSecondary = isDark ? '#9CA3AF' : '#6B7280';
  const borderColor = isDark ? '#1F2937' : '#E5E7EB';

  return (
    <View style={{ flex: 1, backgroundColor: bgColor }}>
      <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 20, paddingTop: 50, paddingBottom: 16 }}>
        <TouchableOpacity onPress={() => router.back()}>
          <Text style={{ fontSize: 24, color: textPrimary }}>←</Text>
        </TouchableOpacity>
        <Text style={{ fontSize: 20, fontWeight: 'bold', color: textPrimary }}>Editar Usuário</Text>
        <View style={{ width: 30 }} />
      </View>

      <ScrollView showsVerticalScrollIndicator={false} style={{ flex: 1, paddingHorizontal: 20 }}>
        <View style={{ backgroundColor: cardBg, borderRadius: 16, padding: 16, marginBottom: 20, borderWidth: 1, borderColor }}>
          <Text style={{ fontSize: 16, fontWeight: '600', color: textPrimary, marginBottom: 4 }}>{user.name}</Text>
          <Text style={{ fontSize: 14, color: textSecondary }}>{user.email}</Text>
        </View>

        <Text style={{ fontSize: 16, fontWeight: '600', color: textPrimary, marginBottom: 12 }}>Função</Text>
        <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginBottom: 24 }}>
          {ROLES.map((r) => (
            <TouchableOpacity
              key={r.value}
              onPress={() => setRole(r.value)}
              style={{
                backgroundColor: role === r.value ? r.color : cardBg,
                paddingHorizontal: 16,
                paddingVertical: 10,
                borderRadius: 20,
                borderWidth: 1,
                borderColor: role === r.value ? r.color : borderColor,
              }}
            >
              <Text style={{ fontSize: 14, color: role === r.value ? '#FFFFFF' : textPrimary }}>{r.label}</Text>
            </TouchableOpacity>
          ))}
        </View>

        <Text style={{ fontSize: 16, fontWeight: '600', color: textPrimary, marginBottom: 12 }}>Permissões</Text>
        <View style={{ backgroundColor: cardBg, borderRadius: 16, padding: 16, marginBottom: 40, borderWidth: 1, borderColor }}>
          {['events', 'members', 'prayers', 'finance'].map((resource) => (
            <View key={resource} style={{ marginBottom: 16 }}>
              <Text style={{ fontSize: 14, fontWeight: '600', color: textPrimary, marginBottom: 8, textTransform: 'uppercase' }}>{resource}</Text>
              <View style={{ flexDirection: 'row', gap: 16 }}>
                {['read', 'write', 'delete'].map((action) => {
                  const permKey = `${resource}_${action}`;
                  const isActive = permissions.includes(permKey);
                  return (
                    <TouchableOpacity
                      key={permKey}
                      onPress={() => togglePermission(permKey)}
                      style={{ flexDirection: 'row', alignItems: 'center' }}
                    >
                      <View style={{ 
                        width: 20, 
                        height: 20, 
                        borderRadius: 4, 
                        borderWidth: 2, 
                        borderColor: isActive ? '#008CFF' : borderColor,
                        backgroundColor: isActive ? '#008CFF' : 'transparent',
                        marginRight: 6,
                      }}>
                        {isActive && <Text style={{ color: '#FFF', fontSize: 12, textAlign: 'center' }}>✓</Text>}
                      </View>
                      <Text style={{ fontSize: 14, color: textPrimary }}>{action}</Text>
                    </TouchableOpacity>
                  );
                })}
              </View>
            </View>
          ))}
        </View>

        <TouchableOpacity
          onPress={handleSave}
          disabled={saving}
          style={{ backgroundColor: '#008CFF', borderRadius: 12, padding: 16, alignItems: 'center', marginBottom: 40 }}
        >
          <Text style={{ fontSize: 16, fontWeight: '600', color: '#FFFFFF' }}>
            {saving ? 'Salvando...' : 'Salvar Alterações'}
          </Text>
        </TouchableOpacity>
      </ScrollView>
    </View>
  );
}