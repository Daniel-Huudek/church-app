import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
  Dimensions,
} from 'react-native';
import { useRouter } from 'expo-router';
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
import { Divider } from '../../../../src/components/ui/Divider';
import { formatCurrency, formatDate } from '../../../../src/utils/format';
import { financeService } from '../../../../src/services/finance';
import type { FinanceDashboard, Transaction } from '../../../../src/types';

const { width: SCREEN_WIDTH } = Dimensions.get('window');
const CHART_HEIGHT = 120;

type Period = 'MÊS' | 'TRIMESTRE' | 'ANO';

const MONTHS = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];

const statusConfig: Record<Transaction['status'], { label: string; bg: string; text: string }> = {
  CONFIRMADO: { label: 'Confirmado', bg: 'bg-green-500/15', text: 'text-green-500' },
  PENDENTE: { label: 'Pendente', bg: 'bg-amber-500/15', text: 'text-amber-500' },
  CANCELADO: { label: 'Cancelado', bg: 'bg-red-500/15', text: 'text-red-500' },
};

function BarChart({ data, isDark }: { data: { label: string; revenue: number; expenses: number }[]; isDark: boolean }) {
  const maxVal = Math.max(...data.map((d) => Math.max(d.revenue, d.expenses, 1)));

  return (
    <View className="flex-row items-end justify-between" style={{ height: CHART_HEIGHT }}>
      {data.map((item, idx) => {
        const revHeight = (item.revenue / maxVal) * (CHART_HEIGHT - 20);
        const expHeight = (item.expenses / maxVal) * (CHART_HEIGHT - 20);

        return (
          <View key={idx} className="flex-1 items-center mx-1">
            <View className="flex-row items-end" style={{ height: CHART_HEIGHT - 24, gap: 2 }}>
              <AnimatedBar height={revHeight} color={isDark ? '#34D399' : '#10B981'} delay={idx * 60} />
              <AnimatedBar height={expHeight} color={isDark ? '#F87171' : '#EF4444'} delay={idx * 60 + 30} />
            </View>
            <Text
              className="text-[10px] mt-1"
              style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}
              numberOfLines={1}
            >
              {item.label}
            </Text>
          </View>
        );
      })}
    </View>
  );
}

function AnimatedBar({ height, color, delay }: { height: number; color: string; delay: number }) {
  const barHeight = useSharedValue(0);

  React.useEffect(() => {
    barHeight.value = withDelay(delay, withSpring(height, { damping: 12, stiffness: 80 }));
  }, [height, delay]);

  const style = useAnimatedStyle(() => ({
    height: Math.max(barHeight.value, 4),
    backgroundColor: color,
    borderTopLeftRadius: 4,
    borderTopRightRadius: 4,
  }));

  return <Animated.View style={[style, { width: 10 }]} />;
}

export default function FinanceDashboardScreen() {
  const router = useRouter();
  const { isDark, colors: themeColors } = useColorScheme();
  const [dashboard, setDashboard] = useState<FinanceDashboard | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [period, setPeriod] = useState<Period>('MÊS');

  const loadDashboard = useCallback(async () => {
    try {
      const data = await financeService.getDashboard();
      setDashboard(data);
    } catch {
      // handle error silently
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => {
    loadDashboard();
  }, [loadDashboard]);

  const onRefresh = useCallback(() => {
    setRefreshing(true);
    loadDashboard();
  }, [loadDashboard]);

  if (loading) {
    return (
      <View className="flex-1 px-4" style={{ backgroundColor: isDark ? '#0A0A0F' : '#F9FAFB' }}>
        <View className="pt-14 pb-4">
          <Skeleton variant="text" width={160} height={32} />
        </View>
        <Skeleton variant="card" height={180} className="mb-4" />
        <View className="flex-row gap-3 mb-4">
          <View className="flex-1">
            <Skeleton variant="card" height={100} />
          </View>
          <View className="flex-1">
            <Skeleton variant="card" height={100} />
          </View>
        </View>
        <Skeleton variant="card" height={160} className="mb-4" />
        <Skeleton variant="card" height={60} className="mb-4" />
        <Skeleton variant="card" height={200} />
      </View>
    );
  }

  const balance = dashboard?.balance ?? 0;
  const totalRevenue = dashboard?.totalRevenue ?? 0;
  const totalExpenses = dashboard?.totalExpenses ?? 0;
  const recentTransactions = dashboard?.recentTransactions ?? [];
  const monthlyComparison = dashboard?.monthlyComparison ?? [];

  const periodData = (() => {
    if (period === 'MÊS') return monthlyComparison.slice(-1);
    if (period === 'TRIMESTRE') return monthlyComparison.slice(-3);
    return monthlyComparison;
  })();

  return (
    <View className="flex-1" style={{ backgroundColor: isDark ? '#0A0A0F' : '#F9FAFB' }}>
      <View
        className="px-4 pb-2"
        style={{ paddingTop: 56, backgroundColor: isDark ? '#0A0A0F' : '#F9FAFB' }}
      >
        <Text
          className="text-3xl font-bold"
          style={{
            color: isDark ? '#F9FAFB' : '#111827',
            letterSpacing: -0.5,
          }}
        >
          Financeiro
        </Text>
      </View>

      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={{ paddingBottom: 100, paddingHorizontal: 16 }}
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
        <SlideUp delay={100}>
          <View
            className="rounded-3xl p-6 mb-5 overflow-hidden"
            style={{
              backgroundColor: isDark ? '#1A1A2E' : '#7C3AED',
              shadowColor: isDark ? '#000' : '#7C3AED',
              shadowOffset: { width: 0, height: 8 },
              shadowOpacity: isDark ? 0.4 : 0.3,
              shadowRadius: 24,
              elevation: 10,
            }}
          >
            <Text
              className="text-sm font-medium mb-1"
              style={{ color: isDark ? '#9CA3AF' : 'rgba(255,255,255,0.8)' }}
            >
              Saldo Atual
            </Text>
            <Text
              className="text-4xl font-bold mb-4"
              style={{
                color: isDark ? '#F9FAFB' : '#FFFFFF',
                letterSpacing: -1,
              }}
            >
              {formatCurrency(balance)}
            </Text>

            <View className="flex-row gap-4">
              <View className="flex-1 bg-white/10 rounded-xl p-3">
                <Text
                  className="text-xs font-medium"
                  style={{ color: 'rgba(255,255,255,0.7)' }}
                >
                  Receitas
                </Text>
                <Text className="text-lg font-bold text-green-400">
                  {formatCurrency(totalRevenue)}
                </Text>
              </View>
              <View className="flex-1 bg-white/10 rounded-xl p-3">
                <Text
                  className="text-xs font-medium"
                  style={{ color: 'rgba(255,255,255,0.7)' }}
                >
                  Despesas
                </Text>
                <Text className="text-lg font-bold text-red-400">
                  {formatCurrency(totalExpenses)}
                </Text>
              </View>
            </View>
          </View>
        </SlideUp>

        <FadeIn delay={200}>
          <View className="flex-row mb-5 gap-2">
            {(['MÊS', 'TRIMESTRE', 'ANO'] as Period[]).map((p) => (
              <TouchableOpacity
                key={p}
                onPress={() => setPeriod(p)}
                activeOpacity={0.7}
                className={`px-4 py-2 rounded-full ${
                  period === p
                    ? isDark
                      ? 'bg-purple-600'
                      : 'bg-purple-600'
                    : isDark
                    ? 'bg-neutral-800'
                    : 'bg-neutral-200'
                }`}
              >
                <Text
                  className={`text-sm font-semibold ${
                    period === p ? 'text-white' : isDark ? 'text-neutral-300' : 'text-neutral-600'
                  }`}
                >
                  {p}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        </FadeIn>

        <FadeIn delay={300}>
          <Card variant="elevated" padding="lg" className="mb-5">
            <View className="flex-row justify-between items-center mb-4">
              <Text
                className="text-base font-semibold"
                style={{ color: isDark ? '#F9FAFB' : '#111827' }}
              >
                Fluxo de Caixa
              </Text>
            </View>
            <BarChart
              data={periodData.map((m) => ({
                label: m.month,
                revenue: m.revenue,
                expenses: m.expenses,
              }))}
              isDark={isDark}
            />
            <View className="flex-row justify-center mt-4 gap-6">
              <View className="flex-row items-center">
                <View className={`w-2.5 h-2.5 rounded-full ${isDark ? 'bg-green-400' : 'bg-green-500'} mr-2`} />
                <Text className="text-xs" style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}>
                  Receitas
                </Text>
              </View>
              <View className="flex-row items-center">
                <View className={`w-2.5 h-2.5 rounded-full ${isDark ? 'bg-red-400' : 'bg-red-500'} mr-2`} />
                <Text className="text-xs" style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}>
                  Despesas
                </Text>
              </View>
            </View>
          </Card>
        </FadeIn>

        <FadeIn delay={400}>
          <View className="flex-row gap-3 mb-5">
            <AnimatedCard className="flex-1" onPress={() => router.push('/(app)/(tabs)/finance/transactions')}>
              <View
                className="rounded-2xl p-4 items-center"
                style={{
                  backgroundColor: isDark ? '#12121A' : '#FFFFFF',
                  shadowColor: isDark ? '#000' : '#000',
                  shadowOffset: { width: 0, height: 2 },
                  shadowOpacity: isDark ? 0.3 : 0.06,
                  shadowRadius: 8,
                  elevation: 3,
                }}
              >
                <View className="w-12 h-12 rounded-2xl items-center justify-center mb-2 bg-green-500/15">
                  <Text className="text-2xl">➕</Text>
                </View>
                <Text className="text-xs font-semibold text-center" style={{ color: isDark ? '#D1D5DB' : '#4B5563' }}>
                  Nova Receita
                </Text>
              </View>
            </AnimatedCard>

            <AnimatedCard className="flex-1" onPress={() => router.push('/(app)/(tabs)/finance/transactions')}>
              <View
                className="rounded-2xl p-4 items-center"
                style={{
                  backgroundColor: isDark ? '#12121A' : '#FFFFFF',
                  shadowColor: isDark ? '#000' : '#000',
                  shadowOffset: { width: 0, height: 2 },
                  shadowOpacity: isDark ? 0.3 : 0.06,
                  shadowRadius: 8,
                  elevation: 3,
                }}
              >
                <View className="w-12 h-12 rounded-2xl items-center justify-center mb-2 bg-red-500/15">
                  <Text className="text-2xl">➖</Text>
                </View>
                <Text className="text-xs font-semibold text-center" style={{ color: isDark ? '#D1D5DB' : '#4B5563' }}>
                  Nova Despesa
                </Text>
              </View>
            </AnimatedCard>

            <AnimatedCard className="flex-1" onPress={() => router.push('/(app)/(tabs)/finance/reports')}>
              <View
                className="rounded-2xl p-4 items-center"
                style={{
                  backgroundColor: isDark ? '#12121A' : '#FFFFFF',
                  shadowColor: isDark ? '#000' : '#000',
                  shadowOffset: { width: 0, height: 2 },
                  shadowOpacity: isDark ? 0.3 : 0.06,
                  shadowRadius: 8,
                  elevation: 3,
                }}
              >
                <View className="w-12 h-12 rounded-2xl items-center justify-center mb-2 bg-purple-500/15">
                  <Text className="text-2xl">📊</Text>
                </View>
                <Text className="text-xs font-semibold text-center" style={{ color: isDark ? '#D1D5DB' : '#4B5563' }}>
                  Relatórios
                </Text>
              </View>
            </AnimatedCard>
          </View>
        </FadeIn>

        <FadeIn delay={500}>
          <View className="mb-5">
            <View className="flex-row items-center justify-between mb-4">
              <Text
                className="text-lg font-bold"
                style={{ color: isDark ? '#F9FAFB' : '#111827' }}
              >
                Últimos Lançamentos
              </Text>
              <TouchableOpacity onPress={() => router.push('/(app)/(tabs)/finance/transactions')}>
                <Text className="text-sm font-semibold text-purple-500">
                  Ver Todos
                </Text>
              </TouchableOpacity>
            </View>

            {recentTransactions.length === 0 ? (
              <Card variant="filled" padding="lg">
                <Text className="text-sm text-center" style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}>
                  Nenhuma transação recente
                </Text>
              </Card>
            ) : (
              recentTransactions.slice(0, 5).map((tx, idx) => {
                const st = statusConfig[tx.status];
                const isIncome = tx.type === 'RECEITA';

                return (
                  <AnimatedCard key={tx.id} className="mb-2.5" onPress={() => {}}>
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
                          <Text
                            className="text-xs mt-0.5"
                            style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}
                          >
                            {formatDate(tx.date)}
                          </Text>
                        </View>
                        <View className="items-end">
                          <Text
                            className={`text-sm font-bold ${
                              isIncome
                                ? isDark ? 'text-green-400' : 'text-green-600'
                                : isDark ? 'text-red-400' : 'text-red-600'
                            }`}
                          >
                            {isIncome ? '+' : '-'} {formatCurrency(tx.amount)}
                          </Text>
                          <View className={`rounded-full px-2 py-0.5 mt-1 ${st.bg}`}>
                            <Text className={`text-[10px] font-semibold ${st.text}`}>
                              {st.label}
                            </Text>
                          </View>
                        </View>
                      </View>
                    </View>
                  </AnimatedCard>
                );
              })
            )}
          </View>
        </FadeIn>
      </ScrollView>
    </View>
  );
}
