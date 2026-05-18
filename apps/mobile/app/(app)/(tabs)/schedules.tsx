import { useState, useEffect, useCallback } from 'react';
import { View, Text, FlatList, TouchableOpacity, RefreshControl } from 'react-native';
import { useRouter } from 'expo-router';
import { useColorScheme } from '../../../src/hooks/useColorScheme';
import { schedulesService } from '../../../src/services/schedules';
import { Header, Skeleton, EmptyState, Button } from '../../../src/components/ui';
import { FadeIn } from '../../../src/components/animations';
import { ScheduleCard } from '../../../src/features/schedules/components/ScheduleCard';
import { ScheduleFilter } from '../../../src/features/schedules/components/ScheduleFilter';
import type { Schedule, ScheduleStatus, ScheduleFilter as ScheduleFilterType } from '../../../src/types';

export default function Schedules() {
  const router = useRouter();
  const { isDark } = useColorScheme();
  const [schedules, setSchedules] = useState<Schedule[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [loadingMore, setLoadingMore] = useState(false);
  const [showMine, setShowMine] = useState(true);
  const [filters, setFilters] = useState<ScheduleFilterType>({});

  const loadSchedules = useCallback(async (pageNum: number = 1, append: boolean = false) => {
    try {
      const response = await schedulesService.getAll({
        ...filters,
        page: pageNum,
        limit: 20,
      });
      if (append) {
        setSchedules(prev => [...prev, ...response.data]);
      } else {
        setSchedules(response.data);
      }
      setTotalPages(response.totalPages);
    } catch (error) {
      console.error('Error loading schedules:', error);
    } finally {
      setLoading(false);
      setLoadingMore(false);
    }
  }, [filters]);

  useEffect(() => {
    setLoading(true);
    setPage(1);
    loadSchedules(1);
  }, [loadSchedules]);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    setPage(1);
    await loadSchedules(1);
    setRefreshing(false);
  }, [loadSchedules]);

  const loadMore = useCallback(() => {
    if (loadingMore || page >= totalPages) return;
    setLoadingMore(true);
    const nextPage = page + 1;
    setPage(nextPage);
    loadSchedules(nextPage, true);
  }, [page, totalPages, loadingMore, loadSchedules]);

  const handleFilterChange = useCallback((newFilters: ScheduleFilterType) => {
    setFilters(newFilters);
  }, []);

  const renderSkeleton = () => (
    <View className="flex-1 px-4 pt-20" style={{ backgroundColor: isDark ? '#0A0A0F' : '#FFFFFF' }}>
      <Skeleton variant="text" width="50%" height={28} className="mb-6" />
      <Skeleton variant="card" height={120} className="mb-3" />
      <Skeleton variant="card" height={120} className="mb-3" />
      <Skeleton variant="card" height={120} className="mb-3" />
    </View>
  );

  if (loading) {
    return renderSkeleton();
  }

  return (
    <View className="flex-1" style={{ backgroundColor: isDark ? '#0A0A0F' : '#FFFFFF' }}>
      <Header
        title="Minhas Escalas"
        largeTitle
      />

      <View className="px-6 mb-4">
        <View
          className="flex-row rounded-full p-1"
          style={{
            backgroundColor: isDark ? '#1A1A2E' : '#F3F4F6',
          }}
        >
          <TouchableOpacity
            activeOpacity={0.7}
            onPress={() => setShowMine(true)}
            className={`flex-1 py-2.5 px-4 rounded-full items-center ${
              showMine ? (isDark ? 'bg-purple-600' : 'bg-purple-600') : ''
            }`}
          >
            <Text
              className={`text-sm font-semibold ${
                showMine ? 'text-white' : isDark ? 'text-neutral-400' : 'text-neutral-600'
              }`}
            >
              Minhas
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            activeOpacity={0.7}
            onPress={() => setShowMine(false)}
            className={`flex-1 py-2.5 px-4 rounded-full items-center ${
              !showMine ? (isDark ? 'bg-purple-600' : 'bg-purple-600') : ''
            }`}
          >
            <Text
              className={`text-sm font-semibold ${
                !showMine ? 'text-white' : isDark ? 'text-neutral-400' : 'text-neutral-600'
              }`}
            >
              Todas
            </Text>
          </TouchableOpacity>
        </View>
      </View>

      <ScheduleFilter filters={filters} onChange={handleFilterChange} />

      <FlatList
        data={schedules}
        keyExtractor={(item) => item.id}
        contentContainerStyle={{
          paddingHorizontal: 20,
          paddingBottom: 100,
        }}
        showsVerticalScrollIndicator={false}
        renderItem={({ item, index }) => (
          <ScheduleCard
            schedule={item}
            index={index}
            onPress={() => router.push(`/(app)/(tabs)/schedule-detail?id=${item.id}`)}
          />
        )}
        ListEmptyComponent={
          <FadeIn direction="up" distance={20}>
            <EmptyState
              icon={<Text className="text-5xl">📋</Text>}
              title="Nenhuma escala"
              subtitle={showMine ? 'Você não está escalado para nenhum evento' : 'Nenhuma escala encontrada'}
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
        onEndReached={loadMore}
        onEndReachedThreshold={0.5}
        ListFooterComponent={
          loadingMore ? (
            <View className="py-4 items-center">
              <View className="flex-row gap-2">
                <Skeleton variant="text" width={120} height={16} />
              </View>
            </View>
          ) : null
        }
      />

      <View className="absolute bottom-8 right-6">
        <TouchableOpacity
          activeOpacity={0.8}
          className="w-14 h-14 rounded-2xl items-center justify-center"
          style={{
            backgroundColor: '#7C3AED',
            shadowColor: '#7C3AED',
            shadowOffset: { width: 0, height: 4 },
            shadowOpacity: 0.4,
            shadowRadius: 8,
            elevation: 6,
          }}
          onPress={() => {}}
        >
          <Text className="text-2xl text-white font-bold">+</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}
