import { Stack } from 'expo-router';

export default function PrayersLayout() {
  return (
    <Stack screenOptions={{ headerShown: false, unmountOnBlur: true }}>
      <Stack.Screen name="index" />
      <Stack.Screen name="[id]" />
      <Stack.Screen 
        name="create" 
        options={{ 
          presentation: 'modal',
          gestureEnabled: true,
        }} 
      />
    </Stack>
  );
}