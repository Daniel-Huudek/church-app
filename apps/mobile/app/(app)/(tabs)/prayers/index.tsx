import { View, FlatList, TouchableOpacity, RefreshControl, ActivityIndicator } from 'react-native';
import { useState, useEffect, useCallback, useMemo } from 'react';
import { router } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useColorScheme } from '../../../../src/hooks/useColorScheme';
import { useAuth } from '../../../../src/hooks/useAuth';
import { prayersService } from '../../../../src/services/prayers';
import type { Prayer, PrayerCategory, PrayerFilter } from '../../../../src/types';
import { PrayerCard } from '../../../../src/features/prayers/components/PrayerCard';
import { Header, Skeleton, EmptyState, Chip, Tabs } from '../../../../src/components/ui';
import { FadeIn } from '../../../../src/components/animations';


const FEED_TABS = [
  { key: 'feed', label: 'Feed' },
  { key: 'urgent', label: 'Urgentes' },
  { key: 'mine', label: 'Meus Pedidos' },
];

const PAGE_SIZE = 20;

function PlusIcon() {
  return <Text className="text-2xl text-white">+</Text>;
}

function PrayerSkeleton() {
  return (
    <View className="px-4 mt-2">
      {Array.from({ length: 4 }).map((_, i) => (
        <View key={i} className="mb-4 rounded-2xl p-4" style={{ backgroundColor: '#1A1A2E' }}>
          <View className="flex-row items-center mb-3">
            <Skeleton variant="circular" width={36} height={36} />
            <View className="flex-1 ml-2.5">
              <Skeleton variant="text" width="40%" height={12} className="mb-1" />
              <Skeleton variant="text" width="25%" height={10} />
            </View>
          </View>
          <Skeleton variant="text" width="80%" height={16} className="mb-2" />
          <Skeleton variant="text" width="100%" height={12} className="mb-1" />
          <Skeleton variant="text" width="100%" height={12} className="mb-3" />
          <View className="flex-row gap-2">
            <Skeleton variant="rectangular" width={70} height={28} className="rounded-full" />
            <Skeleton variant="rectangular" width={70} height={28} className="rounded-full" />
            <Skeleton variant="rectangular" width={70} height={28} className="rounded-full" />
          </View>
        </View>
      ))}
    </View>
  );
}

export default function PrayerFeedScreen() {
  const { isDark, colors: themeColors } = useColorScheme();
  const { user } = useAuth();
  const insets = useSafeAreaInsets();

  const [prayers, setPrayers] = useState<Prayer[]>([]);
  const [categories, setCategories] = useState<PrayerCategory[]>([]);
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [loadingMore, setLoadingMore] = useState(false);
  const [activeTab, setActiveTab] = useState('feed');
  const [activeCategory, setActiveCategory] = useState<string | null>(null);

  useEffect(() => {
    prayersService.getCategories()
      .then(setCategories)
      .catch(() => {});
  }, []);

  const filters = useMemo((): PrayerFilter => {
    const f: PrayerFilter = { page, limit: PAGE_SIZE, sortBy: 'recent' };
    if (activeCategory) f.categoryId = activeCategory;
    if (activeTab === 'urgent') f.isUrgent = true;
    if (activeTab === 'mine' && user) f.authorId = user.id;
    return f;
  }, [page, activeCategory, activeTab, user]);

  const loadPrayers = useCallback(async (isRefresh = false) => {
    if (isRefresh) {
      setRefreshing(true);
      setPage(1);
    } else if (page === 1) {
      setLoading(true);
    } else {
      setLoadingMore(true);
    }

    try {
      const currentPage = isRefresh ? 1 : page;
      let res;

      if (activeTab === 'urgent') {
        res = await prayersService.getUrgent(currentPage, PAGE_SIZE);
      } else if (activeTab === 'mine') {
        res = await prayersService.getMy(currentPage, PAGE_SIZE);
      } else {
        res = await prayersService.list({ ...filters, page: currentPage });
      }

      const list = res.data.data || [];
      if (isRefresh || currentPage === 1) {
        setPrayers(list);
      } else {
        setPrayers((prev) => [...prev, ...list]);
      }
      setHasMore(list.length >= PAGE_SIZE);
    } catch {
      // handled
    } finally {
      setLoading(false);
      setRefreshing(false);
      setLoadingMore(false);
    }
  }, [page, filters, activeTab]);

  useEffect(() => {
    loadPrayers();
  }, [page]);

  const handleRefresh = useCallback(() => {
    loadPrayers(true);
  }, [loadPrayers]);

  const handleEndReached = useCallback(() => {
    if (!loadingMore && hasMore && !loading) {
      setPage((p) => p + 1);
    }
  }, [loadingMore, hasMore, loading]);

  const handleTabChange = useCallback((key: string) => {
    setActiveTab(key);
    setActiveCategory(null);
    setPage(1);
  }, []);

  const handleCategoryChange = useCallback((catId: string | null) => {
    setActiveCategory(catId);
    setPage(1);
  }, []);

  const handleReact = useCallback(async (prayerId: string, type: string) => {
    try {
      await prayersService.toggleReaction(prayerId, type as any);
      setPrayers((prev) =>
        prev.map((p) => {
          if (p.id !== prayerId) return p;
          const hasReaction = p.reactions?.some((r) => r.type === type);
          return {
            ...p,
            reactions: hasReaction
              ? (p.reactions?.filter((r) => r.type !== type) || [])
              : [...(p.reactions || []), { id: '', prayerId, memberId: user?.id || '', memberName: user?.name || '', type: type as any, createdAt: new Date().toISOString() }],
          };
        })
      );
    } catch {
      // handled
    }
  }, [user]);

  const handleCreate = useCallback(() => {
    router.push('/(app)/(tabs)/prayers/create');
  }, []);

  const renderPrayer = useCallback(
    ({ item, index }: { item: Prayer; index: number }) => (
      <FadeIn direction="up" delay={index * 60} distance={15}>
        <PrayerCard
          prayer={item}
          index={index}
          onPress={() => router.push(`/(app)/(tabs)/prayers/${item.id}`)}
          onReact={(type) => handleReact(item.id, type)}
        />
      </FadeIn>
    ),
    [handleReact]
  );

  const renderListHeader = useMemo(() => {
    if (categories.length === 0) return null;
    return (
      <View className="px-4 mb-4">
        <FlatList
          horizontal
          data={[{ id: null, name: 'Todas' } as any, ...categories]}
          keyExtractor={(item) => item.id || 'all'}
          showsHorizontalScrollIndicator={false}
          renderItem={({ item }) => (
            <Chip
              label={item.name}
              selected={activeCategory === item.id}
              onPress={() => handleCategoryChange(item.id)}
              className="mr-2"
              size="sm"
            />
          )}
        />
      </View>
    );
  }, [categories, activeCategory, handleCategoryChange]);

  if (loading && page === 1) {
    return (
      <View className="flex-1" style={{ backgroundColor: isDark ? '#0A0A0F' : '#F9FAFB' }}>
        <Header title="Pedidos de Oração" largeTitle />
        <View className="px-4 mb-4">
          <View className="flex-row border-b" style={{ borderColor: isDark ? '#1F2937' : '#E5E7EB' }}>
            {FEED_TABS.map((tab) => (
              <View key={tab.key} className="px-4 py-3">
                <Skeleton variant="text" width={60} height={14} />
              </View>
            ))}
          </View>
        </View>
        <View className="px-4 mb-4">
          <FlatList
            horizontal
            data={[1, 2, 3, 4]}
            keyExtractor={(i) => String(i)}
            showsHorizontalScrollIndicator={false}
            renderItem={() => <Skeleton variant="rectangular" width={70} height={28} className="mr-2 rounded-full" />}
          />
        </View>
        <PrayerSkeleton />
      </View>
    );
  }

  return (
    <View className="flex-1" style={{ backgroundColor: isDark ? '#0A0A0F' : '#F9FAFB' }}>
      <Header title="Pedidos de Oração" largeTitle />

      <Tabs tabs={FEED_TABS} activeTab={activeTab} onTabChange={handleTabChange} />

      <FlatList
        data={prayers}
        renderItem={renderPrayer}
        keyExtractor={(item) => item.id}
        contentContainerStyle={{
          paddingTop: 16,
          paddingHorizontal: 16,
          paddingBottom: 100,
        }}
        ListHeaderComponent={renderListHeader}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={handleRefresh}
            tintColor={isDark ? '#A78BFA' : '#7C3AED'}
            colors={['#7C3AED']}
            progressBackgroundColor={isDark ? '#1A1A2E' : '#FFFFFF'}
          />
        }
        onEndReached={handleEndReached}
        onEndReachedThreshold={0.3}
        ListFooterComponent={
          loadingMore ? (
            <View className="py-4 items-center">
              <ActivityIndicator color={isDark ? '#A78BFA' : '#7C3AED'} />
            </View>
          ) : null
        }
        ListEmptyComponent={
          !loading ? (
            <EmptyState
              icon={<Text className="text-5xl">🙏</Text>}
              title={
                activeTab === 'urgent'
                  ? 'Nenhum pedido urgente'
                  : activeTab === 'mine'
                  ? 'Você ainda não fez pedidos'
                  : 'Nenhum pedido de oração'
              }
              subtitle={
                activeTab === 'mine'
                  ? 'Compartilhe seus pedidos de oração com a igreja.'
                  : 'Quando alguém compartilhar um pedido, ele aparecerá aqui.'
              }
              actionLabel="Criar pedido"
              onAction={handleCreate}
            />
          ) : null
        }
      />

      <TouchableOpacity
        onPress={handleCreate}
        activeOpacity={0.8}
        className="absolute w-14 h-14 rounded-full items-center justify-center"
        style={{
          backgroundColor: '#7C3AED',
          bottom: insets.bottom + 24,
          right: 20,
          shadowColor: '#7C3AED',
          shadowOffset: { width: 0, height: 4 },
          shadowOpacity: 0.4,
          shadowRadius: 8,
          elevation: 6,
        }}
      >
        <PlusIcon />
      </TouchableOpacity>
    </View>
  );
}
