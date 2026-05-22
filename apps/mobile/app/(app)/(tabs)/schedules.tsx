import { useState, useEffect, useCallback } from 'react';
import { View, Text, FlatList, TouchableOpacity, RefreshControl, StyleSheet, Image } from 'react-native';
import { useRouter } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useColorScheme } from '../../../src/hooks/useColorScheme';
import { useAuth } from '../../../src/hooks/useAuth';
import { schedulesService } from '../../../src/services/schedules';
import type { Schedule, ScheduleStatus } from '../../../src/types';

const statusConfig: Record<ScheduleStatus, { label: string; color: string; bg: string }> = {
  AGENDADO: { label: 'Agendado', color: '#3B82F6', bg: '#3B82F615' },
  CONFIRMADO: { label: 'Confirmado', color: '#10B981', bg: '#10B98115' },
  EM_ANDAMENTO: { label: 'Em Andamento', color: '#008CFF', bg: '#008CFF15' },
  CONCLUIDO: { label: 'Concluído', color: '#6B7280', bg: '#6B728015' },
  CANCELADO: { label: 'Cancelado', color: '#EF4444', bg: '#EF444415' },
};

function formatDate(dateStr: string): string {
  const d = new Date(dateStr);
  return d.toLocaleDateString('pt-BR', { day: '2-digit', month: 'short', year: 'numeric' });
}

function formatTime(start: string, end: string): string {
  const fmt = (t: string) => t.substring(0, 5);
  return `${fmt(start)} - ${fmt(end)}`;
}

function ScheduleItem({ schedule, onPress }: { schedule: Schedule; onPress: () => void }) {
  const { isDark } = useColorScheme();
  const config = statusConfig[schedule.status];
  const confirmed = schedule.positions?.filter(p => p.status === 'CONFIRMADO').length || 0;
  const total = schedule.positions?.length || 0;

  return (
    <TouchableOpacity onPress={onPress} activeOpacity={0.7} style={[styles.card, { backgroundColor: isDark ? '#1A1A2E' : '#FFFFFF' }]}>
      <View style={styles.cardHeader}>
        <View style={styles.cardDate}>
          <Text style={[styles.cardDay, { color: isDark ? '#F9FAFB' : '#111827' }]}>
            {new Date(schedule.date).getDate()}
          </Text>
          <Text style={[styles.cardMonth, { color: isDark ? '#9CA3AF' : '#6B7280' }]}>
            {new Date(schedule.date).toLocaleDateString('pt-BR', { month: 'short' }).toUpperCase()}
          </Text>
        </View>
        <View style={[styles.statusBadge, { backgroundColor: config.bg }]}>
          <Text style={[styles.statusText, { color: config.color }]}>{config.label}</Text>
        </View>
      </View>

      <Text style={[styles.cardTime, { color: isDark ? '#9CA3AF' : '#6B7280' }]}>
        {formatTime(schedule.startTime, schedule.endTime)}
      </Text>

      {schedule.eventName && (
        <Text style={[styles.cardEvent, { color: isDark ? '#F9FAFB' : '#111827' }]} numberOfLines={1}>
          {schedule.eventName}
        </Text>
      )}

      {schedule.ministryName && (
        <View style={[styles.ministryTag, { backgroundColor: isDark ? '#008CFF20' : '#008CFF10' }]}>
          <Text style={[styles.ministryText, { color: '#008CFF' }]}>{schedule.ministryName}</Text>
        </View>
      )}

      {total > 0 && (
        <View style={[styles.cardFooter, { borderTopColor: isDark ? '#1F2937' : '#F3F4F6' }]}>
          <Text style={[styles.confirmedText, { color: isDark ? '#9CA3AF' : '#6B7280' }]}>
            {confirmed}/{total} confirmados
          </Text>
          <View style={styles.avatars}>
            {schedule.positions?.slice(0, 3).map((pos, i) => (
              <View key={pos.id} style={[styles.avatar, { marginLeft: i > 0 ? -8 : 0 }]}>
                <Text style={styles.avatarText}>{pos.memberName?.charAt(0) || '?'}</Text>
              </View>
            ))}
            {total > 3 && (
              <View style={[styles.moreAvatars, { backgroundColor: isDark ? '#374151' : '#E5E7EB' }]}>
                <Text style={[styles.moreText, { color: isDark ? '#9CA3AF' : '#6B7280' }]}>+{total - 3}</Text>
              </View>
            )}
          </View>
        </View>
      )}
    </TouchableOpacity>
  );
}

export default function Schedules() {
  const router = useRouter();
  const { isDark } = useColorScheme();
  const { user } = useAuth();
  const insets = useSafeAreaInsets();
  const [schedules, setSchedules] = useState<Schedule[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [activeTab, setActiveTab] = useState<'mine' | 'all'>('mine');

  const loadSchedules = useCallback(async () => {
    try {
      const res = await schedulesService.getAll({ limit: 50 });
      setSchedules(res.data);
    } catch {
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { loadSchedules(); }, [loadSchedules]);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await loadSchedules();
    setRefreshing(false);
  }, [loadSchedules]);

  const filteredSchedules = activeTab === 'mine' 
    ? schedules.filter(s => s.positions?.some(p => p.memberId === user?.id))
    : schedules;

  const upcomingCount = schedules.filter(s => s.status === 'AGENDADO' || s.status === 'CONFIRMADO').length;
  const myCount = schedules.filter(s => s.positions?.some(p => p.memberId === user?.id)).length;

  return (
    <View style={[styles.container, { backgroundColor: isDark ? '#0A0A0F' : '#F8FAFC' }]}>
      <View style={[styles.header, { paddingTop: insets.top + 20 }]}>
        <Text style={[styles.title, { color: isDark ? '#F9FAFB' : '#111827' }]}>Escalas</Text>
        <Text style={[styles.subtitle, { color: isDark ? '#9CA3AF' : '#6B7280' }]}>
          {upcomingCount} agendas próximas
        </Text>
      </View>

      <View style={styles.tabs}>
        <TouchableOpacity onPress={() => setActiveTab('mine')} style={[styles.tab, activeTab === 'mine' && styles.tabActive]}>
          <Text style={[styles.tabText, activeTab === 'mine' && styles.tabTextActive]}>
            Minhas ({myCount})
          </Text>
        </TouchableOpacity>
        <TouchableOpacity onPress={() => setActiveTab('all')} style={[styles.tab, activeTab === 'all' && styles.tabActive]}>
          <Text style={[styles.tabText, activeTab === 'all' && styles.tabTextActive]}>
            Todas ({schedules.length})
          </Text>
        </TouchableOpacity>
      </View>

      <FlatList
        data={filteredSchedules}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.list}
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor="#008CFF" />
        }
        renderItem={({ item }) => (
          <ScheduleItem 
            schedule={item} 
            onPress={() => router.push(`/(app)/(tabs)/schedule-detail?id=${item.id}`)}
          />
        )}
        ListEmptyComponent={
          <View style={styles.empty}>
            <Text style={styles.emptyIcon}>📋</Text>
            <Text style={[styles.emptyTitle, { color: isDark ? '#F9FAFB' : '#111827' }]}>
              Nenhuma escala
            </Text>
            <Text style={[styles.emptySubtitle, { color: isDark ? '#9CA3AF' : '#6B7280' }]}>
              {activeTab === 'mine' ? 'Você não está escalado' : 'Nenhuma escala encontrada'}
            </Text>
          </View>
        }
      />

      <TouchableOpacity
        onPress={() => router.push('/(app)/(tabs)/schedule-create')}
        style={[styles.fab, { bottom: insets.bottom + 20 }]}
      >
        <Image
          source={require('../../../assets/add.png')}
          style={{ width: 24, height: 24 }}
          resizeMode="contain"
        />
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  header: { paddingHorizontal: 20, paddingBottom: 16 },
  title: { fontSize: 32, fontWeight: 'bold' },
  subtitle: { fontSize: 14, marginTop: 4 },
  tabs: { flexDirection: 'row', paddingHorizontal: 20, marginBottom: 16, gap: 8 },
  tab: { flex: 1, paddingVertical: 10, borderRadius: 10, alignItems: 'center', backgroundColor: '#1A1A2E' },
  tabActive: { backgroundColor: '#008CFF' },
  tabText: { fontSize: 14, fontWeight: '600', color: '#9CA3AF' },
  tabTextActive: { color: '#FFFFFF' },
  list: { paddingHorizontal: 20, paddingBottom: 100 },
  card: { borderRadius: 16, padding: 16, marginBottom: 12, shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.1, shadowRadius: 8, elevation: 3 },
  cardHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 8 },
  cardDate: { alignItems: 'center' },
  cardDay: { fontSize: 24, fontWeight: 'bold' },
  cardMonth: { fontSize: 11, fontWeight: '600' },
  statusBadge: { paddingHorizontal: 10, paddingVertical: 4, borderRadius: 20 },
  statusText: { fontSize: 12, fontWeight: '600' },
  cardTime: { fontSize: 13, marginBottom: 8 },
  cardEvent: { fontSize: 16, fontWeight: '600', marginBottom: 8 },
  ministryTag: { alignSelf: 'flex-start', paddingHorizontal: 10, paddingVertical: 4, borderRadius: 12, marginBottom: 8 },
  ministryText: { fontSize: 12, fontWeight: '600' },
  cardFooter: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingTop: 12, borderTopWidth: 1 },
  confirmedText: { fontSize: 12 },
  avatars: { flexDirection: 'row' },
  avatar: { width: 28, height: 28, borderRadius: 14, backgroundColor: '#008CFF', alignItems: 'center', justifyContent: 'center' },
  avatarText: { fontSize: 12, fontWeight: 'bold', color: '#FFFFFF' },
  moreAvatars: { width: 28, height: 28, borderRadius: 14, alignItems: 'center', justifyContent: 'center', marginLeft: -8 },
  moreText: { fontSize: 10, fontWeight: '600' },
  empty: { alignItems: 'center', paddingTop: 60 },
  emptyIcon: { fontSize: 48 },
  emptyTitle: { fontSize: 18, fontWeight: '600', marginTop: 16 },
  emptySubtitle: { fontSize: 14, marginTop: 4 },
  fab: { position: 'absolute', right: 20, width: 56, height: 56, borderRadius: 12, backgroundColor: '#008CFF', alignItems: 'center', justifyContent: 'center', shadowColor: '#008CFF', shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.4, shadowRadius: 8, elevation: 6 },
  fabText: { fontSize: 28, color: '#FFFFFF', fontWeight: '600', textAlign: 'center', lineHeight: 27 },
});