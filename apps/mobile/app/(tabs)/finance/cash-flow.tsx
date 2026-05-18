import { View, Text, FlatList, StyleSheet, ActivityIndicator } from 'react-native';
import { useEffect, useState } from 'react';
import { financeService } from '../../../services/finance';

export default function CashFlowScreen() {
  const [flow, setFlow] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadFlow();
  }, []);

  const loadFlow = async () => {
    try {
      const res = await financeService.getCashFlow();
      setFlow(res.data.data || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <ActivityIndicator style={{ marginTop: 40 }} />;

  const formatMoney = (val: number) =>
    `R$ ${Math.abs(val).toLocaleString('pt-BR', { minimumFractionDigits: 2 })}`;

  const renderItem = ({ item }: { item: any }) => (
    <View style={styles.card}>
      <View style={styles.row}>
        <Text style={styles.date}>{new Date(item.date).toLocaleDateString('pt-BR')}</Text>
        <Text style={[styles.value, { color: item.value >= 0 ? '#4caf50' : '#ff5252' }]}>
          {item.value >= 0 ? '+' : '-'}{formatMoney(item.value)}
        </Text>
      </View>
      {item.description && <Text style={styles.description}>{item.description}</Text>}
      <Text style={styles.balance}>Saldo: {formatMoney(item.balance)}</Text>
    </View>
  );

  return (
    <View style={styles.container}>
      <FlatList
        data={flow}
        renderItem={renderItem}
        keyExtractor={(item) => item.id}
        refreshing={loading}
        onRefresh={loadFlow}
        ListEmptyComponent={<Text style={styles.empty}>Nenhum registro</Text>}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#f5f5f5' },
  card: { backgroundColor: '#fff', margin: 12, marginBottom: 4, padding: 12, borderRadius: 8, elevation: 1 },
  row: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  date: { fontSize: 13, color: '#666' },
  value: { fontSize: 16, fontWeight: 'bold' },
  description: { fontSize: 14, color: '#555', marginTop: 4 },
  balance: { fontSize: 12, color: '#999', marginTop: 6, textAlign: 'right' },
  empty: { textAlign: 'center', marginTop: 40, color: '#999' },
});
