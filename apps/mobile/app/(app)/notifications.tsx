import { useState, useCallback, useMemo } from 'react';
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  RefreshControl,
  Platform,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Stack, router } from 'expo-router';
import { useColorScheme, useNotifications } from '../../src/hooks';
import { spacing, borderRadius } from '../../src/theme';
import { EmptyState } from '../../src/components/ui';

interface GroupedNotifications {
  title: string;
  data: any[];
}

function formatRelativeDate(dateStr: string): string {
  const date = new Date(dateStr);
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

  if (diffDays === 0) return 'Hoje';
  if (diffDays === 1) return 'Ontem';
  if (diffDays < 7) return `Há ${diffDays} dias`;

  return date.toLocaleDateString('pt-BR', { day: '2-digit', month: 'short' });
}

export default function NotificationsScreen() {
  const { isDark } = useColorScheme();
  const { notifications, unreadCount, markAllAsRead, markAsRead, fetchNotifications, isLoaded } = useNotifications();
  const [refreshing, setRefreshing] = useState(false);

  const grouped = useMemo(() => {
    const groups: Record<string, any[]> = {};
    notifications.forEach((n) => {
      const key = formatRelativeDate(n.createdAt);
      if (!groups[key]) groups[key] = [];
      groups[key].push(n);
    });
    return Object.entries(groups).map(([title, data]) => ({ title, data }));
  }, [notifications]);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    try {
      await fetchNotifications();
    } catch {}
    setRefreshing(false);
  }, [fetchNotifications]);

  const notificationTypeColor = (type: string, isDark: boolean) => {
    switch (type) {
      case 'success': return isDark ? '#34D399' : '#10B981';
      case 'warning': return isDark ? '#FBBF24' : '#F59E0B';
      case 'error': return isDark ? '#F87171' : '#EF4444';
      default: return isDark ? '#60A5FA' : '#3B82F6';
    }
  };

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: isDark ? '#0A0A0F' : '#FFFFFF' }}>
      <Stack.Screen
        options={{
          headerShown: true,
          headerTitle: 'Notificações',
          headerStyle: { backgroundColor: isDark ? '#12121A' : '#FFFFFF' },
          headerTintColor: isDark ? '#F9FAFB' : '#111827',
          headerRight: () =>
            unreadCount > 0 ? (
              <TouchableOpacity
                onPress={markAllAsRead}
                style={{ marginRight: spacing.lg }}
                hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
              >
                <Text style={{ color: '#008CFF', fontSize: 14, fontWeight: '600' }}>
                  Marcar todas como lidas
                </Text>
              </TouchableOpacity>
            ) : null,
        }}
      />

      <FlatList
        data={grouped}
        keyExtractor={(item) => item.title}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={onRefresh}
            tintColor={isDark ? '#008CFF' : '#0066CC'}
          />
        }
        contentContainerStyle={{ flexGrow: 1, paddingBottom: spacing['2xl'] }}
        ListEmptyComponent={
          <EmptyState
            title="Sem notificações"
            subtitle="Você não tem notificações no momento."
          />
        }
        renderItem={({ item: group }) => (
          <View style={{ marginTop: spacing.lg }}>
            <Text
              style={{
                fontSize: 13,
                fontWeight: '600',
                color: isDark ? '#9CA3AF' : '#6B7280',
                textTransform: 'uppercase',
                letterSpacing: 0.5,
                paddingHorizontal: spacing.xl,
                marginBottom: spacing.sm,
              }}
            >
              {group.title}
            </Text>
            {group.data.map((notification: any) => (
              <TouchableOpacity
                key={notification.id}
                onPress={() => markAsRead(notification.id)}
                activeOpacity={0.7}
                style={{
                  flexDirection: 'row',
                  paddingVertical: spacing.md,
                  paddingHorizontal: spacing.xl,
                  backgroundColor: !notification.read
                    ? isDark
                      ? 'rgba(139, 92, 246, 0.08)'
                      : 'rgba(139, 92, 246, 0.05)'
                    : 'transparent',
                }}
              >
                <View
                  style={{
                    width: 8,
                    height: 8,
                    borderRadius: 4,
                    backgroundColor: !notification.read
                      ? notificationTypeColor(notification.type, isDark)
                      : 'transparent',
                    marginTop: 6,
                    marginRight: spacing.md,
                  }}
                />
                <View style={{ flex: 1 }}>
                  <View
                    style={{
                      flexDirection: 'row',
                      justifyContent: 'space-between',
                      alignItems: 'center',
                    }}
                  >
                    <Text
                      style={{
                        fontSize: 15,
                        fontWeight: notification.read ? '400' : '600',
                        color: isDark ? '#F9FAFB' : '#111827',
                        flex: 1,
                      }}
                      numberOfLines={1}
                    >
                      {notification.title}
                    </Text>
                  </View>
                  <Text
                    style={{
                      fontSize: 13,
                      color: isDark ? '#9CA3AF' : '#6B7280',
                      marginTop: 2,
                      lineHeight: 18,
                    }}
                    numberOfLines={2}
                  >
                    {notification.body}
                  </Text>
                </View>
              </TouchableOpacity>
            ))}
          </View>
        )}
      />
    </SafeAreaView>
  );
}
