import { View, Text, FlatList, TouchableOpacity, StyleSheet, TextInput } from 'react-native';
import { useRouter } from 'expo-router';
import { useEffect, useState } from 'react';
import { financeService } from '../../../services/finance';

export default function TransactionsScreen() {
  const router = useRouter();
  const [transactions, setTransactions] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [filter, setFilter] = useState('');

  useEffect(() => {
    loadTransactions();
  }, []);

  const loadTransactions = async () => {
    setLoading(true);
    try {
      const res = await financeService.getTransactions({ limit: 50 });
      setTransactions(res.data.data?.data || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const filtered = filter
    ? transactions.filter((t) => t.description?.toLowerCase().includes(filter.toLowerCase()))
    : transactions;

  const typeColor = (type: string) => {
    switch (type) {
      case 'INCOME': return '#4caf50';
      case 'EXPENSE': return '#ff5252';
      case 'TITHE': return '#ff9800';
      case 'OFFERING': return '#9c27b0';
      default: return '#999';
    }
  };

  const typeLabel = (type: string) => {
    switch (type) {
      case 'INCOME': return 'Entrada';
      case 'EXPENSE': return 'Saída';
      case 'TITHE': return 'Dízimo';
      case 'OFFERING': return 'Oferta';
      default: return type;
    }
  };

  const renderItem = ({ item }: { item: any }) => (
    <View style={styles.card}>
      <View style={styles.cardRow}>
        <View style={[styles.typeBadge, { backgroundColor: typeColor(item.type) }]}>
          <Text style={styles.typeText}>{typeLabel(item.type)}</Text>
        </View>
        <Text style={[styles.value, { color: ['INCOME', 'TITHE', 'OFFERING'].includes(item.type) ? '#4caf50' : '#ff5252' }]}>
          R$ {Number(item.value).toFixed(2)}
        </Text>
      </View>
      {item.description && <Text style={styles.description}>{item.description}</Text>}
      <View style={styles.cardFooter}>
        <Text style={styles.date}>{new Date(item.date).toLocaleDateString('pt-BR')}</Text>
        <Text style={[styles.status, { color: item.status === 'CONFIRMED' ? '#4caf50' : item.status === 'CANCELLED' ? '#ff5252' : '#ff9800' }]}>{item.status}</Text>
      </View>
    </View>
  );

  return (
    <View style={styles.container}>
      <TextInput style={styles.searchInput} placeholder="Filtrar lançamentos..." value={filter} onChangeText={setFilter} />
      <FlatList
        data={filtered}
        renderItem={renderItem}
        keyExtractor={(item) => item.id}
        refreshing={loading}
        onRefresh={loadTransactions}
        ListEmptyComponent={<Text style={styles.empty}>Nenhum lançamento</Text>}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#f5f5f5' },
  searchInput: { backgroundColor: '#fff', margin: 12, padding: 10, borderRadius: 8, fontSize: 14 },
  card: { backgroundColor: '#fff', marginHorizontal: 12, marginVertical: 4, padding: 12, borderRadius: 8, elevation: 1 },
  cardRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  typeBadge: { borderRadius: 4, paddingHorizontal: 8, paddingVertical: 2 },
  typeText: { color: '#fff', fontSize: 11, fontWeight: '600' },
  value: { fontSize: 18, fontWeight: 'bold' },
  description: { fontSize: 14, color: '#555', marginTop: 4 },
  cardFooter: { flexDirection: 'row', justifyContent: 'space-between', marginTop: 8 },
  date: { fontSize: 12, color: '#999' },
  status: { fontSize: 12, fontWeight: '600' },
  empty: { textAlign: 'center', marginTop: 40, color: '#999' },
});
