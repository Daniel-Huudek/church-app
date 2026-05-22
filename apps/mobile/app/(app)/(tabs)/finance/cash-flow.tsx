import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
  ActivityIndicator,
} from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withTiming,
  withDelay,
  withSpring,
  Easing,
} from 'react-native-reanimated';
import { useColorScheme } from '../../../../src/hooks/useColorScheme';
import { FadeIn } from '../../../../src/components/animations/FadeIn';
import { SlideUp } from '../../../../src/components/animations/SlideUp';
import { AnimatedCard } from '../../../../src/components/animations/AnimatedCard';
import { Card } from '../../../../src/components/ui/Card';
import { Button } from '../../../../src/components/ui/Button';
import { Skeleton } from '../../../../src/components/ui/Skeleton';
import { formatCurrency, formatDate, formatMonthYear } from '../../../../src/utils/format';
import { financeService } from '../../../../src/services/finance';
import type { Transaction } from '../../../../src/types';

const CHART_BAR_HEIGHT = 160;

const MONTH_NAMES = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];

function AnimatedChartBar({
  height,
  color,
  delay,
  label,
  value,
  isDark,
}: {
  height: number;
  color: string;
  delay: number;
  label: string;
  value: string;
  isDark: boolean;
}) {
  const barHeight = useSharedValue(0);
  const opacity = useSharedValue(0);

  React.useEffect(() => {
    barHeight.value = withDelay(
      delay,
      withSpring(height, { damping: 14, stiffness: 90 })
    );
    opacity.value = withDelay(
      delay,
      withTiming(1, { duration: 300, easing: Easing.out(Easing.cubic) })
    );
  }, [height, delay]);

  const animatedBarStyle = useAnimatedStyle(() => ({
    height: Math.max(barHeight.value, 4),
    backgroundColor: color,
    borderTopLeftRadius: 6,
    borderTopRightRadius: 6,
    opacity: opacity.value,
  }));

  return (
    <View className="flex-1 items-center mx-1">
      <Text
        className="text-[10px] font-semibold mb-1"
        style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}
        numberOfLines={1}
      >
        {value}
      </Text>
      <Animated.View style={[animatedBarStyle, { width: '70%' }]} />
      <Text
        className="text-[10px] mt-1.5"
        style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}
        numberOfLines={1}
      >
        {label}
      </Text>
    </View>
  );
}

export default function CashFlowScreen() {
  const { isDark } = useColorScheme();
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [currentMonth, setCurrentMonth] = useState(() => new Date().getMonth());
  const [currentYear, setCurrentYear] = useState(() => new Date().getFullYear());

  const selectedDate = new Date(currentYear, currentMonth);
  const monthLabel = formatMonthYear(selectedDate);

  const loadData = useCallback(async () => {
    try {
      const startDate = new Date(currentYear, currentMonth, 1).toISOString();
      const endDate = new Date(currentYear, currentMonth + 1, 0).toISOString();

      const response = await financeService.getTransactions({
        startDate,
        endDate,
        limit: 100,
        page: 1,
      });
      const data = response.data ?? response;
      setTransactions(Array.isArray(data) ? data : []);
    } catch {
      setTransactions([]);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, [currentMonth, currentYear]);

  useEffect(() => {
    setLoading(true);
    loadData();
  }, [loadData]);

  const onRefresh = useCallback(() => {
    setRefreshing(true);
    loadData();
  }, [loadData]);

  const prevMonth = () => {
    if (currentMonth === 0) {
      setCurrentMonth(11);
      setCurrentYear((y) => y - 1);
    } else {
      setCurrentMonth((m) => m - 1);
    }
  };

  const nextMonth = () => {
    if (currentMonth === 11) {
      setCurrentMonth(0);
      setCurrentYear((y) => y + 1);
    } else {
      setCurrentMonth((m) => m + 1);
    }
  };

  const totalIncome = transactions
    .filter((t) => t.type === 'RECEITA' && t.status !== 'CANCELADO')
    .reduce((sum, t) => sum + t.amount, 0);

  const totalExpenses = transactions
    .filter((t) => t.type === 'DESPESA' && t.status !== 'CANCELADO')
    .reduce((sum, t) => sum + t.amount, 0);

  const balance = totalIncome - totalExpenses;

  const categorySummary = transactions.reduce<Record<string, { income: number; expense: number }>>(
    (acc, t) => {
      const cat = t.categoryName || 'Outros';
      if (!acc[cat]) acc[cat] = { income: 0, expense: 0 };
      if (t.type === 'RECEITA' && t.status !== 'CANCELADO') acc[cat].income += t.amount;
      else if (t.type === 'DESPESA' && t.status !== 'CANCELADO') acc[cat].expense += t.amount;
      return acc;
    },
    {}
  );

  const chartCategories = Object.entries(categorySummary)
    .map(([name, vals]) => ({
      name,
      income: vals.income,
      expense: vals.expense,
    }))
    .filter((c) => c.income > 0 || c.expense > 0);

  const maxChartValue = Math.max(
    ...chartCategories.map((c) => Math.max(c.income, c.expense, 1))
  );

  if (loading) {
    return (
      <View className="flex-1 px-4" style={{ backgroundColor: isDark ? '#0A0A0F' : '#F9FAFB' }}>
        <View className="pt-14 pb-4">
          <Skeleton variant="text" width={180} height={32} />
        </View>
        <Skeleton variant="card" height={60} className="mb-4" />
        <View className="flex-row gap-3 mb-4">
          <Skeleton variant="card" height={80} className="flex-1" />
          <Skeleton variant="card" height={80} className="flex-1" />
          <Skeleton variant="card" height={80} className="flex-1" />
        </View>
        <Skeleton variant="card" height={200} className="mb-4" />
      </View>
    );
  }

  return (
    <View className="flex-1" style={{ backgroundColor: isDark ? '#0A0A0F' : '#F9FAFB' }}>
      <View
        className="px-4"
        style={{ paddingTop: 56, backgroundColor: isDark ? '#0A0A0F' : '#F9FAFB' }}
      >
        <Text
          className="text-3xl font-bold"
          style={{ color: isDark ? '#F9FAFB' : '#111827', letterSpacing: -0.5 }}
        >
          Fluxo de Caixa
        </Text>
      </View>

      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={{ paddingHorizontal: 16, paddingBottom: 100 }}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={onRefresh}
            tintColor={isDark ? '#66B5FF' : '#0066CC'}
            colors={['#0066CC']}
            progressBackgroundColor={isDark ? '#1A1A2E' : '#FFFFFF'}
          />
        }
      >
        <SlideUp delay={100}>
          <View
            className="flex-row items-center justify-between rounded-2xl p-3 mb-5"
            style={{
              backgroundColor: isDark ? '#12121A' : '#FFFFFF',
              shadowColor: isDark ? '#000' : '#000',
              shadowOffset: { width: 0, height: 2 },
              shadowOpacity: isDark ? 0.3 : 0.06,
              shadowRadius: 8,
              elevation: 3,
            }}
          >
            <TouchableOpacity onPress={prevMonth} className="w-10 h-10 items-center justify-center rounded-full bg-neutral-800/30">
              <Text className="text-lg" style={{ color: isDark ? '#D1D5DB' : '#4B5563' }}>◀</Text>
            </TouchableOpacity>
            <Text
              className="text-base font-bold"
              style={{ color: isDark ? '#F9FAFB' : '#111827' }}
            >
              {MONTH_NAMES[currentMonth]} {currentYear}
            </Text>
            <TouchableOpacity onPress={nextMonth} className="w-10 h-10 items-center justify-center rounded-full bg-neutral-800/30">
              <Text className="text-lg" style={{ color: isDark ? '#D1D5DB' : '#4B5563' }}>▶</Text>
            </TouchableOpacity>
          </View>
        </SlideUp>

        <FadeIn delay={200}>
          <View className="flex-row gap-3 mb-5">
            <View
              className="flex-1 rounded-2xl p-4"
              style={{
                backgroundColor: isDark ? '#12121A' : '#FFFFFF',
                shadowColor: isDark ? '#000' : '#000',
                shadowOffset: { width: 0, height: 2 },
                shadowOpacity: isDark ? 0.3 : 0.06,
                shadowRadius: 8,
                elevation: 3,
              }}
            >
              <Text className="text-xs font-medium mb-1" style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}>
                Receitas
              </Text>
              <Text
                className="text-lg font-bold"
                style={{ color: isDark ? '#34D399' : '#059669' }}
              >
                {formatCurrency(totalIncome)}
              </Text>
            </View>
            <View
              className="flex-1 rounded-2xl p-4"
              style={{
                backgroundColor: isDark ? '#12121A' : '#FFFFFF',
                shadowColor: isDark ? '#000' : '#000',
                shadowOffset: { width: 0, height: 2 },
                shadowOpacity: isDark ? 0.3 : 0.06,
                shadowRadius: 8,
                elevation: 3,
              }}
            >
              <Text className="text-xs font-medium mb-1" style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}>
                Despesas
              </Text>
              <Text
                className="text-lg font-bold"
                style={{ color: isDark ? '#F87171' : '#DC2626' }}
              >
                {formatCurrency(totalExpenses)}
              </Text>
            </View>
            <View
              className="flex-1 rounded-2xl p-4"
              style={{
                backgroundColor: isDark ? '#12121A' : '#FFFFFF',
                shadowColor: isDark ? '#000' : '#000',
                shadowOffset: { width: 0, height: 2 },
                shadowOpacity: isDark ? 0.3 : 0.06,
                shadowRadius: 8,
                elevation: 3,
              }}
            >
              <Text className="text-xs font-medium mb-1" style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}>
                Saldo
              </Text>
              <Text
                className={`text-lg font-bold ${
                  balance >= 0
                    ? isDark ? 'text-green-400' : 'text-green-600'
                    : isDark ? 'text-red-400' : 'text-red-600'
                }`}
              >
                {formatCurrency(balance)}
              </Text>
            </View>
          </View>
        </FadeIn>

        {chartCategories.length > 0 && (
          <FadeIn delay={300}>
            <Card variant="elevated" padding="lg" className="mb-5">
              <Text
                className="text-base font-bold mb-4"
                style={{ color: isDark ? '#F9FAFB' : '#111827' }}
              >
                Receitas vs Despesas por Categoria
              </Text>

              <View
                className="flex-row items-end justify-between"
                style={{ height: CHART_BAR_HEIGHT }}
              >
                {chartCategories.slice(0, 6).map((cat, idx) => {
                  const incHeight =
                    ((cat.income || 0) / maxChartValue) * (CHART_BAR_HEIGHT - 30);
                  const expHeight =
                    ((cat.expense || 0) / maxChartValue) * (CHART_BAR_HEIGHT - 30);

                  return (
                    <View key={idx} className="flex-1 items-center mx-0.5">
                      <View className="flex-row items-end" style={{ height: CHART_BAR_HEIGHT - 24, gap: 1.5 }}>
                        <AnimatedChartBar
                          height={incHeight}
                          color={isDark ? '#34D399' : '#10B981'}
                          delay={idx * 50}
                          label=""
                          value=""
                          isDark={isDark}
                        />
                        <AnimatedChartBar
                          height={expHeight}
                          color={isDark ? '#F87171' : '#EF4444'}
                          delay={idx * 50 + 25}
                          label=""
                          value=""
                          isDark={isDark}
                        />
                      </View>
                      <Text
                        className="text-[9px] mt-1 text-center"
                        style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}
                        numberOfLines={1}
                      >
                        {cat.name}
                      </Text>
                    </View>
                  );
                })}
              </View>

              <View className="flex-row justify-center mt-4 gap-6">
                <View className="flex-row items-center">
                  <View className={`w-2.5 h-2.5 rounded-full mr-2 ${isDark ? 'bg-green-400' : 'bg-green-500'}`} />
                  <Text className="text-xs" style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}>
                    Receitas
                  </Text>
                </View>
                <View className="flex-row items-center">
                  <View className={`w-2.5 h-2.5 rounded-full mr-2 ${isDark ? 'bg-red-400' : 'bg-red-500'}`} />
                  <Text className="text-xs" style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}>
                    Despesas
                  </Text>
                </View>
              </View>
            </Card>
          </FadeIn>
        )}

        <FadeIn delay={400}>
          <View className="mb-5">
            <View className="flex-row items-center justify-between mb-4">
              <Text
                className="text-lg font-bold"
                style={{ color: isDark ? '#F9FAFB' : '#111827' }}
              >
                Transações do Período
              </Text>
              <Text
                className="text-xs"
                style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}
              >
                {transactions.length} registro{transactions.length !== 1 ? 's' : ''}
              </Text>
            </View>

            {transactions.length === 0 ? (
              <Card variant="filled" padding="lg">
                <Text
                  className="text-sm text-center"
                  style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}
                >
                  Nenhuma transação neste período
                </Text>
              </Card>
            ) : (
              transactions.map((tx, idx) => {
                const isIncome = tx.type === 'RECEITA';
                return (
                  <AnimatedCard key={tx.id} className="mb-2">
                    <View
                      className="rounded-2xl p-4"
                      style={{
                        backgroundColor: isDark ? '#12121A' : '#FFFFFF',
                        shadowColor: isDark ? '#000' : '#000',
                        shadowOffset: { width: 0, height: 1 },
                        shadowOpacity: isDark ? 0.3 : 0.05,
                        shadowRadius: 6,
                        elevation: 2,
                      }}
                    >
                      <View className="flex-row items-center">
                        <View
                          className={`w-10 h-10 rounded-xl items-center justify-center ${
                            isIncome ? 'bg-green-500/15' : 'bg-red-500/15'
                          }`}
                        >
                          <Text className="text-lg">{isIncome ? '📈' : '📉'}</Text>
                        </View>
                        <View className="flex-1 ml-3">
                          <Text
                            className="text-sm font-semibold"
                            style={{ color: isDark ? '#F9FAFB' : '#111827' }}
                            numberOfLines={1}
                          >
                            {tx.description}
                          </Text>
                          <View className="flex-row items-center mt-0.5">
                            <Text
                              className="text-xs"
                              style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}
                            >
                              {formatDate(tx.date)}
                            </Text>
                            <Text
                              className="text-xs mx-1.5"
                              style={{ color: isDark ? '#4B5563' : '#D1D5DB' }}
                            >
                              •
                            </Text>
                            <Text
                              className="text-xs"
                              style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}
                              numberOfLines={1}
                            >
                              {tx.categoryName}
                            </Text>
                          </View>
                        </View>
                        <Text
                          className={`text-sm font-bold ${
                            isIncome
                              ? isDark ? 'text-green-400' : 'text-green-600'
                              : isDark ? 'text-red-400' : 'text-red-600'
                          }`}
                        >
                          {isIncome ? '+' : '-'} {formatCurrency(tx.amount)}
                        </Text>
                      </View>
                    </View>
                  </AnimatedCard>
                );
              })
            )}
          </View>
        </FadeIn>

        <FadeIn delay={500}>
          <Button
            variant="secondary"
            size="md"
            fullWidth
            onPress={() => {}}
            leftIcon={<Text className="text-base">📤</Text>}
          >
            Exportar Dados
          </Button>
        </FadeIn>
      </ScrollView>
    </View>
  );
}
