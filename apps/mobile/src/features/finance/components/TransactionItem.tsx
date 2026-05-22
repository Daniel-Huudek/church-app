import React, { useRef } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  Animated as RNAnimated,
  PanResponder,
} from 'react-native';
import { useColorScheme } from '../../../hooks/useColorScheme';
import { Transaction } from '../../../types';
import { formatCurrency, formatDate } from '../../../utils/format';

interface TransactionItemProps {
  transaction: Transaction;
  onPress?: () => void;
  onEdit?: () => void;
  onDelete?: () => void;
}

const categoryIcons: Record<string, string> = {
  DIZIMO: '💰',
  OFERTA: '🙏',
  SALARIO: '💼',
  ALUGUEL: '🏠',
  AGUA: '💧',
  LUZ: '⚡',
  TELEFONE: '📞',
  INTERNET: '🌐',
  ALIMENTACAO: '🍞',
  TRANSPORTE: '🚗',
  SAUDE: '🏥',
  EDUCACAO: '📚',
  MANUTENCAO: '🔧',
  EVENTO: '🎉',
  MISSÕES: '🌍',
  SOCIAL: '🤝',
  OUTRO: '📋',
  DEFAULT: '💳',
};

function getIcon(categoryName: string): string {
  const key = categoryName
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toUpperCase()
    .replace(/[^A-Z]/g, '');
  for (const [k, v] of Object.entries(categoryIcons)) {
    if (key.includes(k)) return v;
  }
  return categoryIcons.DEFAULT;
}

export function TransactionItem({
  transaction,
  onPress,
  onEdit,
  onDelete,
}: TransactionItemProps) {
  const { isDark } = useColorScheme();
  const isIncome = transaction.type === 'RECEITA';
  const translateX = useRef(new RNAnimated.Value(0)).current;
  const swipeableThreshold = -80;

  const panResponder = useRef(
    PanResponder.create({
      onMoveShouldSetPanResponder: (_, gestureState) =>
        Math.abs(gestureState.dx) > 10 && Math.abs(gestureState.dx) > Math.abs(gestureState.dy),
      onPanResponderMove: (_, gestureState) => {
        if (gestureState.dx < 0) {
          translateX.setValue(Math.max(gestureState.dx, -160));
        }
      },
      onPanResponderRelease: (_, gestureState) => {
        if (gestureState.dx < swipeableThreshold) {
          RNAnimated.spring(translateX, {
            toValue: -120,
            useNativeDriver: true,
          }).start();
        } else {
          RNAnimated.spring(translateX, {
            toValue: 0,
            useNativeDriver: true,
          }).start();
        }
      },
    })
  ).current;

  const resetSwipe = () => {
    RNAnimated.spring(translateX, {
      toValue: 0,
      useNativeDriver: true,
    }).start();
  };

  return (
    <View className="mb-2 overflow-hidden rounded-xl">
      <View
        className="absolute right-0 top-0 bottom-0 flex-row"
        style={{ width: 120 }}
      >
        {onEdit && (
          <TouchableOpacity
            onPress={() => { resetSwipe(); onEdit(); }}
            className="flex-1 items-center justify-center bg-blue-500"
          >
            <Text className="text-white text-xs font-semibold">Editar</Text>
          </TouchableOpacity>
        )}
        {onDelete && (
          <TouchableOpacity
            onPress={() => { resetSwipe(); onDelete(); }}
            className="flex-1 items-center justify-center bg-red-500"
          >
            <Text className="text-white text-xs font-semibold">Excluir</Text>
          </TouchableOpacity>
        )}
      </View>

      <RNAnimated.View
        style={{ transform: [{ translateX }] }}
        {...(onEdit || onDelete ? panResponder.panHandlers : {})}
      >
        <TouchableOpacity
          onPress={onPress}
          activeOpacity={0.7}
          className="flex-row items-center px-4 py-3.5 rounded-xl"
          style={{
            backgroundColor: isDark ? '#1A1A2E' : '#FFFFFF',
          }}
        >
          <View
            className={`w-10 h-10 rounded-xl items-center justify-center ${
              isIncome ? 'bg-green-500/15' : 'bg-red-500/15'
            }`}
          >
            <Text className="text-base">
              {getIcon(transaction.categoryName)}
            </Text>
          </View>

          <View className="flex-1 mx-3">
            <Text
              className="text-sm font-semibold"
              style={{ color: isDark ? '#F9FAFB' : '#111827' }}
              numberOfLines={1}
            >
              {transaction.description}
            </Text>
            <View className="flex-row items-center mt-0.5">
              <Text
                className="text-xs"
                style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}
              >
                {formatDate(transaction.date)}
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
                {transaction.categoryName}
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
            {isIncome ? '+' : '-'} {formatCurrency(transaction.amount)}
          </Text>
        </TouchableOpacity>
      </RNAnimated.View>
    </View>
  );
}
