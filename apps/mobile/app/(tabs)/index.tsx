import { View, Text, StyleSheet } from 'react-native';
import { useAuthStore } from '../../store/auth';

export default function Dashboard() {
  const { user } = useAuthStore();

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Bem-vindo, {user?.name || 'Membro'}!</Text>
      <View style={styles.card}>
        <Text style={styles.cardTitle}>Próximos Eventos</Text>
        <Text style={styles.cardText}>Nenhum evento próximo</Text>
      </View>
      <View style={styles.card}>
        <Text style={styles.cardTitle}>Suas Escalas</Text>
        <Text style={styles.cardText}>Você não tem escalas próximas</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 16, backgroundColor: '#fff' },
  title: { fontSize: 24, fontWeight: 'bold', marginBottom: 20 },
  card: { padding: 16, backgroundColor: '#f5f5f5', borderRadius: 8, marginBottom: 12 },
  cardTitle: { fontSize: 18, fontWeight: '600', marginBottom: 8 },
  cardText: { fontSize: 14, color: '#666' },
});