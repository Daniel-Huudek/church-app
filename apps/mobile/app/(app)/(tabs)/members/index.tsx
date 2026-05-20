import { View, FlatList, TouchableOpacity, TextInput, RefreshControl, ActivityIndicator, Animated as RNAnimated, Dimensions } from 'react-native';
import { useState, useEffect, useCallback, useRef, useMemo } from 'react';
import { router } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useColorScheme } from '../../../../src/hooks/useColorScheme';
import { membersService } from '../../../../src/services/members';
import type { Member, MemberFilter } from '../../../../src/types';
import { MemberCard } from '../../../../src/features/members/components/MemberCard';
import { Header, Skeleton, EmptyState, Chip } from '../../../../src/components/ui';
import { borderRadius } from '../../../../src/theme';

const { width } = Dimensions.get('window');

const STATUS_FILTERS = [
  { key: 'all', label: 'Todos' },
  { key: 'ATIVO', label: 'Ativos' },
  { key: 'INATIVO', label: 'Inativos' },
  { key: 'VISITANTE', label: 'Visitantes' },
];

const PAGE_SIZE = 20;

function SearchIcon() {
  return (
    <View className="opacity-50">
      <Text className="text-lg">🔍</Text>
    </View>
  );
}

function CloseIcon() {
  return (
    <Text className="text-lg">✕</Text>
  );
}

function PlusIcon() {
  return <Text className="text-2xl text-white">+</Text>;
}

function MembersSkeleton() {
  return (
    <View className="px-4 mt-2">
      {Array.from({ length: 6 }).map((_, i) => (
        <View key={i} className="flex-row items-center mb-3">
          <Skeleton variant="circular" width={48} height={48} />
          <View className="flex-1 ml-3">
            <Skeleton variant="text" width="60%" height={14} className="mb-2" />
            <Skeleton variant="text" width="40%" height={12} />
          </View>
        </View>
      ))}
    </View>
  );
}

export default function MembersListScreen() {
  const { isDark, colors: themeColors } = useColorScheme();
  const insets = useSafeAreaInsets();

  const [members, setMembers] = useState<Member[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [loadingMore, setLoadingMore] = useState(false);
  const [search, setSearch] = useState('');
  const [activeFilter, setActiveFilter] = useState('all');
  const [searchExpanded, setSearchExpanded] = useState(false);

  const searchAnim = useRef(new RNAnimated.Value(0)).current;
  const searchInputRef = useRef<TextInput>(null);

  useEffect(() => {
    RNAnimated.timing(searchAnim, {
      toValue: searchExpanded ? 1 : 0,
      duration: 250,
      useNativeDriver: false,
    }).start();
  }, [searchExpanded]);

  const searchWidth = searchAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [40, width - 32],
  });

  const filters: MemberFilter = useMemo(() => {
    const f: MemberFilter = { page, limit: PAGE_SIZE, sortBy: 'name', sortOrder: 'asc' };
    if (activeFilter !== 'all') f.status = activeFilter;
    if (search.trim()) f.search = search.trim();
    return f;
  }, [page, activeFilter, search]);

  const loadMembers = useCallback(async (isRefresh = false) => {
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
      const res = await membersService.list({ ...filters, page: currentPage });
      const data = res.data.data;
      const list = data || [];
      if (isRefresh || currentPage === 1) {
        setMembers(list);
      } else {
        setMembers((prev) => [...prev, ...list]);
      }
      setTotal(res.data.total || 0);
      setHasMore(list.length >= PAGE_SIZE);
    } catch {
      // handled
    } finally {
      setLoading(false);
      setRefreshing(false);
      setLoadingMore(false);
    }
  }, [page, filters]);

  useEffect(() => {
    loadMembers();
  }, [page]);

  const handleRefresh = useCallback(() => {
    loadMembers(true);
  }, [loadMembers]);

  const handleEndReached = useCallback(() => {
    if (!loadingMore && hasMore && !loading) {
      setPage((p) => p + 1);
    }
  }, [loadingMore, hasMore, loading]);

  const handleFilterChange = useCallback((key: string) => {
    setActiveFilter(key);
    setPage(1);
  }, []);

  const toggleSearch = useCallback(() => {
    setSearchExpanded((prev) => {
      if (!prev) {
        setTimeout(() => searchInputRef.current?.focus(), 100);
      } else {
        setSearch('');
      }
      return !prev;
    });
  }, []);

  const handleSearchSubmit = useCallback(() => {
    setPage(1);
    loadMembers(true);
  }, [loadMembers]);

  const handleAddMember = useCallback(() => {
    router.push('/(app)/(tabs)/members/create');
  }, []);

  const renderMember = useCallback(
    ({ item, index }: { item: Member; index: number }) => (
      <MemberCard
        member={item}
        index={index}
        onPress={() => router.push(`/(app)/(tabs)/members/${item.id}`)}
      />
    ),
    []
  );

  const renderHeader = useMemo(
    () => (
      <View>
        <View className="flex-row items-center px-4 mb-3">
          <RNAnimated.View
            style={{
              width: searchWidth,
              height: 40,
              borderRadius: borderRadius.lg,
              backgroundColor: isDark ? '#1A1A2E' : '#F3F4F6',
              flexDirection: 'row',
              alignItems: 'center',
              paddingHorizontal: 12,
              overflow: 'hidden',
            }}
          >
            <TouchableOpacity onPress={toggleSearch} className="mr-2">
              {searchExpanded ? <CloseIcon /> : <SearchIcon />}
            </TouchableOpacity>
            {searchExpanded && (
              <TextInput
                ref={searchInputRef}
                value={search}
                onChangeText={setSearch}
                onSubmitEditing={handleSearchSubmit}
                placeholder="Buscar membros..."
                placeholderTextColor={isDark ? '#6B7280' : '#9CA3AF'}
                className="flex-1 text-base"
                style={{ color: isDark ? '#F9FAFB' : '#111827' }}
                returnKeyType="search"
              />
            )}
            {searchExpanded && search.length > 0 && (
              <TouchableOpacity onPress={() => setSearch('')} className="ml-2">
                <Text className={isDark ? 'text-neutral-400' : 'text-neutral-500'}>✕</Text>
              </TouchableOpacity>
            )}
          </RNAnimated.View>
        </View>

        <FlatList
          horizontal
          data={STATUS_FILTERS}
          keyExtractor={(item) => item.key}
          showsHorizontalScrollIndicator={false}
          contentContainerClassName="px-4 mb-4"
          renderItem={({ item }) => (
            <Chip
              label={item.label}
              selected={activeFilter === item.key}
              onPress={() => handleFilterChange(item.key)}
              className="mr-2"
            />
          )}
        />
      </View>
    ),
    [searchExpanded, search, activeFilter, isDark, searchWidth, toggleSearch, handleSearchSubmit, handleFilterChange]
  );

  if (loading && page === 1) {
    return (
      <View className="flex-1" style={{ backgroundColor: isDark ? '#0A0A0F' : '#FFFFFF' }}>
        <Header title="Membros" largeTitle rightActions={[{ icon: <SearchIcon />, onPress: toggleSearch }]} />
        <View className="flex-row px-4 mb-4">
          {STATUS_FILTERS.map((f) => (
            <Skeleton key={f.key} variant="rectangular" width={80} height={32} className="mr-2 rounded-full" />
          ))}
        </View>
        <MembersSkeleton />
      </View>
    );
  }

  return (
    <View className="flex-1" style={{ backgroundColor: isDark ? '#0A0A0F' : '#FFFFFF' }}>
      <Header
        title="Membros"
        subtitle={`${total} membro${total !== 1 ? 's' : ''}`}
        largeTitle
        rightActions={[
          {
            icon: (
              <Text className={isDark ? 'text-neutral-200' : 'text-neutral-700'}>
                {searchExpanded ? '✕' : '🔍'}
              </Text>
            ),
            onPress: toggleSearch,
          },
        ]}
      />

      <FlatList
        data={members}
        renderItem={renderMember}
        keyExtractor={(item) => item.id}
        contentContainerStyle={{ paddingBottom: 100, paddingHorizontal: 16 }}
        ListHeaderComponent={searchExpanded ? null : renderHeader}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={handleRefresh}
            tintColor={isDark ? '#66B5FF' : '#0066CC'}
            colors={['#0066CC']}
            progressBackgroundColor={isDark ? '#1A1A2E' : '#FFFFFF'}
          />
        }
        onEndReached={handleEndReached}
        onEndReachedThreshold={0.3}
        ListFooterComponent={
          loadingMore ? (
            <View className="py-4 items-center">
              <ActivityIndicator color={isDark ? '#66B5FF' : '#0066CC'} />
            </View>
          ) : null
        }
        ListEmptyComponent={
          !loading ? (
            <EmptyState
              icon={<Text className="text-5xl">🔍</Text>}
              title={search ? 'Nenhum resultado' : 'Nenhum membro'}
              subtitle={
                search
                  ? 'Tente buscar por outro nome ou remova os filtros.'
                  : 'Adicione o primeiro membro da igreja.'
              }
              actionLabel={search ? 'Limpar busca' : 'Adicionar membro'}
              onAction={() => {
                if (search) {
                  setSearch('');
                  setPage(1);
                } else {
                  handleAddMember();
                }
              }}
            />
          ) : null
        }
      />

      <TouchableOpacity
        onPress={handleAddMember}
        activeOpacity={0.8}
        className="absolute w-14 h-14 rounded-full items-center justify-center"
        style={{
          backgroundColor: '#0066CC',
          bottom: insets.bottom + 24,
          right: 20,
          shadowColor: '#0066CC',
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
