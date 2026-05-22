import { View, Text, TextInput, TouchableOpacity, StyleSheet, ScrollView, Alert, FlatList, Switch } from 'react-native';
import { useState, useEffect } from 'react';
import { router, useNavigation } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useColorScheme } from '../../../src/hooks/useColorScheme';
import { useAuth } from '../../../src/hooks/useAuth';
import { schedulesService } from '../../../src/services/schedules';
import { usersService } from '../../../src/services/users';
import type { UserResponse } from '../../../src/services/users';

export default function CreateScheduleScreen() {
  const { isDark } = useColorScheme();
  const { user } = useAuth();
  const insets = useSafeAreaInsets();
  const navigation = useNavigation();
  const [title, setTitle] = useState('');
  const [date, setDate] = useState('');
  const [startTime, setStartTime] = useState('');
  const [endTime, setEndTime] = useState('');
  const [loading, setLoading] = useState(false);
  
  const [search, setSearch] = useState('');
  const [users, setUsers] = useState<UserResponse[]>([]);
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());

  useEffect(() => {
    const parent = navigation.getParent();
    if (parent) parent.setOptions({ tabBarStyle: { display: 'none' } });
    return () => { if (parent) parent.setOptions({ tabBarStyle: { display: 'flex' } }); };
  }, [navigation]);

  useEffect(() => {
    usersService.getAll().then(setUsers).catch(() => {});
  }, []);

  const toggleMember = (id: string) => {
    setSelectedIds(prev => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const handleSubmit = async () => {
    if (!title.trim() || !date || !startTime || !endTime) {
      Alert.alert('Erro', 'Preencha todos os campos');
      return;
    }
    setLoading(true);
    try {
      await schedulesService.create({
        title: title.trim(),
        date,
        startTime,
        endTime,
        createdById: user?.id,
        status: 'AGENDADO',
        memberIds: Array.from(selectedIds),
      } as any);
      Alert.alert('✅', 'Escala criada com sucesso!', [
        { text: 'OK', onPress: () => router.back() }
      ]);
    } catch (error: any) {
      Alert.alert('Erro', error?.message || 'Falha ao criar');
    } finally {
      setLoading(false);
    }
  };

  const bgColor = isDark ? '#0A0A0F' : '#F8FAFC';
  const cardBg = isDark ? '#1A1A2E' : '#FFFFFF';
  const textPrimary = isDark ? '#F9FAFB' : '#111827';
  const textSecondary = isDark ? '#9CA3AF' : '#6B7280';
  const borderColor = isDark ? '#1F2937' : '#E5E7EB';

  const filteredUsers = users.filter(u => 
    u.name.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <View style={[styles.container, { backgroundColor: bgColor, paddingTop: insets.top }]}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}>
          <Text style={[styles.backText, { color: textPrimary }]}>←</Text>
        </TouchableOpacity>
        <Text style={[styles.title, { color: textPrimary }]}>Nova Escala</Text>
        <View style={{ width: 40 }} />
      </View>

      <ScrollView contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">
        <View style={[styles.card, { backgroundColor: cardBg }]}>
          <Text style={[styles.label, { color: textSecondary }]}>Título</Text>
          <TextInput
            value={title}
            onChangeText={setTitle}
            placeholder="Ex: Culto de Domingo"
            placeholderTextColor={textSecondary}
            style={[styles.input, { color: textPrimary, borderColor }]}
          />
        </View>

        <View style={[styles.card, { backgroundColor: cardBg }]}>
          <Text style={[styles.label, { color: textSecondary }]}>Data</Text>
          <TextInput
            value={date}
            onChangeText={setDate}
            placeholder="YYYY-MM-DD"
            placeholderTextColor={textSecondary}
            style={[styles.input, { color: textPrimary, borderColor }]}
          />
        </View>

        <View style={styles.row}>
          <View style={[styles.card, styles.half, { backgroundColor: cardBg }]}>
            <Text style={[styles.label, { color: textSecondary }]}>Início</Text>
            <TextInput
              value={startTime}
              onChangeText={setStartTime}
              placeholder="HH:MM"
              placeholderTextColor={textSecondary}
              style={[styles.input, { color: textPrimary, borderColor }]}
            />
          </View>
          <View style={[styles.card, styles.half, { backgroundColor: cardBg }]}>
            <Text style={[styles.label, { color: textSecondary }]}>Fim</Text>
            <TextInput
              value={endTime}
              onChangeText={setEndTime}
              placeholder="HH:MM"
              placeholderTextColor={textSecondary}
              style={[styles.input, { color: textPrimary, borderColor }]}
            />
          </View>
        </View>

        <View style={[styles.card, { backgroundColor: cardBg }]}>
          <Text style={[styles.label, { color: textSecondary }]}>
            Membros Escalados ({selectedIds.size})
          </Text>
          <TextInput
            value={search}
            onChangeText={setSearch}
            placeholder="Buscar membro..."
            placeholderTextColor={textSecondary}
            style={[styles.input, { color: textPrimary, borderColor, marginBottom: 12 }]}
          />
          
          <View style={styles.membersList}>
            {filteredUsers.map(user => {
              const isSelected = selectedIds.has(user.id);
              return (
                <View key={user.id} style={[styles.memberRow, { borderColor }]}>
                  <View style={styles.memberInfo}>
                    <Text style={[styles.memberName, { color: textPrimary }]}>{user.name}</Text>
                    {user.role && (
                      <Text style={[styles.memberRole, { color: textSecondary }]}>{user.role}</Text>
                    )}
                  </View>
                  <Switch
                    value={isSelected}
                    onValueChange={() => toggleMember(user.id)}
                    trackColor={{ false: borderColor, true: '#008CFF80' }}
                    thumbColor={isSelected ? '#008CFF' : textSecondary}
                  />
                </View>
              );
            })}
          </View>
          
          {filteredUsers.length === 0 && (
            <Text style={{ color: textSecondary, textAlign: 'center', padding: 20 }}>Nenhum membro encontrado</Text>
          )}
        </View>

        <TouchableOpacity
          onPress={handleSubmit}
          disabled={loading || !title.trim() || !date || !startTime || !endTime}
          style={[styles.submitBtn, { backgroundColor: !title.trim() || !date || !startTime || !endTime ? '#6B7280' : '#008CFF' }]}
        >
          <Text style={styles.submitText}>{loading ? 'Criando...' : 'Criar Escala'}</Text>
        </TouchableOpacity>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  header: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 20, paddingVertical: 16 },
  backBtn: { width: 40, height: 40, alignItems: 'center', justifyContent: 'center' },
  backText: { fontSize: 28 },
  title: { fontSize: 18, fontWeight: '600' },
  content: { padding: 20, paddingBottom: 40 },
  card: { borderRadius: 16, padding: 16, marginBottom: 16 },
  half: { flex: 1, marginRight: 8 },
  row: { flexDirection: 'row', gap: 8 },
  label: { fontSize: 14, marginBottom: 10 },
  input: { fontSize: 16, borderWidth: 1, borderRadius: 12, padding: 14 },
  membersList: { maxHeight: 300 },
  memberRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingVertical: 12, borderBottomWidth: 1 },
  memberInfo: { flex: 1 },
  memberName: { fontSize: 15, fontWeight: '500' },
  memberRole: { fontSize: 12, marginTop: 2 },
  submitBtn: { borderRadius: 12, padding: 16, alignItems: 'center', marginTop: 10 },
  submitText: { fontSize: 16, fontWeight: '600', color: '#FFFFFF' },
});