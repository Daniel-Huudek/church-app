import { View, Text, StyleSheet, FlatList, TouchableOpacity, RefreshControl } from 'react-native';
import { useState, useEffect, useCallback } from 'react';
import { eventsService, Event } from '../../services/events';

export default function Calendar() {
  const [events, setEvents] = useState<Event[]>([]);
  const [refreshing, setRefreshing] = useState(false);
  const [selectedMonth, setSelectedMonth] = useState(new Date().toISOString().slice(0, 7));

  const loadEvents = useCallback(async () => {
    try {
      const [startDate, endDate] = selectedMonth.split('-').map((_, i) => {
        const year = selectedMonth.slice(0, 4);
        const month = selectedMonth.slice(5, 7);
        if (i === 0) return `${year}-${month}-01`;
        const lastDay = new Date(parseInt(year), parseInt(month), 0).getDate();
        return `${year}-${month}-${lastDay}`;
      });

      const response = await eventsService.getAll({ startDate, endDate });
      if (response.success) {
        setEvents(response.data.data);
      }
    } catch (error) {
      console.error('Error loading events:', error);
    }
  }, [selectedMonth]);

  useEffect(() => {
    loadEvents();
  }, [loadEvents]);

  const onRefresh = async () => {
    setRefreshing(true);
    await loadEvents();
    setRefreshing(false);
  };

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('pt-BR', { weekday: 'short', day: '2-digit', month: 'short' });
  };

  const getMonthName = () => {
    const [year, month] = selectedMonth.split('-');
    return new Date(parseInt(year), parseInt(month) - 1).toLocaleDateString('pt-BR', { month: 'long', year: 'numeric' });
  };

  const changeMonth = (delta: number) => {
    const date = new Date(selectedMonth + '-01');
    date.setMonth(date.getMonth() + delta);
    setSelectedMonth(date.toISOString().slice(0, 7));
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Calendário</Text>
      
      <View style={styles.monthSelector}>
        <TouchableOpacity onPress={() => changeMonth(-1)} style={styles.monthButton}>
          <Text>◀</Text>
        </TouchableOpacity>
        <Text style={styles.monthText}>{getMonthName()}</Text>
        <TouchableOpacity onPress={() => changeMonth(1)} style={styles.monthButton}>
          <Text>▶</Text>
        </TouchableOpacity>
      </View>

      <FlatList
        data={events}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <TouchableOpacity style={styles.eventCard}>
            <View style={styles.eventHeader}>
              <Text style={styles.eventDate}>{formatDate(item.date)}</Text>
              <Text style={styles.eventType}>{item.type}</Text>
            </View>
            <Text style={styles.eventTitle}>{item.title}</Text>
            {item.description && <Text style={styles.eventDesc} numberOfLines={2}>{item.description}</Text>}
            <Text style={styles.eventTime}>{item.time}</Text>
          </TouchableOpacity>
        )}
        ListEmptyComponent={<Text style={styles.emptyText}>Nenhum evento neste mês</Text>}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 16, backgroundColor: '#fff' },
  title: { fontSize: 24, fontWeight: 'bold', marginBottom: 16 },
  monthSelector: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 },
  monthButton: { padding: 10 },
  monthText: { fontSize: 18, fontWeight: '600' },
  eventCard: { padding: 16, backgroundColor: '#f5f5f5', borderRadius: 8, marginBottom: 12 },
  eventHeader: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 8 },
  eventDate: { fontSize: 12, color: '#666' },
  eventType: { fontSize: 12, color: '#2196F3', fontWeight: '600' },
  eventTitle: { fontSize: 16, fontWeight: '600', marginBottom: 4 },
  eventDesc: { fontSize: 14, color: '#666', marginBottom: 4 },
  eventTime: { fontSize: 12, color: '#999' },
  emptyText: { fontSize: 14, color: '#999', textAlign: 'center', marginVertical: 40 },
});