import { useState, useCallback } from 'react';
import { View, Text, ScrollView, TouchableOpacity, TextInput, Alert } from 'react-native';
import { useRouter } from 'expo-router';
import { useColorScheme } from '../../../src/hooks/useColorScheme';
import { eventsService } from '../../../src/services/events';
import type { EventType } from '../../../src/types/event';

const eventTypes: { value: EventType; label: string; icon: string }[] = [
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

export default function CreateEvent() {
  const router = useRouter();
  const { isDark } = useColorScheme();

  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [date, setDate] = useState('');
  const [time, setTime] = useState('');
  const [location, setLocation] = useState('');
  const [type, setType] = useState<EventType>('CULTO');
  const [loading, setLoading] = useState(false);

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
      Alert.alert('Erro', 'Data inválida. Use o formato DD/MM/YY');
      return;
    }
    const isoDate = `20${parts[2]}-${parts[1]}-${parts[0]}`;

    setLoading(true);
    try {
      await eventsService.create({
        title,
        description,
        date: isoDate,
        startTime: time,
        endTime: time,
        location,
        type: type === 'CULTO' ? 'WORSHIP' : type === 'REUNIAO' ? 'EVENT' : type === 'ESTUDO' ? 'REHEARSAL' : 'EVENT',
        isRecurring: false,
      } as any);
      Alert.alert('Sucesso', 'Evento criado com sucesso!', [
        { text: 'OK', onPress: () => router.replace('/(app)/(tabs)/calendar') }
      ]);
    } catch (error: any) {
      Alert.alert('Erro', error?.message || 'Falha ao criar evento');
    } finally {
      setLoading(false);
    }
  }, [title, description, date, time, location, type, router]);

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
        <Text style={{ fontSize: 20, fontWeight: 'bold', color: textPrimary }}>Novo Evento</Text>
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
                onPress={() => setType(item.value)}
                style={{
                  backgroundColor: type === item.value ? '#8B5CF6' : cardBg,
                  paddingHorizontal: 14,
                  paddingVertical: 8,
                  borderRadius: 20,
                  borderWidth: 1,
                  borderColor: type === item.value ? '#8B5CF6' : borderColor,
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
              placeholder="DD/MM/YY"
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
            backgroundColor: '#8B5CF6',
            borderRadius: 12,
            padding: 16,
            alignItems: 'center',
            marginBottom: 40,
          }}
        >
          <Text style={{ fontSize: 16, fontWeight: '600', color: '#FFFFFF' }}>
            {loading ? 'Criando...' : 'Criar Evento'}
          </Text>
        </TouchableOpacity>
      </ScrollView>
    </View>
  );
}