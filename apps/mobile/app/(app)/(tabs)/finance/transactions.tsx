import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  FlatList,
  TextInput,
  TouchableOpacity,
  RefreshControl,
  ActivityIndicator,
  ListRenderItemInfo,
} from 'react-native';
import { useRouter } from 'expo-router';
import { useColorScheme } from '../../../../src/hooks/useColorScheme';
import { FadeIn } from '../../../../src/components/animations/FadeIn';
import { TransactionItem } from '../../../../src/features/finance/components/TransactionItem';
import { Skeleton } from '../../../../src/components/ui/Skeleton';
import { EmptyState } from '../../../../src/components/ui/EmptyState';
import { Chip } from '../../../../src/components/ui/Chip';
import { Divider } from '../../../../src/components/ui/Divider';
import { formatCurrency } from '../../../../src/utils/format';
import { financeService } from '../../../../src/services/finance';
import type { Transaction, PaginatedResponse } from '../../../../src/types';

type TypeFilter = 'TODAS' | 'RECEITA' | 'DESPESA';
type StatusFilter = 'TODOS' | 'CONFIRMADO' | 'PENDENTE' | 'CANCELADO';

const PAGE_SIZE = 20;

export default function TransactionsScreen() {
  const router = useRouter();
  const { isDark } = useColorScheme();

  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [loadingMore, setLoadingMore] = useState(false);
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);
  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState<TypeFilter>('TODAS');
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('TODOS');

  const loadTransactions = useCallback(
    async (pageNum: number, append: boolean) => {
      try {
        const response: PaginatedResponse<Transaction> = await financeService.getTransactions({
          page: pageNum,
          limit: PAGE_SIZE,
          ...(typeFilter !== 'TODAS' && { type: typeFilter }),
          ...(statusFilter !== 'TODOS' && { status: statusFilter }),
          ...(search ? { search } : {}),
        });
        const data = response.data ?? response;
        const items = Array.isArray(data) ? data : [];
        if (append) {
          setTransactions((prev) => [...prev, ...items]);
        } else {
          setTransactions(items);
        }
        setHasMore(items.length === PAGE_SIZE);
      } catch {
        if (!append) setTransactions([]);
      } finally {
        setLoading(false);
        setRefreshing(false);
        setLoadingMore(false);
      }
    },
    [typeFilter, statusFilter, search]
  );

  useEffect(() => {
    setLoading(true);
    setPage(1);
    loadTransactions(1, false);
  }, [loadTransactions]);

  const onRefresh = useCallback(() => {
    setRefreshing(true);
    setPage(1);
    loadTransactions(1, false);
  }, [loadTransactions]);

  const onEndReached = useCallback(() => {
    if (loadingMore || !hasMore) return;
    setLoadingMore(true);
    const nextPage = page + 1;
    setPage(nextPage);
    loadTransactions(nextPage, true);
  }, [loadingMore, hasMore, page, loadTransactions]);

  const renderItem = useCallback(
    ({ item }: ListRenderItemInfo<Transaction>) => (
      <TransactionItem
        transaction={item}
        onPress={() => {}}
      />
    ),
    []
  );

  const renderSkeleton = () => (
    <View className="px-4 pt-4">
      <View className="flex-row gap-3 mb-4">
        <Skeleton width={80} height={32} variant="rectangular" />
        <Skeleton width={100} height={32} variant="rectangular" />
        <Skeleton width={70} height={32} variant="rectangular" />
      </View>
      {[1, 2, 3, 4, 5].map((i) => (
        <View key={i} className="flex-row items-center mb-3">
          <Skeleton variant="circular" width={40} height={40} />
          <View className="flex-1 mx-3">
            <Skeleton variant="text" width="60%" height={14} className="mb-1" />
            <Skeleton variant="text" width="40%" height={12} />
          </View>
          <Skeleton variant="text" width={80} height={16} />
        </View>
      ))}
    </View>
  );

  const renderFooter = () => {
    if (!loadingMore) return null;
    return (
      <View className="py-4 items-center">
        <ActivityIndicator size="small" color={isDark ? '#A78BFA' : '#7C3AED'} />
      </View>
    );
  };

  const renderEmpty = () => {
    if (loading) return null;
    return (
      <EmptyState
        icon={
          <View
            className={`w-16 h-16 rounded-2xl items-center justify-center ${
              isDark ? 'bg-neutral-800' : 'bg-neutral-100'
            }`}
          >
            <Text className="text-3xl">📋</Text>
          </View>
        }
        title="Nenhum Lançamento"
        subtitle={search || typeFilter !== 'TODAS' || statusFilter !== 'TODOS'
          ? 'Nenhum resultado encontrado para os filtros aplicados.'
          : 'Você ainda não possui lançamentos financeiros.'
        }
        actionLabel="Novo Lançamento"
        onAction={() => {}}
      />
    );
  };

  const typeFilters: TypeFilter[] = ['TODAS', 'RECEITA', 'DESPESA'];
  const statusFilters: StatusFilter[] = ['TODOS', 'CONFIRMADO', 'PENDENTE', 'CANCELADO'];

  return (
    <View className="flex-1" style={{ backgroundColor: isDark ? '#0A0A0F' : '#F9FAFB' }}>
      <View
        className="px-4"
        style={{ paddingTop: 56, backgroundColor: isDark ? '#0A0A0F' : '#F9FAFB' }}
      >
        <View className="flex-row items-center justify-between mb-3">
          <Text
            className="text-3xl font-bold"
            style={{ color: isDark ? '#F9FAFB' : '#111827', letterSpacing: -0.5 }}
          >
            Lançamentos
          </Text>
        </View>

        <View
          className={`flex-row items-center rounded-2xl px-4 mb-3 ${
            isDark ? 'bg-[#12121A]' : 'bg-white'
          }`}
          style={{
            borderWidth: 1,
            borderColor: isDark ? '#1F2937' : '#E5E7EB',
            shadowColor: isDark ? '#000' : '#000',
            shadowOffset: { width: 0, height: 1 },
            shadowOpacity: isDark ? 0.2 : 0.04,
            shadowRadius: 4,
            elevation: 1,
          }}
        >
          <Text className="text-lg" style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}>
            🔍
          </Text>
          <TextInput
            className="flex-1 ml-2 py-3 text-base"
            style={{ color: isDark ? '#F9FAFB' : '#111827' }}
            placeholder="Buscar lançamentos..."
            placeholderTextColor={isDark ? '#6B7280' : '#9CA3AF'}
            value={search}
            onChangeText={setSearch}
            returnKeyType="search"
          />
          {search.length > 0 && (
            <TouchableOpacity onPress={() => setSearch('')} className="p-1">
              <Text className="text-lg" style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}>
                ✕
              </Text>
            </TouchableOpacity>
          )}
        </View>
      </View>

      <View
        className="px-4 pb-3"
        style={{ backgroundColor: isDark ? '#0A0A0F' : '#F9FAFB' }}
      >
        <FlatList
          horizontal
          showsHorizontalScrollIndicator={false}
          data={typeFilters}
          keyExtractor={(item) => item}
          contentContainerStyle={{ gap: 8 }}
          renderItem={({ item }) => (
            <Chip
              label={
                item === 'TODAS'
                  ? 'Todas'
                  : item === 'RECEITA'
                  ? 'Receitas'
                  : 'Despesas'
              }
              variant="filled"
              selected={typeFilter === item}
              onPress={() => setTypeFilter(item)}
            />
          )}
        />
        <View className="mt-2">
          <FlatList
            horizontal
            showsHorizontalScrollIndicator={false}
            data={statusFilters}
            keyExtractor={(item) => item}
            contentContainerStyle={{ gap: 8 }}
            renderItem={({ item }) => (
              <Chip
                label={
                  item === 'TODOS'
                    ? 'Todos'
                    : item === 'CONFIRMADO'
                    ? 'Confirmados'
                    : item === 'PENDENTE'
                    ? 'Pendentes'
                    : 'Cancelados'
                }
                variant="filled"
                selected={statusFilter === item}
                onPress={() => setStatusFilter(item)}
              />
            )}
          />
        </View>
      </View>

      {loading ? (
        renderSkeleton()
      ) : (
        <FlatList
          data={transactions}
          renderItem={renderItem}
          keyExtractor={(item) => item.id}
          contentContainerStyle={{
            paddingHorizontal: 16,
            paddingBottom: 100,
            flexGrow: 1,
          }}
          refreshControl={
            <RefreshControl
              refreshing={refreshing}
              onRefresh={onRefresh}
              tintColor={isDark ? '#A78BFA' : '#7C3AED'}
              colors={['#7C3AED']}
              progressBackgroundColor={isDark ? '#1A1A2E' : '#FFFFFF'}
            />
          }
          onEndReached={onEndReached}
          onEndReachedThreshold={0.3}
          ListFooterComponent={renderFooter}
          ListEmptyComponent={renderEmpty}
          showsVerticalScrollIndicator={false}
          ItemSeparatorComponent={() => <View className="h-2" />}
        />
      )}

      <TouchableOpacity
        activeOpacity={0.85}
        className="absolute bottom-6 right-6 w-14 h-14 rounded-full items-center justify-center"
        style={{
          backgroundColor: isDark ? '#7C3AED' : '#7C3AED',
          shadowColor: '#7C3AED',
          shadowOffset: { width: 0, height: 4 },
          shadowOpacity: 0.4,
          shadowRadius: 8,
          elevation: 6,
        }}
        onPress={() => {}}
      >
        <Text className="text-white text-2xl font-bold leading-none" style={{ marginTop: -2 }}>
          +
        </Text>
      </TouchableOpacity>
    </View>
  );
}
