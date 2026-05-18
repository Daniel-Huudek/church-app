import { View, Text, FlatList, TouchableOpacity, StyleSheet, TextInput } from 'react-native';
import { useRouter } from 'expo-router';
import { useEffect, useState } from 'react';
import { membersService } from '../../../services/members';

export default function MembersListScreen() {
  const router = useRouter();
  const [members, setMembers] = useState<any[]>([]);
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    loadMembers();
  }, [page]);

  const loadMembers = async () => {
    setLoading(true);
    try {
      const res = await membersService.list({ page, limit: 20, name: search || undefined });
      setMembers(res.data.data?.data || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = () => {
    setPage(1);
    loadMembers();
  };

  const renderMember = ({ item }: { item: any }) => (
    <TouchableOpacity style={styles.card} onPress={() => router.push(`/(tabs)/members/${item.id}`)}>
      <View style={styles.avatar}>
        <Text style={styles.avatarText}>{item.name?.charAt(0)?.toUpperCase()}</Text>
      </View>
      <View style={styles.info}>
        <Text style={styles.name}>{item.name}</Text>
        <Text style={styles.detail}>{item.role} • {item.status}</Text>
        {item.ministry && <Text style={styles.ministry}>{item.ministry.name}</Text>}
      </View>
    </TouchableOpacity>
  );

  return (
    <View style={styles.container}>
      <View style={styles.searchRow}>
        <TextInput
          style={styles.searchInput}
          placeholder="Buscar membros..."
          value={search}
          onChangeText={setSearch}
          onSubmitEditing={handleSearch}
        />
        <TouchableOpacity style={styles.searchBtn} onPress={handleSearch}>
          <Text style={styles.searchBtnText}>Buscar</Text>
        </TouchableOpacity>
      </View>

      <FlatList
        data={members}
        renderItem={renderMember}
        keyExtractor={(item) => item.id}
        refreshing={loading}
        onRefresh={loadMembers}
        onEndReached={() => setPage((p) => p + 1)}
        ListEmptyComponent={<Text style={styles.empty}>Nenhum membro encontrado</Text>}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#f5f5f5' },
  searchRow: { flexDirection: 'row', padding: 12, gap: 8 },
  searchInput: { flex: 1, backgroundColor: '#fff', borderRadius: 8, paddingHorizontal: 12, height: 40 },
  searchBtn: { backgroundColor: '#1a73e8', borderRadius: 8, paddingHorizontal: 16, justifyContent: 'center' },
  searchBtnText: { color: '#fff', fontWeight: '600' },
  card: { flexDirection: 'row', backgroundColor: '#fff', marginHorizontal: 12, marginVertical: 4, padding: 12, borderRadius: 8, alignItems: 'center', elevation: 1 },
  avatar: { width: 44, height: 44, borderRadius: 22, backgroundColor: '#1a73e8', justifyContent: 'center', alignItems: 'center' },
  avatarText: { color: '#fff', fontSize: 18, fontWeight: 'bold' },
  info: { marginLeft: 12, flex: 1 },
  name: { fontSize: 16, fontWeight: '600' },
  detail: { fontSize: 13, color: '#666', marginTop: 2 },
  ministry: { fontSize: 12, color: '#1a73e8', marginTop: 2 },
  empty: { textAlign: 'center', marginTop: 40, color: '#999' },
});
