import { Tabs } from 'expo-router';
import { View, Text, StyleSheet } from 'react-native';
import { useAuthStore } from '../../store/auth';

export default function TabLayout() {
  const hasRole = useAuthStore((state) => state.hasRole);
  const canAccessFinance = hasRole(['ADMINISTRADOR', 'PASTOR', 'FINANCEIRO']);

  return (
    <Tabs>
      <Tabs.Screen name="index" options={{ title: 'Dashboard', headerShown: false }} />
      <Tabs.Screen name="schedules" options={{ title: 'Minhas Escalas' }} />
      <Tabs.Screen name="calendar" options={{ title: 'Calendário' }} />
      <Tabs.Screen name="members/index" options={{ title: 'Membros' }} />
      <Tabs.Screen name="prayers/index" options={{ title: 'Oração' }} />
      {canAccessFinance && (
        <Tabs.Screen name="finance/index" options={{ title: 'Financeiro' }} />
      )}
      <Tabs.Screen name="profile" options={{ title: 'Perfil' }} />
    </Tabs>
  );
}