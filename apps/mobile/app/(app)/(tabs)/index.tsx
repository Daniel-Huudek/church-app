import { useState, useEffect, useCallback } from 'react';
import { View, Text, ScrollView, FlatList, RefreshControl } from 'react-native';
import { useRouter } from 'expo-router';
import { useAuth } from '../../../src/hooks/useAuth';
import { useColorScheme } from '../../../src/hooks/useColorScheme';
import { eventsService } from '../../../src/services/events';
import { schedulesService } from '../../../src/services/schedules';
import { prayersService } from '../../../src/services/prayers';
import { Button, Header, Card, Skeleton, EmptyState, Loading } from '../../../src/components/ui';
import { FadeIn, SlideUp } from '../../../src/components/animations';
import { DashboardCard } from '../../../src/features/dashboard/components/DashboardCard';
import { QuickActions } from '../../../src/features/dashboard/components/QuickActions';
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
  prayersCount: number
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
    'mensagem': () => router.push('/(app)/(tabs)/chat/index'),
  };

  const stats = calculateDashboardStats(events, schedules, prayersCount);

  const renderSkeleton = () => (
    <View className="flex-1 px-4 pt-16" style={{ backgroundColor: isDark ? '#0A0A0F' : '#FFFFFF' }}>
      <Skeleton variant="text" width="60%" height={28} className="mb-6" />
      <View className="flex-row mb-6 gap-3">
        <Skeleton variant="card" height={100} className="flex-1" />
        <Skeleton variant="card" height={100} className="flex-1" />
      </View>
      <Skeleton variant="card" height={160} className="mb-4" />
      <Skeleton variant="card" height={120} className="mb-4" />
      <Skeleton variant="card" height={120} />
    </View>
  );

  if (loading) {
    return renderSkeleton();
  }

  return (
    <View className="flex-1" style={{ backgroundColor: isDark ? '#0A0A0F' : '#FFFFFF' }}>
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
      >
        <View className="px-6 pt-16 pb-4">
          <FadeIn direction="down" distance={15} duration={500}>
            <Text
              className="text-3xl font-bold tracking-tight"
              style={{ color: isDark ? '#F9FAFB' : '#111827' }}
            >
              Olá, {user?.name?.split(' ')[0] || 'Membro'}
            </Text>
            <Text
              className="text-sm mt-1"
              style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}
            >
              {new Date().toLocaleDateString('pt-BR', {
                weekday: 'long',
                day: 'numeric',
                month: 'long',
              })}
            </Text>
          </FadeIn>
        </View>

        <QuickActions userRole={user?.role} />

        <View className="px-6 mb-6">
          <View className="flex-row" style={{ gap: 10 }}>
            <View className="flex-1">
              <DashboardCard
                icon={<Text className="text-lg">📅</Text>}
                title="Próximas Escolas"
                value={String(stats.schedulesCount)}
                color="#8B5CF6"
                index={0}
                onPress={() => router.push('/(app)/(tabs)/schedules')}
              />
            </View>
            <View className="flex-1">
              <DashboardCard
                icon={<Text className="text-lg">🎉</Text>}
                title="Eventos Hoje"
                value={String(stats.eventsToday)}
                color="#3B82F6"
                index={1}
                onPress={() => router.push('/(app)/(tabs)/calendar')}
              />
            </View>
          </View>
          <View className="flex-row mt-3" style={{ gap: 10 }}>
            <View className="flex-1">
              <DashboardCard
                icon={<Text className="text-lg">🙏</Text>}
                title="Pedidos Oração"
                value={String(stats.prayersCount)}
                color="#10B981"
                index={2}
                onPress={() => router.push('/(app)/(tabs)/prayers/index')}
              />
            </View>
            {canAccessFinance && (
              <View className="flex-1">
                <DashboardCard
                  icon={<Text className="text-lg">💰</Text>}
                  title="Saldo"
                  value="R$ --"
                  color="#F59E0B"
                  index={3}
                  onPress={() => router.push('/(app)/(tabs)/finance/index')}
                />
              </View>
            )}
          </View>
        </View>

        <SlideUp distance={30} delay={200}>
          <View className="px-6 mb-6">
            <View className="flex-row items-center justify-between mb-4">
              <Text
                className="text-lg font-bold"
                style={{ color: isDark ? '#F9FAFB' : '#111827' }}
              >
                Próximos Eventos
              </Text>
              <Button variant="ghost" size="sm" onPress={() => router.push('/(app)/(tabs)/calendar')}>
                Ver Todos
              </Button>
            </View>
            {events.length === 0 ? (
              <Card variant="filled" padding="lg" className="items-center">
                <EmptyState
                  title="Nenhum evento"
                  subtitle="Não há eventos próximos agendados"
                />
              </Card>
            ) : (
              <FlatList
                data={events.slice(0, 5)}
                keyExtractor={(item) => item.id}
                horizontal
                showsHorizontalScrollIndicator={false}
                contentContainerStyle={{ gap: 12 }}
                renderItem={({ item, index }) => (
                  <View style={{ width: 260 }}>
                    <EventCard
                      event={item}
                      index={index}
                      onPress={() => {}}
                    />
                  </View>
                )}
              />
            )}
          </View>
        </SlideUp>

        <SlideUp distance={30} delay={300}>
          <View className="px-6 mb-8">
            <View className="flex-row items-center justify-between mb-4">
              <Text
                className="text-lg font-bold"
                style={{ color: isDark ? '#F9FAFB' : '#111827' }}
              >
                Suas Escalas
              </Text>
              <Button variant="ghost" size="sm" onPress={() => router.push('/(app)/(tabs)/schedules')}>
                Ver Todas
              </Button>
            </View>
            {schedules.length === 0 ? (
              <Card variant="filled" padding="lg" className="items-center">
                <EmptyState
                  title="Nenhuma escala"
                  subtitle="Você não tem escalas agendadas"
                />
              </Card>
            ) : (
              schedules.slice(0, 3).map((schedule, index) => (
                <ScheduleCard
                  key={schedule.id}
                  schedule={schedule}
                  index={index}
                  onPress={() => router.push(`/(app)/(tabs)/schedule-detail?id=${schedule.id}`)}
                />
              ))
            )}
          </View>
        </SlideUp>
      </ScrollView>
    </View>
  );
}
