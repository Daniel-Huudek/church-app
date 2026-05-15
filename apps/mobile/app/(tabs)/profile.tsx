import { View, Text, Button, StyleSheet } from 'react-native';
import { useAuthStore } from '../../store/auth';
import { router } from 'expo-router';

export default function Profile() {
  const { user, logout } = useAuthStore();

  const handleLogout = () => {
    logout();
    router.replace('/login');
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Perfil</Text>
      <Text style={styles.name}>{user?.name || 'Usuário'}</Text>
      <Text style={styles.email}>{user?.email || 'email@example.com'}</Text>
      <Text style={styles.role}>{user?.role || 'MEMBER'}</Text>
      <Button title="Sair" onPress={handleLogout} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 16, backgroundColor: '#fff' },
  title: { fontSize: 24, fontWeight: 'bold', marginBottom: 20 },
  name: { fontSize: 20, fontWeight: '600', marginBottom: 8 },
  email: { fontSize: 16, color: '#666', marginBottom: 4 },
  role: { fontSize: 14, color: '#999', marginBottom: 20 },
});