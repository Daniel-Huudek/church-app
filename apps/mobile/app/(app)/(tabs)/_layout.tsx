import { Tabs } from 'expo-router';
import { View, Text, TouchableOpacity, Keyboard, Platform } from 'react-native';
import { useEffect, useState } from 'react';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { useAuth } from '../../../src/hooks';
import { useColorScheme, useNotifications } from '../../../src/hooks';
import { spacing, borderRadius, iconSize } from '../../../src/theme';

type TabIcon = 'home' | 'calendar' | 'chat' | 'finance' | 'profile';

function TabIconComponent({ name, focused, isDark }: { name: TabIcon; focused: boolean; isDark: boolean }) {
  const color = focused ? '#8B5CF6' : isDark ? '#525252' : '#A3A3A3';

  const icons: Record<TabIcon, string> = {
    home: focused ? '🏠' : '🏠',
    calendar: focused ? '📅' : '📅',
    chat: focused ? '💬' : '💬',
    finance: focused ? '💰' : '💰',
    profile: focused ? '👤' : '👤',
  };

  return (
    <Text style={{ fontSize: iconSize.lg, opacity: focused ? 1 : 0.5 }}>
      {icons[name]}
    </Text>
  );
}

function MyTabBar({ state, descriptors, navigation }: any) {
  const { isDark } = useColorScheme();
  const insets = useSafeAreaInsets();
  const { unreadCount } = useNotifications();
  const { hasRole } = useAuth();
  const [keyboardVisible, setKeyboardVisible] = useState(false);
  const canAccessFinance = hasRole(['ADMINISTRADOR', 'PASTOR', 'FINANCEIRO']);

  useEffect(() => {
    const showSub = Keyboard.addListener('keyboardDidShow', () => setKeyboardVisible(true));
    const hideSub = Keyboard.addListener('keyboardDidHide', () => setKeyboardVisible(false));
    return () => {
      showSub.remove();
      hideSub.remove();
    };
  }, []);

  if (keyboardVisible) return null;

  const filteredRoutes = state.routes.filter((route: any) => {
    if (route.name === 'finance/index') return canAccessFinance;
    if (route.name === 'chat/index') return true;
    return true;
  });

  const routeLabels: Record<string, string> = {
    index: 'Início',
    calendar: 'Agenda',
    'chat/index': 'Chat',
    'finance/index': 'Finanças',
    profile: 'Perfil',
  };

  const routeIcons: Record<string, TabIcon> = {
    index: 'home',
    calendar: 'calendar',
    'chat/index': 'chat',
    'finance/index': 'finance',
    profile: 'profile',
  };

  return (
    <View
      style={{
        flexDirection: 'row',
        backgroundColor: isDark ? '#12121A' : '#FFFFFF',
        paddingTop: spacing.sm,
        paddingBottom: insets.bottom + spacing.xs,
        paddingHorizontal: spacing.lg,
        borderTopWidth: 1,
        borderTopColor: isDark ? '#1F2937' : '#F3F4F6',
      }}
    >
      {filteredRoutes.map((route: any, index: number) => {
        const { options } = descriptors[route.key];
        const isFocused = state.index === index;
        const label = routeLabels[route.name] || route.name;
        const iconName = routeIcons[route.name] || 'home';

        const onPress = () => {
          const event = navigation.emit({
            type: 'tabPress',
            target: route.key,
            canPreventDefault: true,
          });

          if (!isFocused && !event.defaultPrevented) {
            navigation.navigate(route.name);
          }
        };

        return (
          <TouchableOpacity
            key={route.key}
            onPress={onPress}
            activeOpacity={0.7}
            style={{
              flex: 1,
              alignItems: 'center',
              justifyContent: 'center',
              gap: 2,
              paddingVertical: spacing.xs,
            }}
          >
            <View>
              <TabIconComponent name={iconName} focused={isFocused} isDark={isDark} />
              {route.name === 'chat/index' && unreadCount > 0 && (
                <View
                  style={{
                    position: 'absolute',
                    top: -4,
                    right: -8,
                    backgroundColor: '#EF4444',
                    minWidth: 16,
                    height: 16,
                    borderRadius: 8,
                    alignItems: 'center',
                    justifyContent: 'center',
                    paddingHorizontal: 4,
                  }}
                >
                  <Text style={{ color: '#FFFFFF', fontSize: 10, fontWeight: '700' }}>
                    {unreadCount > 99 ? '99+' : unreadCount}
                  </Text>
                </View>
              )}
            </View>
            <Text
              style={{
                fontSize: 11,
                fontWeight: isFocused ? '600' : '400',
                color: isFocused ? '#8B5CF6' : isDark ? '#6B7280' : '#9CA3AF',
              }}
            >
              {label}
            </Text>
          </TouchableOpacity>
        );
      })}
    </View>
  );
}

export default function TabLayout() {
  return (
    <Tabs tabBar={(props) => <MyTabBar {...props} />} screenOptions={{ headerShown: false }}>
      <Tabs.Screen name="index" />
      <Tabs.Screen name="calendar" />
      <Tabs.Screen name="chat/index" />
      <Tabs.Screen name="finance/index" />
      <Tabs.Screen name="profile" />
      <Tabs.Screen name="schedules" options={{ href: null }} />
      <Tabs.Screen name="schedule-detail" options={{ href: null }} />
      <Tabs.Screen name="members/index" options={{ href: null }} />
      <Tabs.Screen name="members/[id]" options={{ href: null }} />
      <Tabs.Screen name="prayers/index" options={{ href: null }} />
      <Tabs.Screen name="prayers/[id]" options={{ href: null }} />
      <Tabs.Screen name="prayers/create" options={{ href: null }} />
      <Tabs.Screen name="finance/transactions" options={{ href: null }} />
      <Tabs.Screen name="finance/cash-flow" options={{ href: null }} />
      <Tabs.Screen name="finance/reports" options={{ href: null }} />
      <Tabs.Screen name="chat/[id]" options={{ href: null }} />
    </Tabs>
  );
}
