import React from 'react';
import { View, Text, TouchableOpacity } from 'react-native';
import { useColorScheme } from '../../../hooks/useColorScheme';
import { Schedule, ScheduleStatus } from '../../../types';
import { FadeIn } from '../../../components/animations/FadeIn';

interface ScheduleCardProps {
  schedule: Schedule;
  onPress?: () => void;
  index?: number;
}

const statusConfig: Record<
  ScheduleStatus,
  { label: string; bg: string; text: string }
> = {
  AGENDADO: { label: 'Agendado', bg: 'bg-blue-500/10', text: 'text-blue-600' },
  CONFIRMADO: {
    label: 'Confirmado',
    bg: 'bg-green-500/10',
    text: 'text-green-600',
  },
  EM_ANDAMENTO: {
    label: 'Em Andamento',
    bg: 'bg-purple-500/10',
    text: 'text-purple-600',
  },
  CONCLUIDO: {
    label: 'Concluído',
    bg: 'bg-neutral-500/10',
    text: 'text-neutral-600',
  },
  CANCELADO: {
    label: 'Cancelado',
    bg: 'bg-red-500/10',
    text: 'text-red-600',
  },
};

function formatDate(dateStr: string): string {
  const d = new Date(dateStr);
  return d.toLocaleDateString('pt-BR', {
    day: '2-digit',
    month: 'long',
    year: 'numeric',
  });
}

function formatTimeRange(start: string, end: string): string {
  const fmt = (t: string) => {
    const [h, m] = t.split(':');
    return `${h}:${m}`;
  };
  return `${fmt(start)} - ${fmt(end)}`;
}

export function ScheduleCard({
  schedule,
  onPress,
  index = 0,
}: ScheduleCardProps) {
  const { isDark } = useColorScheme();
  const config = statusConfig[schedule.status];

  const confirmedCount = schedule.positions?.filter(
    (p) => p.status === 'CONFIRMADO'
  ).length;
  const totalPositions = schedule.positions?.length || 0;

  return (
    <FadeIn direction="up" delay={index * 80} distance={20}>
      <TouchableOpacity
        onPress={onPress}
        activeOpacity={0.7}
        className="rounded-2xl p-4 mb-3"
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
          <View className="flex-1 mr-3">
            <Text
              className="text-sm font-bold"
              style={{ color: isDark ? '#F9FAFB' : '#111827' }}
            >
              {formatDate(schedule.date)}
            </Text>
            <Text
              className="text-xs mt-0.5"
              style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}
            >
              {formatTimeRange(schedule.startTime, schedule.endTime)}
            </Text>
          </View>
          <View className={`rounded-full px-3 py-1 ${config.bg}`}>
            <Text className={`text-xs font-semibold ${config.text}`}>
              {config.label}
            </Text>
          </View>
        </View>

        {schedule.ministryName && (
          <View className="flex-row items-center mb-2">
            <Text
              className="text-xs"
              style={{ color: isDark ? '#A78BFA' : '#7C3AED' }}
            >
              ◆
            </Text>
            <Text
              className="text-xs ml-1.5 font-medium"
              style={{ color: isDark ? '#D4D4D4' : '#525252' }}
            >
              {schedule.ministryName}
            </Text>
          </View>
        )}

        {schedule.eventName && (
          <Text
            className="text-sm mb-3"
            style={{ color: isDark ? '#A3A3A3' : '#6B7280' }}
          >
            {schedule.eventName}
          </Text>
        )}

        {totalPositions > 0 && (
          <View
            className="flex-row items-center pt-3"
            style={{
              borderTopWidth: 1,
              borderTopColor: isDark ? '#1F2937' : '#F3F4F6',
            }}
          >
            <Text
              className="text-xs font-medium"
              style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}
            >
              {confirmedCount}/{totalPositions} membros confirmados
            </Text>
            <View className="flex-row ml-auto">
              {schedule.positions?.slice(0, 3).map((pos, i) => (
                <View
                  key={pos.id}
                  className="w-6 h-6 rounded-full items-center justify-center -ml-1.5"
                  style={{
                    backgroundColor: isDark ? '#374151' : '#E5E7EB',
                    borderWidth: 1.5,
                    borderColor: isDark ? '#1A1A2E' : '#FFFFFF',
                    zIndex: 3 - i,
                  }}
                >
                  <Text className="text-[10px] font-bold text-purple-600">
                    {pos.memberName
                      ? pos.memberName.charAt(0).toUpperCase()
                      : '?'}
                  </Text>
                </View>
              ))}
              {totalPositions > 3 && (
                <View className="w-6 h-6 rounded-full items-center justify-center -ml-1.5">
                  <Text
                    className="text-[10px] font-medium"
                    style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}
                  >
                    +{totalPositions - 3}
                  </Text>
                </View>
              )}
            </View>
          </View>
        )}
      </TouchableOpacity>
    </FadeIn>
  );
}
