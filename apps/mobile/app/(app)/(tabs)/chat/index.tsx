import { View, Text, FlatList, TouchableOpacity, RefreshControl } from 'react-native';
import { useRouter } from 'expo-router';
import { useState, useEffect, useCallback } from 'react';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useColorScheme } from '../../../../src/hooks';
import { spacing, borderRadius } from '../../../../src/theme';

const MOCK_CHATS = [
  { id: '1', name: 'Grupo de Oração', lastMessage: 'Amém! 🙏', time: '10:30', unread: 2 },
  { id: '2', name: 'Ministério de Louvor', lastMessage: 'Ensaio amanhã às 19h', time: '09:15', unread: 0 },
  { id: '3', name: 'Pastor João', lastMessage: 'Deus abençoe!', time: 'Ontem', unread: 1 },
  { id: '4', name: 'Juventude', lastMessage: 'Evento sábado!', time: 'Ontem', unread: 0 },
];

export default function ChatListScreen() {
  const router = useRouter();
  const { isDark } = useColorScheme();
  const [refreshing, setRefreshing] = useState(false);
  const [chats, setChats] = useState(MOCK_CHATS);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    setTimeout(() => setRefreshing(false), 1000);
  }, []);

  const formatTime = (time: string) => time;

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: isDark ? '#0A0A0F' : '#FFFFFF' }}>
      <FlatList
        data={chats}
        keyExtractor={(item) => item.id}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={isDark ? '#8B5CF6' : '#7C3AED'} />
        }
        contentContainerStyle={{ flexGrow: 1 }}
        ListHeaderComponent={
          <View style={{ paddingHorizontal: spacing.xl, paddingVertical: spacing.lg }}>
            <Text style={{ fontSize: 28, fontWeight: '700', color: isDark ? '#F9FAFB' : '#111827' }}>
              Conversas
            </Text>
          </View>
        }
        ListEmptyComponent={
          <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', paddingTop: 80 }}>
            <Text style={{ fontSize: 16, color: isDark ? '#6B7280' : '#9CA3AF' }}>Nenhuma conversa</Text>
          </View>
        }
        renderItem={({ item }) => (
          <TouchableOpacity
            activeOpacity={0.7}
            onPress={() => router.push(`/(app)/(tabs)/chat/${item.id}`)}
            style={{
              flexDirection: 'row',
              alignItems: 'center',
              paddingVertical: spacing.md,
              paddingHorizontal: spacing.xl,
            }}
          >
            <View
              style={{
                width: 52,
                height: 52,
                borderRadius: 26,
                backgroundColor: 'rgba(139, 92, 246, 0.15)',
                alignItems: 'center',
                justifyContent: 'center',
                marginRight: spacing.md,
              }}
            >
              <Text style={{ fontSize: 20, fontWeight: '600', color: '#A78BFA' }}>
                {item.name.charAt(0).toUpperCase()}
              </Text>
            </View>
            <View style={{ flex: 1 }}>
              <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' }}>
                <Text style={{ fontSize: 16, fontWeight: '600', color: isDark ? '#F9FAFB' : '#111827' }}>
                  {item.name}
                </Text>
                <Text style={{ fontSize: 12, color: isDark ? '#6B7280' : '#9CA3AF' }}>
                  {formatTime(item.time)}
                </Text>
              </View>
              <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginTop: 2 }}>
                <Text
                  style={{ fontSize: 14, color: isDark ? '#9CA3AF' : '#6B7280', flex: 1 }}
                  numberOfLines={1}
                >
                  {item.lastMessage}
                </Text>
                {item.unread > 0 && (
                  <View
                    style={{
                      backgroundColor: '#8B5CF6',
                      minWidth: 20,
                      height: 20,
                      borderRadius: 10,
                      alignItems: 'center',
                      justifyContent: 'center',
                      paddingHorizontal: 6,
                      marginLeft: spacing.sm,
                    }}
                  >
                    <Text style={{ color: '#FFFFFF', fontSize: 11, fontWeight: '700' }}>
                      {item.unread}
                    </Text>
                  </View>
                )}
              </View>
            </View>
          </TouchableOpacity>
        )}
      />
    </SafeAreaView>
  );
}
