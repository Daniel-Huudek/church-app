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
import { Prayer } from '../../../types';
import { getRelativeTime } from '../../../utils/format';

interface PrayerCardProps {
  prayer: Prayer;
  onPress?: () => void;
  onReact?: (type: string) => void;
  index?: number;
}

const reactionButtons = [
  { type: 'ORANDO', emoji: '🙏', label: 'Orando' },
  { type: 'AMEM', emoji: '❤️', label: 'Amém' },
  { type: 'GRATO', emoji: '✝️', label: 'Grato' },
];

export function PrayerCard({
  prayer,
  onPress,
  onReact,
  index = 0,
}: PrayerCardProps) {
  const { isDark } = useColorScheme();

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

  const initials = prayer.authorName
    ? prayer.authorName
        .split(' ')
        .filter((n) => n.length > 0)
        .slice(0, 2)
        .map((n) => n[0].toUpperCase())
        .join('')
    : '?';

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
          borderWidth: prayer.isUrgent ? 1 : 0,
          borderColor: prayer.isUrgent ? '#EF4444' : 'transparent',
        }}
      >
        {prayer.isUrgent && (
          <View className="flex-row items-center mb-2">
            <View className="bg-red-500 rounded-full px-2 py-0.5">
              <Text className="text-[10px] font-bold text-white uppercase tracking-wider">
                Urgente
              </Text>
            </View>
          </View>
        )}

        <View className="flex-row items-center mb-3">
          <View
            className="w-9 h-9 rounded-full items-center justify-center"
            style={{
              backgroundColor: prayer.isAnonymous ? '#9CA3AF' : '#8B5CF6',
            }}
          >
            <Text className="text-xs font-bold text-white">
              {prayer.isAnonymous ? '??' : initials}
            </Text>
          </View>
          <View className="flex-1 ml-2.5">
            <Text
              className="text-sm font-semibold"
              style={{ color: isDark ? '#F9FAFB' : '#111827' }}
            >
              {prayer.isAnonymous ? 'Anônimo' : prayer.authorName}
            </Text>
            <Text
              className="text-xs"
              style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}
            >
              {getRelativeTime(prayer.createdAt)}
            </Text>
          </View>
          {prayer.category && (
            <View
              className="rounded-full px-2.5 py-1"
              style={{
                backgroundColor: isDark
                  ? `${prayer.category.color || '#8B5CF6'}25`
                  : `${prayer.category.color || '#8B5CF6'}15`,
              }}
            >
              <Text
                className="text-xs font-medium"
                style={{
                  color: prayer.category.color || '#8B5CF6',
                }}
              >
                {prayer.category.name}
              </Text>
            </View>
          )}
        </View>

        <Text
          className="text-base font-semibold mb-1"
          style={{ color: isDark ? '#F9FAFB' : '#111827' }}
        >
          {prayer.title}
        </Text>
        <Text
          className="text-sm leading-5 mb-3"
          style={{ color: isDark ? '#D4D4D4' : '#525252' }}
          numberOfLines={3}
        >
          {prayer.description}
        </Text>

        <View
          className="flex-row items-center pt-3 mb-3"
          style={{
            borderTopWidth: 1,
            borderTopColor: isDark ? '#1F2937' : '#F3F4F6',
          }}
        >
          <View className="flex-row items-center mr-4">
            <Text className="text-xs mr-1">🙏</Text>
            <Text
              className="text-xs"
              style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}
            >
              {prayer.intercessionCount}
            </Text>
          </View>
          <View className="flex-row items-center mr-4">
            <Text className="text-xs mr-1">💬</Text>
            <Text
              className="text-xs"
              style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}
            >
              {prayer.comments?.length || 0}
            </Text>
          </View>
          {prayer.isAnswered && (
            <View className="flex-row items-center ml-auto">
              <Text className="text-xs text-green-500 font-medium">✓ Respondida</Text>
            </View>
          )}
        </View>

        <View className="flex-row gap-2">
          {reactionButtons.map((reaction) => {
            const isActive = prayer.reactions?.some(
              (r) => r.type === reaction.type
            );
            return (
              <TouchableOpacity
                key={reaction.type}
                onPress={() => onReact?.(reaction.type)}
                activeOpacity={0.6}
                className={`flex-row items-center rounded-full px-3 py-1.5 ${
                  isActive
                    ? isDark
                      ? 'bg-purple-900/40'
                      : 'bg-purple-100'
                    : isDark
                    ? 'bg-neutral-800'
                    : 'bg-neutral-100'
                }`}
              >
                <Text className="text-sm mr-1">{reaction.emoji}</Text>
                <Text
                  className={`text-xs font-medium ${
                    isActive
                      ? 'text-purple-600'
                      : isDark
                      ? 'text-neutral-400'
                      : 'text-neutral-500'
                  }`}
                >
                  {reaction.label}
                </Text>
              </TouchableOpacity>
            );
          })}
        </View>
      </TouchableOpacity>
    </Animated.View>
  );
}
