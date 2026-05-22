import React from 'react';
import { View, Text, TouchableOpacity } from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withTiming,
  withDelay,
  Easing,
} from 'react-native-reanimated';
import { useColorScheme } from '../../../hooks/useColorScheme';
import { Transaction } from '../../../types';
import { formatCurrency, formatDate } from '../../../utils/format';

interface FinanceCardProps {
  transaction: Transaction;
  onPress?: () => void;
  index?: number;
}

const statusConfig: Record<
  Transaction['status'],
  { label: string; bg: string; text: string }
> = {
  CONFIRMADO: { label: 'Confirmado', bg: 'bg-green-500/10', text: 'text-green-600' },
  PENDENTE: { label: 'Pendente', bg: 'bg-amber-500/10', text: 'text-amber-600' },
  CANCELADO: { label: 'Cancelado', bg: 'bg-red-500/10', text: 'text-red-600' },
};

export function FinanceCard({
  transaction,
  onPress,
  index = 0,
}: FinanceCardProps) {
  const { isDark } = useColorScheme();
  const isIncome = transaction.type === 'RECEITA';

  const opacity = useSharedValue(0);
  const translateY = useSharedValue(20);

  React.useEffect(() => {
    opacity.value = withDelay(
      index * 80,
      withTiming(1, { duration: 500, easing: Easing.out(Easing.cubic) })
    );
    translateY.value = withDelay(
      index * 80,
      withTiming(0, { duration: 500, easing: Easing.out(Easing.cubic) })
    );
  }, [index]);

  const animatedStyle = useAnimatedStyle(() => ({
    opacity: opacity.value,
    transform: [{ translateY: translateY.value }],
  }));

  const st = statusConfig[transaction.status];

  return (
    <Animated.View style={animatedStyle} className="mb-3">
      <TouchableOpacity
        onPress={onPress}
        activeOpacity={0.7}
        className="rounded-2xl p-4"
        style={{
          backgroundColor: isDark ? '#1A1A2E' : '#FFFFFF',
          shadowColor: isDark ? '#000' : '#000',
          shadowOffset: { width: 0, height: 2 },
          shadowOpacity: isDark ? 0.3 : 0.06,
          shadowRadius: 8,
          elevation: 3,
        }}
      >
        <View className="flex-row items-start justify-between mb-3">
          <View className="flex-row items-center flex-1">
            <View
              className={`w-10 h-10 rounded-xl items-center justify-center ${
                isIncome ? 'bg-green-500/15' : 'bg-red-500/15'
              }`}
            >
              <Text className={`text-lg ${isIncome ? 'text-green-500' : 'text-red-500'}`}>
                {isIncome ? '📈' : '📉'}
              </Text>
            </View>
            <View className="ml-3 flex-1">
              <Text
                className="text-base font-semibold"
                style={{ color: isDark ? '#F9FAFB' : '#111827' }}
                numberOfLines={1}
              >
                {transaction.description}
              </Text>
              <Text
                className="text-xs mt-0.5"
                style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}
              >
                {transaction.categoryName}
              </Text>
            </View>
          </View>
          <Text
            className={`text-base font-bold ${
              isIncome
                ? isDark ? 'text-green-400' : 'text-green-600'
                : isDark ? 'text-red-400' : 'text-red-600'
            }`}
          >
            {isIncome ? '+' : '-'} {formatCurrency(transaction.amount)}
          </Text>
        </View>

        <View className="flex-row items-center">
          <Text
            className="text-xs"
            style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}
          >
            {formatDate(transaction.date)}
          </Text>
          <View className={`ml-auto rounded-full px-2.5 py-0.5 ${st.bg}`}>
            <Text className={`text-[10px] font-semibold ${st.text}`}>
              {st.label}
            </Text>
          </View>
        </View>
      </TouchableOpacity>
    </Animated.View>
  );
}
