import { useState, useRef } from 'react';
import {
  View,
  Text,
  TextInput,
  FlatList,
  TouchableOpacity,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { useLocalSearchParams, Stack } from 'expo-router';
import { useColorScheme } from '../../../../src/hooks';
import { spacing, borderRadius } from '../../../../src/theme';

const MOCK_MESSAGES = [
  { id: '1', text: 'Olá! Tudo bem?', sent: false, time: '10:00' },
  { id: '2', text: 'Tudo sim, graças a Deus!', sent: true, time: '10:02' },
  { id: '3', text: 'Que bom! Lembrete: ensaio hoje às 19h.', sent: false, time: '10:05' },
  { id: '4', text: 'Confirmado! Estarei lá.', sent: true, time: '10:06' },
];

export default function ChatDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { isDark } = useColorScheme();
  const [messages, setMessages] = useState(MOCK_MESSAGES);
  const [input, setInput] = useState('');
  const flatListRef = useRef<FlatList>(null);

  const chatName = id === '1' ? 'Grupo de Oração'
    : id === '2' ? 'Ministério de Louvor'
    : id === '3' ? 'Pastor João'
    : id === '4' ? 'Juventude'
    : 'Chat';

  const handleSend = () => {
    if (!input.trim()) return;
    const newMsg = {
      id: Date.now().toString(),
      text: input.trim(),
      sent: true,
      time: new Date().toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' }),
    };
    setMessages((prev) => [...prev, newMsg]);
    setInput('');
    setTimeout(() => flatListRef.current?.scrollToEnd({ animated: true }), 100);
  };

  return (
    <KeyboardAvoidingView
      style={{ flex: 1, backgroundColor: isDark ? '#0A0A0F' : '#F9FAFB' }}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      keyboardVerticalOffset={Platform.OS === 'ios' ? 90 : 0}
    >
      <Stack.Screen
        options={{
          headerShown: true,
          headerTitle: chatName,
          headerStyle: { backgroundColor: isDark ? '#12121A' : '#FFFFFF' },
          headerTintColor: isDark ? '#F9FAFB' : '#111827',
        }}
      />

      <FlatList
        ref={flatListRef}
        data={messages}
        keyExtractor={(item) => item.id}
        contentContainerStyle={{ padding: spacing.lg }}
        onContentSizeChange={() => flatListRef.current?.scrollToEnd({ animated: false })}
        renderItem={({ item }) => (
          <View
            style={{
              alignSelf: item.sent ? 'flex-end' : 'flex-start',
              maxWidth: '80%',
              marginBottom: spacing.sm,
            }}
          >
            <View
              style={{
                backgroundColor: item.sent
                  ? '#8B5CF6'
                  : isDark ? '#1F2937' : '#FFFFFF',
                paddingVertical: spacing.md,
                paddingHorizontal: spacing.lg,
                borderRadius: borderRadius.xl,
                borderBottomRightRadius: item.sent ? 4 : borderRadius.xl,
                borderBottomLeftRadius: item.sent ? borderRadius.xl : 4,
              }}
            >
              <Text style={{ color: item.sent ? '#FFFFFF' : isDark ? '#F9FAFB' : '#111827', fontSize: 15 }}>
                {item.text}
              </Text>
            </View>
            <Text
              style={{
                fontSize: 11,
                color: isDark ? '#6B7280' : '#9CA3AF',
                marginTop: 2,
                textAlign: item.sent ? 'right' : 'left',
              }}
            >
              {item.time}
            </Text>
          </View>
        )}
      />

      <View
        style={{
          flexDirection: 'row',
          alignItems: 'center',
          paddingHorizontal: spacing.lg,
          paddingVertical: spacing.sm,
          borderTopWidth: 1,
          borderTopColor: isDark ? '#1F2937' : '#E5E7EB',
          backgroundColor: isDark ? '#12121A' : '#FFFFFF',
        }}
      >
        <TextInput
          value={input}
          onChangeText={setInput}
          placeholder="Digite sua mensagem..."
          placeholderTextColor={isDark ? '#6B7280' : '#9CA3AF'}
          style={{
            flex: 1,
            backgroundColor: isDark ? '#0A0A0F' : '#F3F4F6',
            borderRadius: borderRadius.full,
            paddingHorizontal: spacing.lg,
            paddingVertical: spacing.sm,
            fontSize: 15,
            color: isDark ? '#F9FAFB' : '#111827',
            maxHeight: 100,
          }}
          multiline
        />
        <TouchableOpacity
          onPress={handleSend}
          disabled={!input.trim()}
          style={{
            width: 40,
            height: 40,
            borderRadius: 20,
            backgroundColor: input.trim() ? '#8B5CF6' : isDark ? '#374151' : '#E5E7EB',
            alignItems: 'center',
            justifyContent: 'center',
            marginLeft: spacing.sm,
          }}
        >
          <Text style={{ color: '#FFFFFF', fontSize: 18 }}>↑</Text>
        </TouchableOpacity>
      </View>
    </KeyboardAvoidingView>
  );
}
