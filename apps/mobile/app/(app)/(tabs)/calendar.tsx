import { useState, useEffect, useCallback, useMemo } from 'react';
import { View, Text, SectionList, TouchableOpacity, RefreshControl } from 'react-native';
import { useRouter } from 'expo-router';
import { useColorScheme } from '../../../src/hooks/useColorScheme';
import { eventsService } from '../../../src/services/events';
import { Header, Skeleton, EmptyState } from '../../../src/components/ui';
import { FadeIn } from '../../../src/components/animations';
import { EventCard } from '../../../src/features/events/components/EventCard';
import { EventFilter } from '../../../src/features/events/components/EventFilter';
import type { Event, EventFilter as EventFilterType } from '../../../src/types';

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
  const now = new Date();
  const [currentYear, setCurrentYear] = useState(now.getFullYear());
  const [currentMonth, setCurrentMonth] = useState(now.getMonth() + 1);
  const [events, setEvents] = useState<Event[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [filters, setFilters] = useState<EventFilterType>({});

  const monthRange = useMemo(
    () => getMonthRange(currentYear, currentMonth),
    [currentYear, currentMonth]
  );

  const loadEvents = useCallback(async () => {
    try {
      const response = await eventsService.getAll({
        ...filters,
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
  }, [monthRange, filters]);

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

  const handleFilterChange = useCallback((newFilters: EventFilterType) => {
    setFilters(newFilters);
  }, []);

  const sections = useMemo(() => groupEventsByDate(events), [events]);

  const renderSkeleton = () => (
    <View className="flex-1 px-4 pt-20" style={{ backgroundColor: isDark ? '#0A0A0F' : '#FFFFFF' }}>
      <Skeleton variant="text" width="40%" height={28} className="mb-4" />
      <Skeleton variant="text" width="60%" height={20} className="mb-6" />
      <Skeleton variant="card" height={160} className="mb-3" />
      <Skeleton variant="card" height={160} className="mb-3" />
      <Skeleton variant="card" height={160} className="mb-3" />
    </View>
  );

  if (loading) {
    return renderSkeleton();
  }

  return (
    <View className="flex-1" style={{ backgroundColor: isDark ? '#0A0A0F' : '#FFFFFF' }}>
      <Header
        title="Agenda"
        largeTitle
      />

      <View
        className="mx-6 mb-4 rounded-2xl p-2 flex-row items-center justify-between"
        style={{
          backgroundColor: isDark ? '#1A1A2E' : '#F3F4F6',
        }}
      >
        <TouchableOpacity
          onPress={() => changeMonth(-1)}
          className="w-10 h-10 rounded-full items-center justify-center"
          activeOpacity={0.7}
          style={{
            backgroundColor: isDark ? '#12121A' : '#FFFFFF',
          }}
        >
          <Text
            className="text-lg font-bold"
            style={{ color: isDark ? '#F9FAFB' : '#111827' }}
          >
            ‹
          </Text>
        </TouchableOpacity>

        <Text
          className="text-base font-bold capitalize"
          style={{ color: isDark ? '#F9FAFB' : '#111827' }}
        >
          {getMonthName(currentYear, currentMonth)}
        </Text>

        <TouchableOpacity
          onPress={() => changeMonth(1)}
          className="w-10 h-10 rounded-full items-center justify-center"
          activeOpacity={0.7}
          style={{
            backgroundColor: isDark ? '#12121A' : '#FFFFFF',
          }}
        >
          <Text
            className="text-lg font-bold"
            style={{ color: isDark ? '#F9FAFB' : '#111827' }}
          >
            ›
          </Text>
        </TouchableOpacity>
      </View>

      <EventFilter filters={filters} onChange={handleFilterChange} />

      <SectionList
        sections={sections}
        keyExtractor={(item) => item.id}
        contentContainerStyle={{
          paddingHorizontal: 20,
          paddingBottom: 40,
        }}
        showsVerticalScrollIndicator={false}
        renderSectionHeader={({ section: { title } }) => (
          <FadeIn direction="left" distance={10} duration={300}>
            <View className="pt-4 pb-2">
              <Text
                className="text-sm font-bold uppercase tracking-wider"
                style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}
              >
                {title}
              </Text>
            </View>
          </FadeIn>
        )}
        renderItem={({ item, index }) => (
          <EventCard
            event={item}
            index={index}
            onPress={() => {}}
          />
        )}
        ListEmptyComponent={
          <FadeIn direction="up" distance={20}>
            <EmptyState
              icon={<Text className="text-5xl">📅</Text>}
              title="Nenhum evento"
              subtitle="Não há eventos para este período"
            />
          </FadeIn>
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
    </View>
  );
}
