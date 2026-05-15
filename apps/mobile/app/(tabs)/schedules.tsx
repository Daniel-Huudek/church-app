import { View, Text, StyleSheet, FlatList, TouchableOpacity, RefreshControl } from 'react-native';
import { useState, useEffect, useCallback } from 'react';
import { schedulesService, Schedule } from '../../services/schedules';

export default function Schedules() {
  const [schedules, setSchedules] = useState<Schedule[]>([]);
  const [refreshing, setRefreshing] = useState(false);
  const [page, setPage] = useState(1);

  const loadSchedules = useCallback(async (pageNum: number = 1) => {
    try {
      const response = await schedulesService.getAll({ page: pageNum, limit: 20 });
      if (response.success) {
        if (pageNum === 1) {
          setSchedules(response.data.data);
        } else {
          setSchedules(prev => [...prev, ...response.data.data]);
        }
      }
    } catch (error) {
      console.error('Error loading schedules:', error);
    }
  }, []);

  useEffect(() => {
    loadSchedules();
  }, [loadSchedules]);

  const onRefresh = async () => {
    setRefreshing(true);
    setPage(1);
    await loadSchedules(1);
    setRefreshing(false);
  };

  const loadMore = () => {
    const nextPage = page + 1;
    setPage(nextPage);
    loadSchedules(nextPage);
  };

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('pt-BR', { weekday: 'long', day: '2-digit', month: 'long' });
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Minhas Escalas</Text>
      <Text style={styles.subtitle}>{schedules.length} escala(s) encontrada(s)</Text>
      
      <FlatList
        data={schedules}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <View style={styles.scheduleCard}>
            <View style={styles.scheduleHeader}>
              <Text style={styles.scheduleDate}>{formatDate(item.date)}</Text>
              <View style={styles.timeBadge}>
                <Text style={styles.timeText}>{item.startTime} - {item.endTime}</Text>
              </View>
            </View>
            
            {item.positions && item.positions.length > 0 && (
              <View style={styles.positionsContainer}>
                <Text style={styles.positionsTitle}>Posições:</Text>
                {item.positions.map((pos, idx) => (
                  <View key={pos.id || idx} style={styles.positionItem}>
                    <Text style={styles.positionText}>• {pos.position}</Text>
                  </View>
                ))}
              </View>
            )}
          </View>
        )}
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Text style={styles.emptyTitle}>Nenhuma escala</Text>
            <Text style={styles.emptyText}>Você não tem escalas agendadas.</Text>
          </View>
        }
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
        onEndReached={loadMore}
        onEndReachedThreshold={0.5}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 16, backgroundColor: '#fff' },
  title: { fontSize: 24, fontWeight: 'bold', marginBottom: 4 },
  subtitle: { fontSize: 14, color: '#666', marginBottom: 16 },
  scheduleCard: { padding: 16, backgroundColor: '#f5f5f5', borderRadius: 8, marginBottom: 12 },
  scheduleHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 },
  scheduleDate: { fontSize: 16, fontWeight: '600' },
  timeBadge: { backgroundColor: '#2196F3', paddingHorizontal: 12, paddingVertical: 4, borderRadius: 12 },
  timeText: { fontSize: 12, color: '#fff', fontWeight: '600' },
  positionsContainer: { marginTop: 8 },
  positionsTitle: { fontSize: 14, fontWeight: '600', marginBottom: 8 },
  positionItem: { marginLeft: 8, marginBottom: 4 },
  positionText: { fontSize: 14, color: '#666' },
  emptyContainer: { alignItems: 'center', marginTop: 60 },
  emptyTitle: { fontSize: 18, fontWeight: '600', marginBottom: 8 },
  emptyText: { fontSize: 14, color: '#999', textAlign: 'center' },
});