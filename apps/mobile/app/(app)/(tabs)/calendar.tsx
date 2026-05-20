import { useState, useEffect, useCallback, useMemo } from 'react';
import { View, Text, SectionList, TouchableOpacity, RefreshControl } from 'react-native';
import { useRouter } from 'expo-router';
import { useColorScheme } from '../../../src/hooks/useColorScheme';
import { useAuth } from '../../../src/hooks/useAuth';
import { usePermission } from '../../../src/hooks/usePermission';
import { eventsService } from '../../../src/services/events';
import { FadeIn } from '../../../src/components/animations';
import { EventCard } from '../../../src/features/events/components/EventCard';
import type { Event } from '../../../src/types';

function getMonthName(year: number, month: number): string {
  return new Date(year, month - 1).toLocaleDateString('pt-BR', {
    month: 'long',
    year: 'numeric',
  });
}

function getMonthRange(year: number, month: number): { start: string; end: string } {
  const start = `${year}-${String(month).padStart(2, '0')}-01`;
  const lastDay = new Date(year, month, 0).getDate();
  const end = `${year}-${String(month).padStart(2, '0')}-${String(lastDay).padStart(2, '0')}`;
  return { start, end };
}

interface EventSection {
  title: string;
  data: Event[];
}

function groupEventsByDate(events: Event[]): EventSection[] {
  const grouped = new Map<string, Event[]>();
  events.forEach((event) => {
    const existing = grouped.get(event.date) || [];
    existing.push(event);
    grouped.set(event.date, existing);
  });
  return Array.from(grouped.entries())
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([date, items]) => ({
      title: new Date(date).toLocaleDateString('pt-BR', {
        weekday: 'long',
        day: 'numeric',
        month: 'long',
      }),
      data: items,
    }));
}

export default function Calendar() {
  const router = useRouter();
  const { isDark } = useColorScheme();
  const { canCreateEvent } = usePermission();
  const now = new Date();
  const [currentYear, setCurrentYear] = useState(now.getFullYear());
  const [currentMonth, setCurrentMonth] = useState(now.getMonth() + 1);
  const [events, setEvents] = useState<Event[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const monthRange = useMemo(
    () => getMonthRange(currentYear, currentMonth),
    [currentYear, currentMonth]
  );

  const loadEvents = useCallback(async () => {
    try {
      const response = await eventsService.getAll({
        startDate: monthRange.start,
        endDate: monthRange.end,
        limit: 100,
      });
      if (response.success) {
        setEvents(response.data.data);
      }
    } catch (error) {
      console.error('Error loading events:', error);
    } finally {
      setLoading(false);
    }
  }, [monthRange]);

  useEffect(() => {
    setLoading(true);
    loadEvents();
  }, [loadEvents]);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await loadEvents();
    setRefreshing(false);
  }, [loadEvents]);

  const changeMonth = useCallback((delta: number) => {
    let newMonth = currentMonth + delta;
    let newYear = currentYear;
    if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    } else if (newMonth < 1) {
      newMonth = 12;
      newYear--;
    }
    setCurrentMonth(newMonth);
    setCurrentYear(newYear);
  }, [currentMonth, currentYear]);

  const sections = useMemo(() => groupEventsByDate(events), [events]);

  return (
    <View style={{ flex: 1, backgroundColor: isDark ? '#0A0A0F' : '#FFFFFF', paddingHorizontal: 24 }}>
      <View style={{ paddingTop: 20, paddingBottom: 16 }}>
        <Text style={{ fontSize: 32, fontWeight: 'bold', color: isDark ? '#F9FAFB' : '#111827' }}>
          Agenda
        </Text>
      </View>

      <View
        style={{
          flexDirection: 'row',
          alignItems: 'center',
          justifyContent: 'space-between',
          marginBottom: 16,
          padding: 12,
          borderRadius: 16,
          backgroundColor: isDark ? '#1A1A2E' : '#F3F4F6',
        }}
      >
        <TouchableOpacity onPress={() => changeMonth(-1)} style={{ padding: 8 }}>
          <Text style={{ fontSize: 24, color: isDark ? '#F9FAFB' : '#111827' }}>‹</Text>
        </TouchableOpacity>
        <Text style={{ fontSize: 16, fontWeight: 'bold', color: isDark ? '#F9FAFB' : '#111827', textTransform: 'capitalize' }}>
          {getMonthName(currentYear, currentMonth)}
        </Text>
        <TouchableOpacity onPress={() => changeMonth(1)} style={{ padding: 8 }}>
          <Text style={{ fontSize: 24, color: isDark ? '#F9FAFB' : '#111827' }}>›</Text>
        </TouchableOpacity>
      </View>

      <SectionList
        sections={sections}
        keyExtractor={(item) => item.id}
        contentContainerStyle={{ paddingBottom: 100 }}
        showsVerticalScrollIndicator={false}
        renderSectionHeader={({ section: { title } }) => (
          <FadeIn direction="left" distance={10} duration={300}>
            <View style={{ paddingVertical: 8 }}>
              <Text style={{ fontSize: 14, fontWeight: 'bold', color: isDark ? '#9CA3AF' : '#6B7280', textTransform: 'uppercase' }}>
                {title}
              </Text>
            </View>
          </FadeIn>
        )}
        renderItem={({ item, index }) => (
          <EventCard event={item} index={index} onPress={() => router.push(`/(app)/events/${item.id}`)} />
        )}
        ListEmptyComponent={
          <View style={{ padding: 40, alignItems: 'center' }}>
            <Text style={{ fontSize: 48 }}>📅</Text>
            <Text style={{ fontSize: 18, fontWeight: 'bold', color: isDark ? '#F9FAFB' : '#111827', marginTop: 16 }}>
              Nenhum evento
            </Text>
            <Text style={{ fontSize: 14, color: isDark ? '#9CA3AF' : '#6B7280', marginTop: 8 }}>
              Não há eventos para este período
            </Text>
          </View>
        }
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={onRefresh}
            tintColor={isDark ? '#A78BFA' : '#7C3AED'}
            colors={['#7C3AED']}
            progressBackgroundColor={isDark ? '#1A1A2E' : '#FFFFFF'}
          />
        }
      />

      {canCreateEvent() && (
        <TouchableOpacity
          onPress={() => router.push('/(app)/events/create')}
          style={{
            position: 'absolute',
            right: 20,
            bottom: 100,
            width: 60,
            height: 60,
            borderRadius: 30,
            backgroundColor: '#8B5CF6',
            alignItems: 'center',
            justifyContent: 'center',
            shadowColor: '#8B5CF6',
            shadowOffset: { width: 0, height: 4 },
            shadowOpacity: 0.4,
            shadowRadius: 8,
            elevation: 8,
          }}
        >
          <Text style={{ fontSize: 28, color: '#FFFFFF', fontWeight: '300' }}>+</Text>
        </TouchableOpacity>
      )}
    </View>
  );
}