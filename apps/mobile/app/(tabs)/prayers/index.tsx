import { View, Text, FlatList, TouchableOpacity, StyleSheet } from 'react-native';
import { useRouter } from 'expo-router';
import { useEffect, useState } from 'react';
import { prayersService } from '../../../services/prayers';

export default function PrayerFeedScreen() {
  const router = useRouter();
  const [prayers, setPrayers] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    loadPrayers();
  }, []);

  const loadPrayers = async () => {
    setLoading(true);
    try {
      const res = await prayersService.list();
      setPrayers(res.data.data?.data || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const renderPrayer = ({ item }: { item: any }) => (
    <TouchableOpacity style={styles.card} onPress={() => router.push(`/(tabs)/prayers/${item.id}`)}>
      <View style={styles.headerRow}>
        <Text style={styles.title}>{item.isAnonymous ? 'Anônimo' : 'Pedido de Oração'}</Text>
        {item.isUrgent && <View style={styles.urgentBadge}><Text style={styles.urgentText}>Urgente</Text></View>}
        {item.isAnswered && <View style={styles.answeredBadge}><Text style={styles.answeredText}>Atendido</Text></View>}
      </View>
      <Text style={styles.content} numberOfLines={3}>{item.content}</Text>
      {item.category && <Text style={styles.category}>{item.category.name}</Text>}
      <View style={styles.footer}>
        <Text style={styles.stats}>{item._count?.comments || 0} comentários</Text>
        <Text style={styles.stats}>{item._count?.intercessors || 0} intercessores</Text>
      </View>
    </TouchableOpacity>
  );

  return (
    <View style={styles.container}>
      <FlatList
        data={prayers}
        renderItem={renderPrayer}
        keyExtractor={(item) => item.id}
        refreshing={loading}
        onRefresh={loadPrayers}
        ListEmptyComponent={<Text style={styles.empty}>Nenhum pedido de oração</Text>}
      />
      <TouchableOpacity style={styles.fab} onPress={() => router.push('/(tabs)/prayers/create')}>
        <Text style={styles.fabText}>+</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#f5f5f5' },
  card: { backgroundColor: '#fff', margin: 12, marginBottom: 4, padding: 16, borderRadius: 8, elevation: 1 },
  headerRow: { flexDirection: 'row', alignItems: 'center', marginBottom: 8, gap: 8 },
  title: { fontSize: 16, fontWeight: '600', flex: 1 },
  urgentBadge: { backgroundColor: '#ff4444', borderRadius: 4, paddingHorizontal: 8, paddingVertical: 2 },
  urgentText: { color: '#fff', fontSize: 11, fontWeight: 'bold' },
  answeredBadge: { backgroundColor: '#4caf50', borderRadius: 4, paddingHorizontal: 8, paddingVertical: 2 },
  answeredText: { color: '#fff', fontSize: 11, fontWeight: 'bold' },
  content: { fontSize: 14, color: '#555', marginBottom: 8 },
  category: { fontSize: 12, color: '#1a73e8', marginBottom: 4 },
  footer: { flexDirection: 'row', gap: 16 },
  stats: { fontSize: 12, color: '#999' },
  empty: { textAlign: 'center', marginTop: 40, color: '#999' },
  fab: { position: 'absolute', bottom: 20, right: 20, width: 56, height: 56, borderRadius: 28, backgroundColor: '#1a73e8', justifyContent: 'center', alignItems: 'center', elevation: 4 },
  fabText: { color: '#fff', fontSize: 28, lineHeight: 28 },
});
