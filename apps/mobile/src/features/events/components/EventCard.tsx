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
import { Event, EventType } from '../../../types';

interface EventCardProps {
  event: Event;
  onPress?: () => void;
  index?: number;
}

const eventTypeLabels: Record<EventType, string> = {
  CULTO: 'Culto',
  REUNIAO: 'Reunião',
  ESTUDO: 'Estudo',
  EVENTO_SOCIAL: 'Evento Social',
  EVENTO_ESPECIAL: 'Evento Especial',
  ESCOLA_DOMINICAL: 'Escola Dominical',
  JEJUM: 'Jejum',
  VIGILIA: 'Vigília',
  RETIRO: 'Retiro',
  OUTRO: 'Outro',
};

const eventTypeColors: Record<EventType, string> = {
  CULTO: '#8B5CF6',
  REUNIAO: '#3B82F6',
  ESTUDO: '#10B981',
  EVENTO_SOCIAL: '#F59E0B',
  EVENTO_ESPECIAL: '#EC4899',
  ESCOLA_DOMINICAL: '#06B6D4',
  JEJUM: '#6B7280',
  VIGILIA: '#1E40AF',
  RETIRO: '#059669',
  OUTRO: '#9CA3AF',
};

function formatDate(dateStr: string): string {
  const d = new Date(dateStr);
  return d.toLocaleDateString('pt-BR', {
    day: '2-digit',
    month: 'long',
  });
}

function formatTime(timeStr: string): string {
  const [h, m] = timeStr.split(':');
  return `${h}:${m}`;
}

export function EventCard({
  event,
  onPress,
  index = 0,
}: EventCardProps) {
  const { isDark } = useColorScheme();
  const typeColor = eventTypeColors[event.type];

  const opacity = useSharedValue(0);
  const translateY = useSharedValue(30);
  const scale = useSharedValue(0.95);

  React.useEffect(() => {
    opacity.value = withDelay(
      index * 100,
      withTiming(1, { duration: 500, easing: Easing.out(Easing.cubic) })
    );
    translateY.value = withDelay(
      index * 100,
      withTiming(0, { duration: 500, easing: Easing.out(Easing.cubic) })
    );
    scale.value = withDelay(
      index * 100,
      withTiming(1, { duration: 400, easing: Easing.out(Easing.cubic) })
    );
  }, [index]);

  const animatedStyle = useAnimatedStyle(() => ({
    opacity: opacity.value,
    transform: [{ translateY: translateY.value }, { scale: scale.value }],
  }));

  return (
    <Animated.View style={animatedStyle} className="mb-4">
      <TouchableOpacity
        onPress={onPress}
        activeOpacity={0.7}
        className="rounded-2xl overflow-hidden"
        style={{
          backgroundColor: isDark ? '#1A1A2E' : '#FFFFFF',
          shadowColor: isDark ? '#000' : '#000',
          shadowOffset: { width: 0, height: 2 },
          shadowOpacity: isDark ? 0.3 : 0.06,
          shadowRadius: 8,
          elevation: 3,
        }}
      >
        <View className="h-32 relative">
          <View
            className="absolute inset-0"
            style={{
              backgroundColor: typeColor,
              opacity: 0.8,
            }}
          />
          <View
            className="absolute inset-0"
            style={{
              backgroundColor: isDark ? 'rgba(0,0,0,0.3)' : 'rgba(0,0,0,0.1)',
            }}
          />
          <View className="absolute top-0 left-0 right-0 bottom-0 p-4 justify-between">
            <View className="flex-row justify-between items-start">
              <View
                className="rounded-full px-3 py-1"
                style={{ backgroundColor: `${typeColor}CC` }}
              >
                <Text className="text-xs font-semibold text-white">
                  {eventTypeLabels[event.type]}
                </Text>
              </View>
              {event.participants && event.participants.length > 0 && (
                <View className="flex-row items-center">
                  <Text className="text-xs text-white/80 mr-1">👥</Text>
                  <Text className="text-xs font-medium text-white">
                    {event.participants.length}
                  </Text>
                </View>
              )}
            </View>
            <View>
              <Text
                className="text-lg font-bold text-white mb-1"
                numberOfLines={2}
              >
                {event.title}
              </Text>
              <View className="flex-row items-center">
                <Text className="text-xs text-white/80 mr-3">
                  {formatDate(event.date)} às {formatTime(event.time)}
                </Text>
                {event.location && (
                  <>
                    <Text className="text-xs text-white/60 mr-1">📍</Text>
                    <Text className="text-xs text-white/80" numberOfLines={1}>
                      {event.location}
                    </Text>
                  </>
                )}
              </View>
            </View>
          </View>
        </View>
      </TouchableOpacity>
    </Animated.View>
  );
}
