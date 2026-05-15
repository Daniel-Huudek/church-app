import { Tabs } from 'expo-router';
import { View, Text, StyleSheet } from 'react-native';

export default function TabLayout() {
  return (
    <Tabs>
      <Tabs.Screen name="index" options={{ title: 'Dashboard', headerShown: false }} />
      <Tabs.Screen name="schedules" options={{ title: 'Minhas Escalas' }} />
      <Tabs.Screen name="calendar" options={{ title: 'Calendário' }} />
      <Tabs.Screen name="profile" options={{ title: 'Perfil' }} />
    </Tabs>
  );
}