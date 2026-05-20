import { Tabs, router } from 'expo-router';
import { View, Text, TouchableOpacity, Keyboard, Image, Animated, PanResponder, Dimensions } from 'react-native';
import { useEffect, useState, useRef } from 'react';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

const { height: SCREEN_HEIGHT } = Dimensions.get('window');

import { useAuth } from '../../../src/hooks';
import { usePermission } from '../../../src/hooks/usePermission';
import { useColorScheme } from '../../../src/hooks';
import { spacing } from '../../../src/theme';
import { Icon, IconName } from '../../../src/components/ui';

const DRAWER_WIDTH = 200;

const menuItems = [
  { name: 'index', label: 'Dashboard', icon: '📊', permission: 'admin' },
  { name: 'calendar', label: 'Eventos', icon: '📅' },
  { name: 'prayers/index', label: 'Oração', icon: '🙏' },
  { name: 'schedules', label: 'Escalas', icon: '📋' },
  { name: 'users/index', label: 'Users', icon: '👥', permission: 'admin' },
  { name: 'finance/index', label: 'Finanças', icon: '💰' },
  { name: 'finance/transactions', label: 'Transações', icon: '💳' },
  { name: 'finance/reports', label: 'Relatórios', icon: '📊' },
  { name: 'finance/cash-flow', label: 'Fluxo de Caixa', icon: '📈' },
];

function Drawer({ navigation, visible, onClose }: { navigation: any; visible: boolean; onClose: () => void }) {
  const { isDark } = useColorScheme();
  const { isAdmin } = useAuth();
  const slideAnim = useRef(new Animated.Value(-DRAWER_WIDTH)).current;

  useEffect(() => {
    Animated.timing(slideAnim, {
      toValue: visible ? 0 : -DRAWER_WIDTH,
      duration: 250,
      useNativeDriver: true,
    }).start();
  }, [visible]);

  const visibleMenuItems = menuItems.filter(item => {
    if (item.permission === 'admin' && !isAdmin) return false;
    return true;
  });

  if (!visible) return null;

  return (
    <View style={{ position: 'absolute', top: 0, bottom: 0, left: 0, right: 0, zIndex: 100 }}>
      <TouchableOpacity 
        style={{ flex: 1, backgroundColor: 'rgba(0,0,0,0.5)' }} 
        onPress={onClose}
        activeOpacity={1}
      />
      <Animated.View
        style={{
          position: 'absolute',
          top: 0,
          bottom: 0,
          left: 0,
          width: DRAWER_WIDTH,
          backgroundColor: isDark ? '#12121A' : '#FFFFFF',
          transform: [{ translateX: slideAnim }],
          paddingTop: 60,
          borderRightWidth: 1,
          borderRightColor: isDark ? '#1F2937' : '#F3F4F6',
        }}
      >
        {visibleMenuItems.map((item) => (
          <TouchableOpacity
            key={item.name}
            onPress={() => {
              navigation.navigate(item.name);
              onClose();
            }}
            style={{
              flexDirection: 'row',
              alignItems: 'center',
              paddingVertical: 14,
              paddingHorizontal: 16,
              borderBottomWidth: 1,
              borderBottomColor: isDark ? '#1F2937' : '#F3F4F6',
            }}
          >
            <Text style={{ fontSize: 20, marginRight: 12 }}>{item.icon}</Text>
            <Text style={{ fontSize: 14, color: isDark ? '#F9FAFB' : '#111827' }}>
              {item.label}
            </Text>
          </TouchableOpacity>
        ))}
      </Animated.View>
    </View>
  );
}

function ProfileAvatar({ avatar, name, focused }: { avatar?: string; name?: string; focused: boolean }) {
  const size = 36;

  if (avatar) {
    return (
      <Image
        source={{ uri: avatar }}
        style={{
          width: size,
          height: size,
          borderRadius: size / 2,
          borderWidth: focused ? 0 : 1.5,
          borderColor: '#8B5CF6',
        }}
      />
    );
  }

  const initial = name ? name.charAt(0).toUpperCase() : '?';
  return (
    <View
      style={{
        width: size,
        height: size,
        borderRadius: size / 2,
        backgroundColor: focused ? '#FFFFFF' : '#8B5CF6',
        alignItems: 'center',
        justifyContent: 'center',
        borderWidth: focused ? 0 : 1.5,
        borderColor: '#8B5CF6',
      }}
    >
      <Text style={{ fontSize: 16, fontWeight: '600', color: focused ? '#8B5CF6' : '#FFFFFF' }}>
        {initial}
      </Text>
    </View>
  );
}

function DrawerButton({ onPress }: { onPress: () => void }) {
  const { isDark } = useColorScheme();
  const { user } = useAuth();
  const defaultPos = Math.max(0, (SCREEN_HEIGHT - 50) / 2);
  const [position, setPosition] = useState(defaultPos);
  const startPos = useRef(defaultPos);

  const canShowAdminButton = user?.role === 'ADMINISTRADOR' || user?.role === 'PASTOR' || user?.role === 'LIDER';

  const panResponder = useRef(
    PanResponder.create({
      onStartShouldSetPanResponder: () => true,
      onMoveShouldSetPanResponder: () => true,
      onPanResponderGrant: () => {
        startPos.current = position;
      },
      onPanResponderMove: (_, gestureState) => {
        const newPos = startPos.current + gestureState.dy;
        setPosition(Math.max(0, Math.min(newPos, SCREEN_HEIGHT - 100)));
      },
    })
  ).current;

  if (!canShowAdminButton) return null;

  return (
    <View {...panResponder.panHandlers} style={{ position: 'absolute', left: 0, top: position, zIndex: 50 }}>
      <TouchableOpacity
        onPress={onPress}
        style={{
          width: 55,
          height: 50,
          borderTopLeftRadius: 0,
          borderBottomLeftRadius: 0,
          borderTopRightRadius: 10,
          borderBottomRightRadius: 10,
          backgroundColor: '#8B5CF6',
          alignItems: 'center',
          justifyContent: 'center',
          padding: 4,
        }}
      >
        <Icon name="settings" size={18} color="#FFFFFF" />
        <Text style={{ fontSize: 8, color: '#FFFFFF', fontWeight: '600' }}>ADMIN</Text>
      </TouchableOpacity>
    </View>
  );
}

function MyTabBar({ state, navigation }: any) {
  const { isDark } = useColorScheme();
  const insets = useSafeAreaInsets();
  const [keyboardVisible, setKeyboardVisible] = useState(false);
  const [drawerVisible, setDrawerVisible] = useState(false);
  const { user } = useAuth();

  useEffect(() => {
    const showSub = Keyboard.addListener('keyboardDidShow', () => setKeyboardVisible(true));
    const hideSub = Keyboard.addListener('keyboardDidHide', () => setKeyboardVisible(false));
    return () => { showSub.remove(); hideSub.remove(); };
  }, []);

  if (keyboardVisible) return null;

  const tabs = [
    { key: 'index', label: 'Início', icon: 'home' as IconName },
    { key: 'prayers', label: 'Oração', icon: 'oracao' as IconName },
    { key: 'calendar', label: 'Eventos', icon: 'calendar' as IconName },
  ];

  const currentRoute = state.routes[state.index]?.name || '';
  const currentIndex = tabs.findIndex(t => currentRoute.startsWith(t.key));

  const barBg = isDark ? 'rgba(22,22,34,0.94)' : 'rgba(255,255,255,0.94)';
  const barBorder = isDark ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.05)';
  const activeBg = isDark ? 'rgba(139,92,246,0.15)' : 'rgba(139,92,246,0.10)';

  return (
    <>
      <DrawerButton onPress={() => setDrawerVisible(!drawerVisible)} />
      <Drawer navigation={navigation} visible={drawerVisible} onClose={() => setDrawerVisible(false)} />
      <View style={{ paddingBottom: insets.bottom, backgroundColor: 'transparent' }}>
        <View style={{
          flexDirection: 'row',
          marginHorizontal: 12,
          marginBottom: 8,
          borderRadius: 22,
          backgroundColor: barBg,
          borderWidth: 1,
          borderColor: barBorder,
          shadowColor: '#000',
          shadowOffset: { width: 0, height: 6 },
          shadowOpacity: isDark ? 0.4 : 0.12,
          shadowRadius: 20,
          elevation: 10,
          paddingVertical: 6,
          paddingHorizontal: 8,
          alignItems: 'center',
          justifyContent: 'space-around',
        }}>
          {tabs.map((tab, idx) => {
            const isFocused = currentIndex === idx;
            return (
              <TouchableOpacity
                key={tab.key}
                onPress={() => {
                  if (tab.key === 'prayers') {
                    router.replace('/(app)/(tabs)/prayers');
                  } else if (!isFocused) {
                    navigation.navigate(tab.key);
                  }
                }}
                activeOpacity={0.7}
                style={{
                  alignItems: 'center',
                  justifyContent: 'center',
                  paddingVertical: 8,
                  paddingHorizontal: 14,
                  borderRadius: 16,
                  backgroundColor: isFocused ? activeBg : 'transparent',
                  flexDirection: 'row',
                  gap: 6,
                }}
              >
                <Icon name={tab.icon} size={22} color={isFocused ? '#8B5CF6' : (isDark ? '#6B7280' : '#9CA3AF')} />
                {isFocused && (
                  <Text style={{
                    fontSize: 13,
                    fontWeight: '700',
                    color: '#8B5CF6',
                  }}>
                    {tab.label}
                  </Text>
                )}
              </TouchableOpacity>
            );
          })}
          <TouchableOpacity
            onPress={() => navigation.navigate('profile')}
            activeOpacity={0.7}
            style={{ padding: 4, marginLeft: 4 }}
          >
            <ProfileAvatar avatar={user?.avatar} name={user?.name} focused={false} />
          </TouchableOpacity>
        </View>
      </View>
    </>
  );
}

export default function TabLayout() {
  return (
    <View style={{ flex: 1 }}>
      <Tabs
        tabBarPosition="bottom"
        tabBar={(props) => <MyTabBar {...props} />}
        screenOptions={{ 
          headerShown: false,
          sceneStyle: { paddingTop: 80 }
        }}
      >
      <Tabs.Screen name="index" />
      <Tabs.Screen name="prayers/index" />
      <Tabs.Screen name="calendar" />
      <Tabs.Screen name="schedules" />
      <Tabs.Screen name="profile" />
      <Tabs.Screen name="schedule-detail" options={{ href: null }} />
      <Tabs.Screen name="schedule-create" options={{ href: null }} />
      <Tabs.Screen name="members/index" />
      <Tabs.Screen name="members/[id]" options={{ href: null }} />
      <Tabs.Screen name="prayers/[id]" options={{ href: null }} />
      <Tabs.Screen name="prayers/create" options={{ href: null }} />
      <Tabs.Screen name="finance/transactions" />
      <Tabs.Screen name="finance/cash-flow" />
      <Tabs.Screen name="finance/reports" />
      </Tabs>
    </View>
  );
}