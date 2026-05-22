import { View, Text, FlatList, TouchableOpacity, RefreshControl, StyleSheet, TextInput, Image, Alert } from 'react-native';
import { useState, useEffect, useCallback } from 'react';
import { router } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useColorScheme } from '../../../../src/hooks/useColorScheme';
import { useAuth } from '../../../../src/hooks/useAuth';
import { prayersService } from '../../../../src/services/prayers';
import type { Prayer } from '../../../../src/types';

const tabs = [
  { key: 'feed', label: 'Pedidos' },
  { key: 'mine', label: 'Meus' },
];

function PrayerCard({ prayer, onPress }: { prayer: Prayer; onPress: () => void }) {
  const { isDark } = useColorScheme();
  const { user } = useAuth();
  const [local, setLocal] = useState(() => ({
    liked: prayer.reactions?.some(r => r.type === 'AMEN' && r.userId === user?.id) ?? false,
    count: prayer.reactions?.filter(r => r.type === 'AMEN').length ?? 0,
  }));

  useEffect(() => {
    setLocal({
      liked: prayer.reactions?.some(r => r.type === 'AMEN' && r.userId === user?.id) ?? false,
      count: prayer.reactions?.filter(r => r.type === 'AMEN').length ?? 0,
    });
  }, [prayer.reactions, user?.id]);

  const handleLike = async () => {
    try {
      await prayersService.toggleReaction(prayer.id, 'AMEN');
      setLocal(prev => ({
        liked: !prev.liked,
        count: prev.liked ? prev.count - 1 : prev.count + 1,
      }));
    } catch (e: any) {
      Alert.alert('Erro', e?.response?.data?.message || e?.message || 'Erro ao reagir');
    }
  };

  return (
    <TouchableOpacity onPress={onPress} activeOpacity={0.7} style={[styles.card, { backgroundColor: isDark ? '#1A1A2E' : '#FFFFFF' }]}>
      <View style={styles.cardHeader}>
        <View style={styles.author}>
          {prayer.isAnonymous ? (
            <View style={[styles.avatar, { backgroundColor: '#6B7280' }]}>
              <Text style={styles.avatarText}>??</Text>
            </View>
          ) : prayer.authorAvatar ? (
            <Image source={{ uri: prayer.authorAvatar }} style={{ width: 40, height: 40, borderRadius: 20, marginRight: 10 }} />
          ) : (
            <View style={[styles.avatar, { backgroundColor: isDark ? '#374151' : '#E5E7EB' }]}>
              <Text style={styles.avatarText}>{prayer.authorName?.charAt(0) || '?'}</Text>
            </View>
          )}
          <View>
            <Text style={[styles.authorName, { color: isDark ? '#F9FAFB' : '#111827' }]}>{prayer.isAnonymous ? 'Anônimo' : prayer.authorName}</Text>
            <Text style={[styles.postedAt, { color: isDark ? '#6B7280' : '#9CA3AF' }]}>
              {new Date(prayer.createdAt).toLocaleDateString('pt-BR', { day: 'numeric', month: 'short' })}
            </Text>
          </View>
        </View>
        {prayer.isUrgent && (
          <View style={styles.urgentBadge}>
            <Text style={styles.urgentText}>⚠️ Urgente</Text>
          </View>
        )}
      </View>

      <Text style={[styles.content, { color: isDark ? '#E5E5E5' : '#374151' }]} numberOfLines={4}>
        {prayer.content}
      </Text>

      {prayer.categoryName && (
        <View style={[styles.categoryBadge, { backgroundColor: isDark ? '#008CFF20' : '#008CFF10' }]}>
          <Text style={styles.categoryText}>{prayer.categoryName}</Text>
        </View>
      )}

      <View style={[styles.cardFooter, { borderTopColor: isDark ? '#1F2937' : '#F3F4F6' }]}>
        <TouchableOpacity onPress={handleLike} style={styles.actionBtn}>
          <Text style={styles.actionIcon}>{local.liked ? '❤️' : '🤍'}</Text>
          <Text style={[styles.actionText, { color: isDark ? '#9CA3AF' : '#6B7280' }]}>{local.count}</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.actionBtn}>
          <Text style={styles.actionIcon}>💬</Text>
          <Text style={[styles.actionText, { color: isDark ? '#9CA3AF' : '#6B7280' }]}>
            {prayer.commentsCount || 0}
          </Text>
        </TouchableOpacity>
      </View>
    </TouchableOpacity>
  );
}

export default function PrayerFeedScreen() {
  const { isDark } = useColorScheme();
  const { user } = useAuth();
  const insets = useSafeAreaInsets();
  const [prayers, setPrayers] = useState<Prayer[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [activeTab, setActiveTab] = useState('feed');
  const [search, setSearch] = useState('');

  const loadPrayers = useCallback(async () => {
    try {
      let res;
      if (activeTab === 'mine') {
        res = await prayersService.getMy(1, 50);
      } else {
        res = await prayersService.list({ limit: 50, sortBy: 'recent' });
      }
      setPrayers(res.data || []);
    } catch {} finally {
      setLoading(false);
    }
  }, [activeTab]);

  useEffect(() => { loadPrayers(); }, [loadPrayers]);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await loadPrayers();
    setRefreshing(false);
  }, [loadPrayers]);

  const filteredPrayers = prayers.filter(p => 
    search === '' || 
    p.content?.toLowerCase().includes(search.toLowerCase()) ||
    p.authorName?.toLowerCase().includes(search.toLowerCase())
  );

  const feedCount = prayers.length;
  const mineCount = prayers.filter(p => p.authorId === user?.id).length;

  return (
    <View style={[styles.container, { backgroundColor: isDark ? '#0A0A0F' : '#F8FAFC' }]}>
      <View style={[styles.header, { paddingTop: insets.top + 20 }]}>
        <Text style={[styles.title, { color: isDark ? '#F9FAFB' : '#111827' }]}>Orações</Text>
        <Text style={[styles.subtitle, { color: isDark ? '#9CA3AF' : '#6B7280' }]}>
          {prayers.length} pedidos registrados
        </Text>
      </View>

      <View style={[styles.searchBox, { backgroundColor: isDark ? '#1A1A2E' : '#FFFFFF' }]}>
        <Text style={styles.searchIcon}>🔍</Text>
        <TextInput
          value={search}
          onChangeText={setSearch}
          placeholder="Buscar pedidos..."
          placeholderTextColor={isDark ? '#6B7280' : '#9CA3AF'}
          style={[styles.searchInput, { color: isDark ? '#F9FAFB' : '#111827' }]}
        />
      </View>

      <View style={styles.tabs}>
        {tabs.map((tab) => (
          <TouchableOpacity
            key={tab.key}
            onPress={() => setActiveTab(tab.key)}
            style={[styles.tab, activeTab === tab.key && styles.tabActive]}
          >
            <Text style={[styles.tabText, activeTab === tab.key && styles.tabTextActive]}>
              {tab.label} ({tab.key === 'feed' ? feedCount : mineCount})
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      <FlatList
        data={filteredPrayers}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.list}
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor="#008CFF" />
        }
        renderItem={({ item }) => (
          <PrayerCard
            prayer={item}
            onPress={() => router.push(`/(app)/(tabs)/prayers/${item.id}`)}
          />
        )}
        ListEmptyComponent={
          <View style={styles.empty}>
            <Text style={styles.emptyIcon}>🙏</Text>
            <Text style={[styles.emptyTitle, { color: isDark ? '#F9FAFB' : '#111827' }]}>
              {activeTab === 'mine' ? 'Você ainda não fez pedidos' : 'Nenhum pedido de oração'}
            </Text>
            <Text style={[styles.emptySubtitle, { color: isDark ? '#9CA3AF' : '#6B7280' }]}>
              Compartilhe seus pedidos com a igreja
            </Text>
          </View>
        }
      />

      <TouchableOpacity
        onPress={() => router.push('/(app)/(tabs)/prayers/create')}
        style={[styles.fab, { bottom: insets.bottom + 20 }]}
      >
          <Image
            source={require('../../../../assets/add.png')}
            style={{ width: 24, height: 24 }}
            resizeMode="contain"
          />
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  header: { paddingHorizontal: 20, paddingBottom: 8 },
  title: { fontSize: 32, fontWeight: 'bold' },
  subtitle: { fontSize: 14, marginTop: 4 },
  searchBox: { flexDirection: 'row', alignItems: 'center', marginHorizontal: 20, marginBottom: 16, paddingHorizontal: 14, paddingVertical: 10, borderRadius: 12 },
  searchIcon: { fontSize: 16, marginRight: 8 },
  searchInput: { flex: 1, fontSize: 15 },
  tabs: { flexDirection: 'row', paddingHorizontal: 20, marginBottom: 16, gap: 8 },
  tab: { flex: 1, paddingVertical: 10, borderRadius: 10, alignItems: 'center', backgroundColor: '#1A1A2E' },
  tabActive: { backgroundColor: '#008CFF' },
  tabText: { fontSize: 13, fontWeight: '600', color: '#9CA3AF' },
  tabTextActive: { color: '#FFFFFF' },
  list: { paddingHorizontal: 20, paddingBottom: 100 },
  card: { borderRadius: 16, padding: 16, marginBottom: 12, shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.1, shadowRadius: 8, elevation: 3 },
  cardHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 12 },
  author: { flexDirection: 'row', alignItems: 'center' },
  avatar: { width: 40, height: 40, borderRadius: 20, alignItems: 'center', justifyContent: 'center', marginRight: 10 },
  avatarText: { fontSize: 16, fontWeight: 'bold', color: '#008CFF' },
  authorName: { fontSize: 14, fontWeight: '600' },
  postedAt: { fontSize: 12, marginTop: 2 },
  urgentBadge: { backgroundColor: '#EF444420', paddingHorizontal: 10, paddingVertical: 4, borderRadius: 12 },
  urgentText: { fontSize: 12, color: '#EF4444', fontWeight: '600' },
  content: { fontSize: 15, lineHeight: 22, marginBottom: 12 },
  categoryBadge: { alignSelf: 'flex-start', paddingHorizontal: 10, paddingVertical: 4, borderRadius: 12 },
  categoryText: { fontSize: 12, color: '#008CFF', fontWeight: '600' },
  cardFooter: { flexDirection: 'row', paddingTop: 12, borderTopWidth: 1, gap: 20 },
  actionBtn: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  actionIcon: { fontSize: 18 },
  actionText: { fontSize: 13 },
  empty: { alignItems: 'center', paddingTop: 60 },
  emptyIcon: { fontSize: 48 },
  emptyTitle: { fontSize: 18, fontWeight: '600', marginTop: 16 },
  emptySubtitle: { fontSize: 14, marginTop: 4 },
  fab: { position: 'absolute', right: 20, width: 56, height: 56, borderRadius: 12, backgroundColor: '#008CFF', alignItems: 'center', justifyContent: 'center', shadowColor: '#008CFF', shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.4, shadowRadius: 8, elevation: 6 },
  fabText: { fontSize: 28, color: '#FFFFFF', fontWeight: '600', textAlign: 'center', lineHeight: 27 },
});