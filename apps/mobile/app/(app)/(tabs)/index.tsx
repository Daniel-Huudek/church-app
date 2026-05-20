import { useState, useEffect, useCallback } from 'react';
import { View, Text, ScrollView, FlatList, RefreshControl } from 'react-native';
import { useRouter } from 'expo-router';
import { useAuth } from '../../../src/hooks/useAuth';
import { useColorScheme } from '../../../src/hooks/useColorScheme';
import { eventsService } from '../../../src/services/events';
import { schedulesService } from '../../../src/services/schedules';
import { prayersService } from '../../../src/services/prayers';
import {
  Button,
  Header,
  Card,
  Skeleton,
  EmptyState,
  Loading,
} from '../../../src/components/ui';
import { SlideUp } from '../../../src/components/animations';
import { EventCard } from '../../../src/features/events/components/EventCard';
import { ScheduleCard } from '../../../src/features/schedules/components/ScheduleCard';
import type { Event } from '../../../src/types';
import type { Schedule } from '../../../src/types';

interface DashboardStats {
  schedulesCount: number;
  eventsToday: number;
  prayersCount: number;
}

function calculateDashboardStats(
  events: Event[],
  schedules: Schedule[],
  prayersCount: number,
): DashboardStats {
  const today = new Date().toISOString().split('T')[0];
  const eventsToday = events.filter((e) => e.date === today).length;
  return {
    schedulesCount: schedules.length,
    eventsToday,
    prayersCount,
  };
}

export default function Dashboard() {
  const router = useRouter();
  const { user, hasRole } = useAuth();
  const { isDark, colors } = useColorScheme();
  const [events, setEvents] = useState<Event[]>([]);
  const [schedules, setSchedules] = useState<Schedule[]>([]);
  const [prayersCount, setPrayersCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const canAccessFinance = hasRole(['ADMINISTRADOR', 'PASTOR', 'FINANCEIRO']);

  const loadData = useCallback(async () => {
    try {
      const today = new Date().toISOString().split('T')[0];
      const endDate = new Date();
      endDate.setDate(endDate.getDate() + 30);
      const endStr = endDate.toISOString().split('T')[0];

      const [eventsRes, schedulesRes, prayersRes] = await Promise.all([
        eventsService.getAll({ startDate: today, endDate: endStr, limit: 10 }),
        schedulesService.getAll({ startDate: today, limit: 5 }),
        prayersService.list({ limit: 1 }),
      ]);

      if (eventsRes.success) {
        setEvents(eventsRes.data.data);
      }
      setSchedules(schedulesRes.data);
      if (prayersRes.success) {
        setPrayersCount(prayersRes.data.total);
      }
    } catch (error) {
      console.error('Error loading dashboard:', error);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await loadData();
    setRefreshing(false);
  }, [loadData]);

  const quickActionHandlers = {
    'nova-escala': () => router.push('/(app)/(tabs)/schedules'),
    'novo-evento': () => {},
    'pedido-oracao': () => router.push('/(app)/(tabs)/prayers/index'),
    'nova-transacao': () => router.push('/(app)/(tabs)/finance/index'),
  };

  const stats = calculateDashboardStats(events, schedules, prayersCount);

  const renderSkeleton = () => (
    <View
      className="flex-1 px-4 pt-16"
      style={{ backgroundColor: isDark ? '#0A0A0F' : '#FFFFFF' }}
    >
      <Skeleton variant="text" width="60%" height={28} className="mb-6" />
      <View className="flex-row mb-6 gap-3">
        <Skeleton variant="card" height={100} className="flex-1" />
        <Skeleton variant="card" height={100} className="flex-1" />
      </View>
    </View>
  );

  if (loading) {
    return renderSkeleton();
  }

  return (
    <View
      className="flex-1"
      style={{ backgroundColor: isDark ? '#0A0A0F' : '#FFFFFF' }}
    >
      <ScrollView
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={onRefresh}
            tintColor={isDark ? '#A78BFA' : '#7C3AED'}
            colors={['#7C3AED']}
            progressBackgroundColor={isDark ? '#1A1A2E' : '#FFFFFF'}
          />
        }
      ></ScrollView>
    </View>
  );
}
