import { useState, useEffect, useCallback } from 'react';
import { View, Text, ScrollView, TouchableOpacity, Alert } from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { useColorScheme } from '../../../src/hooks/useColorScheme';
import { usePermission } from '../../../src/hooks/usePermission';
import { eventsService } from '../../../src/services/events';
import type { Event } from '../../../src/types/event';

export default function EventDetail() {
  const router = useRouter();
  const { id } = useLocalSearchParams<{ id: string }>();
  const { isDark } = useColorScheme();
  const { canEditEvent, canDeleteEvent } = usePermission();

  const [event, setEvent] = useState<Event | null>(null);
  const [loading, setLoading] = useState(true);

  const canEdit = canEditEvent();
  const canDelete = canDeleteEvent();

  useEffect(() => {
    loadEvent();
  }, [id]);

  const loadEvent = async () => {
    try {
      const data = await eventsService.getById(id);
      setEvent(data);
    } catch (error) {
      Alert.alert('Erro', 'Falha ao carregar evento');
      router.back();
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = useCallback(() => {
    if (!canEdit) return;
    
    Alert.alert(
      'Excluir Evento',
      'Tem certeza que deseja excluir este evento? Esta ação não pode ser desfeita.',
      [
        { text: 'Cancelar', style: 'cancel' },
        {
          text: 'Excluir',
          style: 'destructive',
          onPress: async () => {
            try {
              await eventsService.delete(id);
              Alert.alert('Sucesso', 'Evento excluído!', [
                { text: 'OK', onPress: () => router.back() }
              ]);
            } catch (error) {
              Alert.alert('Erro', 'Falha ao excluir evento');
            }
          },
        },
      ]
    );
  }, [id, canEdit, router]);

  const handleEdit = useCallback(() => {
    if (!canEdit) return;
    router.push(`/(app)/events/edit?id=${id}`);
  }, [id, canEdit, router]);

  if (loading || !event) {
    return (
      <View style={{ flex: 1, backgroundColor: isDark ? '#0A0A0F' : '#F8FAFC', alignItems: 'center', justifyContent: 'center' }}>
        <Text style={{ color: isDark ? '#F9FAFB' : '#111827' }}>Carregando...</Text>
      </View>
    );
  }

  const bgColor = isDark ? '#0A0A0F' : '#F8FAFC';
  const cardBg = isDark ? '#1A1A2E' : '#FFFFFF';
  const textPrimary = isDark ? '#F9FAFB' : '#111827';
  const textSecondary = isDark ? '#9CA3AF' : '#6B7280';
  const borderColor = isDark ? '#1F2937' : '#E5E7EB';

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('pt-BR', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' });
  };

  return (
    <View style={{ flex: 1, backgroundColor: bgColor }}>
      <View style={{ 
        flexDirection: 'row', 
        alignItems: 'center', 
        justifyContent: 'space-between',
        paddingHorizontal: 20,
        paddingTop: 50,
        paddingBottom: 16,
      }}>
        <TouchableOpacity onPress={() => router.back()}>
          <Text style={{ fontSize: 24, color: textPrimary }}>←</Text>
        </TouchableOpacity>
        <Text style={{ fontSize: 20, fontWeight: 'bold', color: textPrimary }}>Detalhes</Text>
        {canEdit ? (
          <TouchableOpacity onPress={handleEdit}>
            <Text style={{ fontSize: 18, color: '#008CFF' }}>✏️</Text>
          </TouchableOpacity>
        ) : <View style={{ width: 24 }} />}
      </View>

      <ScrollView showsVerticalScrollIndicator={false} style={{ flex: 1, paddingHorizontal: 20 }}>
        <Text style={{ fontSize: 28, fontWeight: 'bold', color: textPrimary, marginBottom: 8 }}>
          {event.title}
        </Text>

        <View style={{ flexDirection: 'row', alignItems: 'center', gap: 12, marginBottom: 24 }}>
          <View style={{ backgroundColor: '#008CFF20', paddingHorizontal: 12, paddingVertical: 4, borderRadius: 12 }}>
            <Text style={{ fontSize: 14, color: '#008CFF' }}>{event.type}</Text>
          </View>
          <View style={{ backgroundColor: event.status === 'CONFIRMADO' ? '#10B98120' : '#F59E0B20', paddingHorizontal: 12, paddingVertical: 4, borderRadius: 12 }}>
            <Text style={{ fontSize: 14, color: event.status === 'CONFIRMADO' ? '#10B981' : '#F59E0B' }}>
              {event.status}
            </Text>
          </View>
        </View>

        <View style={{ backgroundColor: cardBg, borderRadius: 16, padding: 16, marginBottom: 16, gap: 16 }}>
          <View style={{ flexDirection: 'row', alignItems: 'center', gap: 12 }}>
            <View style={{ width: 40, height: 40, borderRadius: 20, backgroundColor: '#008CFF20', alignItems: 'center', justifyContent: 'center' }}>
              <Text style={{ fontSize: 18 }}>📅</Text>
            </View>
            <View>
              <Text style={{ fontSize: 12, color: textSecondary }}>Data</Text>
              <Text style={{ fontSize: 16, color: textPrimary }}>{formatDate(event.date)}</Text>
            </View>
          </View>

          <View style={{ flexDirection: 'row', alignItems: 'center', gap: 12 }}>
            <View style={{ width: 40, height: 40, borderRadius: 20, backgroundColor: '#3B82F620', alignItems: 'center', justifyContent: 'center' }}>
              <Text style={{ fontSize: 18 }}>🕐</Text>
            </View>
            <View>
              <Text style={{ fontSize: 12, color: textSecondary }}>Horário</Text>
              <Text style={{ fontSize: 16, color: textPrimary }}>{event.time}</Text>
            </View>
          </View>

          {event.location && (
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 12 }}>
              <View style={{ width: 40, height: 40, borderRadius: 20, backgroundColor: '#10B98120', alignItems: 'center', justifyContent: 'center' }}>
                <Text style={{ fontSize: 18 }}>📍</Text>
              </View>
              <View>
                <Text style={{ fontSize: 12, color: textSecondary }}>Local</Text>
                <Text style={{ fontSize: 16, color: textPrimary }}>{event.location}</Text>
              </View>
            </View>
          )}
        </View>

        {event.description && (
          <View style={{ backgroundColor: cardBg, borderRadius: 16, padding: 16, marginBottom: 16 }}>
            <Text style={{ fontSize: 14, fontWeight: '600', color: textPrimary, marginBottom: 8 }}>Descrição</Text>
            <Text style={{ fontSize: 14, color: textSecondary, lineHeight: 20 }}>{event.description}</Text>
          </View>
        )}

        {canEdit && (
          <TouchableOpacity
            onPress={handleDelete}
            style={{
              backgroundColor: '#EF444420',
              borderRadius: 12,
              padding: 16,
              alignItems: 'center',
              marginBottom: 40,
            }}
          >
            <Text style={{ fontSize: 16, color: '#EF4444', fontWeight: '600' }}>Excluir Evento</Text>
          </TouchableOpacity>
        )}
      </ScrollView>
    </View>
  );
}