import { useState, useEffect, useCallback } from 'react';
import { View, Text, ScrollView, TouchableOpacity, Linking } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useColorScheme } from '../../../src/hooks/useColorScheme';
import { schedulesService } from '../../../src/services/schedules';
import { Header, Skeleton, Badge, Card, Divider, Button, Avatar } from '../../../src/components/ui';
import { FadeIn, SlideUp } from '../../../src/components/animations';
import type { Schedule, ScheduleStatus } from '../../../src/types';

const statusConfig: Record<ScheduleStatus, { label: string; bg: string; text: string }> = {
  AGENDADO: { label: 'Agendado', bg: 'bg-blue-500', text: 'text-white' },
  CONFIRMADO: { label: 'Confirmado', bg: 'bg-green-500', text: 'text-white' },
  EM_ANDAMENTO: { label: 'Em Andamento', bg: 'bg-purple-500', text: 'text-white' },
  CONCLUIDO: { label: 'Concluído', bg: 'bg-neutral-500', text: 'text-white' },
  CANCELADO: { label: 'Cancelado', bg: 'bg-red-500', text: 'text-white' },
};

const positionStatusConfig: Record<string, { label: string; color: string }> = {
  CONFIRMADO: { label: 'Confirmado', color: '#10B981' },
  PENDENTE: { label: 'Pendente', color: '#F59E0B' },
  SUBSTITUIDO: { label: 'Substituído', color: '#3B82F6' },
  AUSENTE: { label: 'Ausente', color: '#EF4444' },
};

function formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleDateString('pt-BR', {
    weekday: 'long',
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

export default function ScheduleDetail() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { isDark, colors } = useColorScheme();
  const [schedule, setSchedule] = useState<Schedule | null>(null);
  const [loading, setLoading] = useState(true);

  const loadSchedule = useCallback(async () => {
    if (!id) return;
    try {
      const response = await schedulesService.getById(id);
      setSchedule(response);
    } catch (error) {
      console.error('Error loading schedule:', error);
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => {
    loadSchedule();
  }, [loadSchedule]);

  const handleConfirmPresence = useCallback(async () => {
    if (!schedule) return;
    try {
      const myPosition = schedule.positions?.[0];
      if (myPosition) {
        await schedulesService.updatePosition(schedule.id, myPosition.id, {
          status: 'CONFIRMADO',
        });
        loadSchedule();
      }
    } catch (error) {
      console.error('Error confirming presence:', error);
    }
  }, [schedule, loadSchedule]);

  const handleContactOrganizer = useCallback(() => {
    const phone = '5511999999999';
    Linking.openURL(`https://wa.me/${phone}`);
  }, []);

  if (loading) {
    return (
      <View className="flex-1" style={{ backgroundColor: isDark ? '#0A0A0F' : '#FFFFFF' }}>
        <View className="px-4 pt-20">
          <Skeleton variant="text" width="40%" height={20} className="mb-2" />
          <Skeleton variant="text" width="70%" height={32} className="mb-4" />
          <Skeleton variant="card" height={120} className="mb-4" />
          <Skeleton variant="card" height={200} className="mb-4" />
        </View>
      </View>
    );
  }

  if (!schedule) {
    return (
      <View className="flex-1 items-center justify-center" style={{ backgroundColor: isDark ? '#0A0A0F' : '#FFFFFF' }}>
        <Text className="text-lg" style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}>
          Escala não encontrada
        </Text>
        <Button variant="ghost" onPress={() => router.back()}>
          Voltar
        </Button>
      </View>
    );
  }

  const statusConf = statusConfig[schedule.status];
  const confirmedCount = schedule.positions?.filter(p => p.status === 'CONFIRMADO').length || 0;
  const totalPositions = schedule.positions?.length || 0;

  return (
    <View className="flex-1" style={{ backgroundColor: isDark ? '#0A0A0F' : '#FFFFFF' }}>
      <ScrollView showsVerticalScrollIndicator={false}>
        <View
          className="px-6 pt-16 pb-8 rounded-b-3xl"
          style={{
            backgroundColor: isDark ? '#1A0A2E' : '#4C1D95',
          }}
        >
          <TouchableOpacity
            onPress={() => router.back()}
            className="w-10 h-10 rounded-full items-center justify-center mb-4"
            style={{ backgroundColor: 'rgba(255,255,255,0.15)' }}
            activeOpacity={0.7}
          >
            <Text className="text-white text-lg font-bold">‹</Text>
          </TouchableOpacity>

          <FadeIn direction="up" distance={20}>
            <View className="flex-row items-center justify-between mb-4">
              <View className="flex-1 mr-3">
                <Text className="text-white/60 text-sm font-medium mb-1">
                  {schedule.eventName || 'Escala'}
                </Text>
                <Text className="text-white text-2xl font-bold leading-tight">
                  {formatDate(schedule.date)}
                </Text>
              </View>
              <View className={`px-4 py-2 rounded-full ${statusConf.bg}`}>
                <Text className={`text-xs font-bold ${statusConf.text}`}>
                  {statusConf.label}
                </Text>
              </View>
            </View>

            <View className="flex-row items-center mb-2">
              <Text className="text-white/60 text-sm mr-2">🕐</Text>
              <Text className="text-white/90 text-sm font-medium">
                {formatTimeRange(schedule.startTime, schedule.endTime)}
              </Text>
            </View>

            {schedule.ministryName && (
              <View className="flex-row items-center">
                <Text className="text-white/60 text-sm mr-2">🏛️</Text>
                <Text className="text-white/90 text-sm font-medium">
                  {schedule.ministryName}
                </Text>
              </View>
            )}
          </FadeIn>
        </View>

        <View className="px-6 -mt-4">
          <SlideUp distance={20} delay={100}>
            <Card variant="elevated" padding="lg" className="mb-4">
              <View className="flex-row items-center justify-between mb-2">
                <Text
                  className="text-sm font-semibold"
                  style={{ color: isDark ? '#F9FAFB' : '#111827' }}
                >
                  Membros
                </Text>
                <View className="flex-row items-center">
                  <View
                    className="w-2 h-2 rounded-full mr-1.5"
                    style={{ backgroundColor: '#10B981' }}
                  />
                  <Text
                    className="text-xs font-medium"
                    style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}
                  >
                    {confirmedCount}/{totalPositions} confirmados
                  </Text>
                </View>
              </View>

              {schedule.positions && schedule.positions.length > 0 ? (
                <View style={{ gap: 8 }}>
                  {schedule.positions.map((position) => {
                    const posStatus = positionStatusConfig[position.status] || {
                      label: position.status,
                      color: '#6B7280',
                    };
                    return (
                      <View
                        key={position.id}
                        className="flex-row items-center p-3 rounded-xl"
                        style={{
                          backgroundColor: isDark ? '#12121A' : '#F9FAFB',
                        }}
                      >
                        <Avatar
                          initials={position.memberName}
                          size="sm"
                          className="mr-3"
                        />
                        <View className="flex-1">
                          <Text
                            className="text-sm font-medium"
                            style={{ color: isDark ? '#F9FAFB' : '#111827' }}
                          >
                            {position.memberName || 'Membro'}
                          </Text>
                          <Text
                            className="text-xs mt-0.5"
                            style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}
                          >
                            {position.position}
                          </Text>
                        </View>
                        <View
                          className="px-3 py-1 rounded-full"
                          style={{ backgroundColor: `${posStatus.color}15` }}
                        >
                          <Text
                            className="text-xs font-semibold"
                            style={{ color: posStatus.color }}
                          >
                            {posStatus.label}
                          </Text>
                        </View>
                      </View>
                    );
                  })}
                </View>
              ) : (
                <Text
                  className="text-sm text-center py-4"
                  style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}
                >
                  Nenhum membro atribuído
                </Text>
              )}
            </Card>
          </SlideUp>

          {schedule.notes && (
            <SlideUp distance={20} delay={150}>
              <Card variant="elevated" padding="lg" className="mb-4">
                <Text
                  className="text-sm font-semibold mb-2"
                  style={{ color: isDark ? '#F9FAFB' : '#111827' }}
                >
                  Observações
                </Text>
                <Text
                  className="text-sm leading-5"
                  style={{ color: isDark ? '#D4D4D4' : '#525252' }}
                >
                  {schedule.notes}
                </Text>
              </Card>
            </SlideUp>
          )}

          <SlideUp distance={20} delay={200}>
            <Card variant="elevated" padding="lg" className="mb-6" style={{ gap: 12 }}>
              <Button
                variant="primary"
                size="lg"
                fullWidth
                onPress={handleConfirmPresence}
                leftIcon={<Text>✅</Text>}
              >
                Confirmar Presença
              </Button>

              <Button
                variant="secondary"
                size="lg"
                fullWidth
                onPress={handleContactOrganizer}
                leftIcon={<Text>📱</Text>}
              >
                Contatar Organizador
              </Button>
            </Card>
          </SlideUp>
        </View>
      </ScrollView>
    </View>
  );
}
