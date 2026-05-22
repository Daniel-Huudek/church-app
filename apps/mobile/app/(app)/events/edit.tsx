import { useState, useEffect, useCallback } from 'react';
import { View, Text, ScrollView, TouchableOpacity, TextInput, Alert } from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { useColorScheme } from '../../../src/hooks/useColorScheme';
import { eventsService } from '../../../src/services/events';
import type { Event, EventType } from '../../../src/types/event';

const eventTypes: { value: string; label: string; icon: string }[] = [
  { value: 'CULTO', label: 'Culto', icon: '✝️' },
  { value: 'REUNIAO', label: 'Reunião', icon: '👥' },
  { value: 'ESTUDO', label: 'Estudo', icon: '📖' },
  { value: 'EVENTO_SOCIAL', label: 'Social', icon: '🎉' },
  { value: 'EVENTO_ESPECIAL', label: 'Especial', icon: '⭐' },
  { value: 'ESCOLA_DOMINICAL', label: 'Escola Dominical', icon: '📚' },
  { value: 'JEJUM', label: 'Jejum', icon: '🙏' },
  { value: 'VIGILIA', label: 'Vigília', icon: '🌙' },
  { value: 'RETIRO', label: 'Retiro', icon: '🏕️' },
  { value: 'OUTRO', label: 'Outro', icon: '📌' },
];

export default function EditEvent() {
  const router = useRouter();
  const { id } = useLocalSearchParams<{ id: string }>();
  const { isDark } = useColorScheme();

  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [date, setDate] = useState('');
  const [time, setTime] = useState('');
  const [location, setLocation] = useState('');
  const [type, setType] = useState<EventType>('CULTO');
  const [loading, setLoading] = useState(false);
  const [initialLoading, setInitialLoading] = useState(true);

  useEffect(() => {
    loadEvent();
  }, [id]);

  const loadEvent = async () => {
    try {
      const event = await eventsService.getById(id);
      setTitle(event.title);
      setDescription(event.description || '');
      const dateObj = new Date(event.date);
      setDate(`${String(dateObj.getDate()).padStart(2, '0')}/${String(dateObj.getMonth() + 1).padStart(2, '0')}/${dateObj.getFullYear()}`);
      setTime(event.time);
      setLocation(event.location || '');
      setType(event.type as EventType);
    } catch (error) {
      Alert.alert('Erro', 'Falha ao carregar evento');
      router.back();
    } finally {
      setInitialLoading(false);
    }
  };

  const handleSave = useCallback(async () => {
    if (!title.trim()) {
      Alert.alert('Erro', 'Por favor, insira o título do evento');
      return;
    }
    if (!date.trim()) {
      Alert.alert('Erro', 'Por favor, insira a data do evento');
      return;
    }
    if (!time.trim()) {
      Alert.alert('Erro', 'Por favor, insira o horário do evento');
      return;
    }

    const parts = date.split('/');
    if (parts.length !== 3) {
      Alert.alert('Erro', 'Data inválida. Use o formato DD/MM/YYYY');
      return;
    }
    const isoDate = `${parts[2]}-${parts[1]}-${parts[0]}`;

    setLoading(true);
    try {
      await eventsService.update(id, {
        title,
        description,
        date: isoDate,
        startTime: time,
        endTime: time,
        location,
        type: type === 'CULTO' ? 'WORSHIP' : type === 'REUNIAO' ? 'EVENT' : type === 'ESTUDO' ? 'REHEARSAL' : 'EVENT',
      } as any);
      Alert.alert('Sucesso', 'Evento atualizado!', [
        { text: 'OK', onPress: () => router.back() }
      ]);
    } catch (error: any) {
      Alert.alert('Erro', error?.message || 'Falha ao atualizar evento');
    } finally {
      setLoading(false);
    }
  }, [title, description, date, time, location, type, id, router]);

  if (initialLoading) {
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
        <Text style={{ fontSize: 20, fontWeight: 'bold', color: textPrimary }}>Editar Evento</Text>
        <View style={{ width: 30 }} />
      </View>

      <ScrollView showsVerticalScrollIndicator={false} style={{ flex: 1, paddingHorizontal: 20 }}>
        <View style={{ marginBottom: 20 }}>
          <Text style={{ fontSize: 14, color: textSecondary, marginBottom: 8 }}>Título</Text>
          <View style={{ backgroundColor: cardBg, borderRadius: 12, borderWidth: 1, borderColor }}>
            <TextInput
              value={title}
              onChangeText={setTitle}
              placeholder="Nome do evento"
              placeholderTextColor={textSecondary}
              style={{ padding: 16, fontSize: 16, color: textPrimary }}
            />
          </View>
        </View>

        <View style={{ marginBottom: 20 }}>
          <Text style={{ fontSize: 14, color: textSecondary, marginBottom: 8 }}>Tipo de Evento</Text>
          <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8 }}>
            {eventTypes.map((item) => (
              <TouchableOpacity
                key={item.value}
                onPress={() => setType(item.value as EventType)}
                style={{
                  backgroundColor: type === item.value ? '#008CFF' : cardBg,
                  paddingHorizontal: 14,
                  paddingVertical: 8,
                  borderRadius: 20,
                  borderWidth: 1,
                  borderColor: type === item.value ? '#008CFF' : borderColor,
                }}
              >
                <Text style={{ fontSize: 14, color: type === item.value ? '#FFFFFF' : textPrimary }}>
                  {item.icon} {item.label}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>

        <View style={{ marginBottom: 20 }}>
          <Text style={{ fontSize: 14, color: textSecondary, marginBottom: 8 }}>Data</Text>
          <View style={{ backgroundColor: cardBg, borderRadius: 12, borderWidth: 1, borderColor }}>
            <TextInput
              value={date}
              onChangeText={setDate}
              placeholder="DD/MM/YYYY"
              placeholderTextColor={textSecondary}
              style={{ padding: 16, fontSize: 16, color: textPrimary }}
            />
          </View>
        </View>

        <View style={{ marginBottom: 20 }}>
          <Text style={{ fontSize: 14, color: textSecondary, marginBottom: 8 }}>Horário</Text>
          <View style={{ backgroundColor: cardBg, borderRadius: 12, borderWidth: 1, borderColor }}>
            <TextInput
              value={time}
              onChangeText={setTime}
              placeholder="19:00"
              placeholderTextColor={textSecondary}
              style={{ padding: 16, fontSize: 16, color: textPrimary }}
            />
          </View>
        </View>

        <View style={{ marginBottom: 20 }}>
          <Text style={{ fontSize: 14, color: textSecondary, marginBottom: 8 }}>Local</Text>
          <View style={{ backgroundColor: cardBg, borderRadius: 12, borderWidth: 1, borderColor }}>
            <TextInput
              value={location}
              onChangeText={setLocation}
              placeholder="Endereço do evento"
              placeholderTextColor={textSecondary}
              style={{ padding: 16, fontSize: 16, color: textPrimary }}
            />
          </View>
        </View>

        <View style={{ marginBottom: 40 }}>
          <Text style={{ fontSize: 14, color: textSecondary, marginBottom: 8 }}>Descrição</Text>
          <View style={{ backgroundColor: cardBg, borderRadius: 12, borderWidth: 1, borderColor }}>
            <TextInput
              value={description}
              onChangeText={setDescription}
              placeholder="Detalhes do evento..."
              placeholderTextColor={textSecondary}
              multiline
              numberOfLines={4}
              textAlignVertical="top"
              style={{ padding: 16, fontSize: 16, color: textPrimary, minHeight: 100 }}
            />
          </View>
        </View>

        <TouchableOpacity
          onPress={handleSave}
          disabled={loading}
          style={{
            backgroundColor: '#008CFF',
            borderRadius: 12,
            padding: 16,
            alignItems: 'center',
            marginBottom: 40,
          }}
        >
          <Text style={{ fontSize: 16, fontWeight: '600', color: '#FFFFFF' }}>
            {loading ? 'Salvando...' : 'Salvar Alterações'}
          </Text>
        </TouchableOpacity>
      </ScrollView>
    </View>
  );
}