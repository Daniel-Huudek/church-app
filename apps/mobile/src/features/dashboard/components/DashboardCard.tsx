import React, { useEffect } from 'react';
import { View, Text, TouchableOpacity } from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withTiming,
  withDelay,
  Easing,
  interpolate,
} from 'react-native-reanimated';
import { useColorScheme } from '../../../hooks/useColorScheme';

interface DashboardCardProps {
  icon: React.ReactNode;
  title: string;
  value: string;
  trend?: {
    direction: 'up' | 'down';
    percentage: number;
  };
  color?: string;
  onPress?: () => void;
  index?: number;
}

export function DashboardCard({
  icon,
  title,
  value,
  trend,
  color = '#8B5CF6',
  onPress,
  index = 0,
}: DashboardCardProps) {
  const { isDark } = useColorScheme();
  const entryProgress = useSharedValue(0);
  const scaleProgress = useSharedValue(0);

  useEffect(() => {
    entryProgress.value = withDelay(
      index * 100,
      withTiming(1, { duration: 500, easing: Easing.out(Easing.cubic) })
    );
    scaleProgress.value = withDelay(
      index * 100,
      withTiming(1, { duration: 400, easing: Easing.out(Easing.back) })
    );
  }, [index]);

  const animatedStyle = useAnimatedStyle(() => ({
    opacity: entryProgress.value,
    transform: [
      { translateY: interpolate(entryProgress.value, [0, 1], [20, 0]) },
      { scale: interpolate(scaleProgress.value, [0, 1], [0.9, 1]) },
    ],
  }));

  return (
    <Animated.View style={animatedStyle} className="flex-1">
      <TouchableOpacity
        onPress={onPress}
        activeOpacity={0.7}
        className="rounded-2xl p-4"
        style={{
          backgroundColor: isDark ? '#1A1A2E' : '#FFFFFF',
          shadowColor: isDark ? '#000' : color,
          shadowOffset: { width: 0, height: 4 },
          shadowOpacity: isDark ? 0.3 : 0.1,
          shadowRadius: 12,
          elevation: 4,
        }}
      >
        <View
          className="w-10 h-10 rounded-xl items-center justify-center mb-3"
          style={{ backgroundColor: `${color}20` }}
        >
          {icon}
        </View>

        <Text
          className="text-xs font-medium mb-1"
          style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}
        >
          {title}
        </Text>

        <Text
          className="text-xl font-bold mb-1"
          style={{ color: isDark ? '#F9FAFB' : '#111827' }}
        >
          {value}
        </Text>

        {trend && (
          <View className="flex-row items-center">
            <Text
              className={`text-xs font-semibold ${
                trend.direction === 'up'
                  ? 'text-green-500'
                  : 'text-red-500'
              }`}
            >
              {trend.direction === 'up' ? '↑' : '↓'}{' '}
              {Math.abs(trend.percentage).toFixed(1)}%
            </Text>
            <Text
              className="text-xs ml-1"
              style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}
            >
              vs. mês anterior
            </Text>
          </View>
        )}
      </TouchableOpacity>
    </Animated.View>
  );
}
