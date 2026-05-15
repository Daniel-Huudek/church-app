import { View, Text, StyleSheet, FlatList, TouchableOpacity, RefreshControl } from 'react-native';
import { useState, useEffect, useCallback } from 'react';
import { useAuthStore } from '../../store/auth';
import { eventsService, Event } from '../../services/events';
import { schedulesService, Schedule } from '../../services/schedules';

export default function Dashboard() {
  const { user } = useAuthStore();
  const [events, setEvents] = useState<Event[]>([]);
  const [schedules, setSchedules] = useState<Schedule[]>([]);
  const [refreshing, setRefreshing] = useState(false);

  const loadData = useCallback(async () => {
    try {
      const today = new Date().toISOString().split('T')[0];
      const eventsRes = await eventsService.getAll({ startDate: today, limit: 5 });
      if (eventsRes.success) {
        setEvents(eventsRes.data.data);
      }
      const schedulesRes = await schedulesService.getAll({ limit: 5 });
      if (schedulesRes.success) {
        setSchedules(schedulesRes.data.data);
      }
    } catch (error) {
      console.error('Error loading data:', error);
    }
  }, []);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const onRefresh = async () => {
    setRefreshing(true);
    await loadData();
    setRefreshing(false);
  };

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('pt-BR', { day: '2-digit', month: 'short' });
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Bem-vindo, {user?.name || 'Membro'}!</Text>
      
      <Text style={styles.sectionTitle}>Próximos Eventos</Text>
      <FlatList
        data={events}
        keyExtractor={(item) => item.id}
        horizontal
        showsHorizontalScrollIndicator={false}
        renderItem={({ item }) => (
          <TouchableOpacity style={styles.eventCard}>
            <Text style={styles.eventDate}>{formatDate(item.date)}</Text>
            <Text style={styles.eventTitle} numberOfLines={1}>{item.title}</Text>
            <Text style={styles.eventType}>{item.time}</Text>
          </TouchableOpacity>
        )}
        ListEmptyComponent={<Text style={styles.emptyText}>Nenhum evento próximo</Text>}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
      />

      <Text style={styles.sectionTitle}>Suas Escalas</Text>
      <FlatList
        data={schedules}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <View style={styles.scheduleCard}>
            <Text style={styles.scheduleDate}>{formatDate(item.date)}</Text>
            <Text style={styles.scheduleTime}>{item.startTime} - {item.endTime}</Text>
            <Text style={styles.schedulePositions}>
              {item.positions?.length || 0} posições
            </Text>
          </View>
        )}
        ListEmptyComponent={<Text style={styles.emptyText}>Nenhuma escala próxima</Text>}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 16, backgroundColor: '#fff' },
  title: { fontSize: 24, fontWeight: 'bold', marginBottom: 20 },
  sectionTitle: { fontSize: 18, fontWeight: '600', marginBottom: 12, marginTop: 8 },
  eventCard: { width: 120, padding: 12, backgroundColor: '#f5f5f5', borderRadius: 8, marginRight: 12 },
  eventDate: { fontSize: 12, color: '#666', marginBottom: 4 },
  eventTitle: { fontSize: 14, fontWeight: '600', marginBottom: 4 },
  eventType: { fontSize: 12, color: '#999' },
  scheduleCard: { padding: 12, backgroundColor: '#f5f5f5', borderRadius: 8, marginBottom: 8 },
  scheduleDate: { fontSize: 14, fontWeight: '600', marginBottom: 4 },
  scheduleTime: { fontSize: 12, color: '#666', marginBottom: 4 },
  schedulePositions: { fontSize: 12, color: '#999' },
  emptyText: { fontSize: 14, color: '#999', textAlign: 'center', marginVertical: 20 },
});