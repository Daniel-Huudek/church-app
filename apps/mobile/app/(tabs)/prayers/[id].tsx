import { View, Text, ScrollView, StyleSheet, ActivityIndicator, TextInput, TouchableOpacity, Alert } from 'react-native';
import { useLocalSearchParams } from 'expo-router';
import { useEffect, useState } from 'react';
import { prayersService } from '../../../services/prayers';

export default function PrayerDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const [prayer, setPrayer] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [comment, setComment] = useState('');

  useEffect(() => {
    loadPrayer();
  }, [id]);

  const loadPrayer = async () => {
    try {
      const res = await prayersService.getById(id);
      setPrayer(res.data.data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleComment = async () => {
    if (!comment.trim()) return;
    try {
      await prayersService.addComment(id, comment);
      setComment('');
      loadPrayer();
    } catch (err) {
      Alert.alert('Erro', 'Não foi possível comentar');
    }
  };

  const handleReact = async (type: string) => {
    try {
      await prayersService.toggleReaction(id, type);
      loadPrayer();
    } catch (err) {
      console.error(err);
    }
  };

  const handleIntercede = async () => {
    try {
      await prayersService.intercede(id);
      Alert.alert('Sucesso', 'Você está intercedendo por este pedido!');
      loadPrayer();
    } catch (err) {
      console.error(err);
    }
  };

  if (loading) return <ActivityIndicator style={{ marginTop: 40 }} />;
  if (!prayer) return <Text style={{ textAlign: 'center', marginTop: 40 }}>Pedido não encontrado</Text>;

  return (
    <ScrollView style={styles.container}>
      <View style={styles.card}>
        <View style={styles.headerRow}>
          <Text style={styles.title}>{prayer.isAnonymous ? 'Anônimo' : prayer.title}</Text>
          {prayer.isUrgent && <View style={styles.badge}><Text style={styles.badgeText}>Urgente</Text></View>}
        </View>
        {prayer.isAnswered && <Text style={styles.answered}>✓ Atendido em {new Date(prayer.answeredAt).toLocaleDateString('pt-BR')}</Text>}
        <Text style={styles.content}>{prayer.content}</Text>
        {prayer.category && <Text style={styles.category}>{prayer.category.name}</Text>}
        <Text style={styles.views}>{prayer.viewsCount} visualizações</Text>
      </View>

      <View style={styles.actions}>
        <TouchableOpacity style={styles.actionBtn} onPress={() => handleReact('AMEN')}>
          <Text style={styles.actionText}>🙏 Amém</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.actionBtn} onPress={() => handleReact('PRAYING')}>
          <Text style={styles.actionText}>🤲 Orando</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.actionBtn} onPress={handleIntercede}>
          <Text style={styles.actionText}>🕯️ Interceder</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Comentários ({prayer.comments?.length || 0})</Text>
        {prayer.comments?.map((c: any) => (
          <View key={c.id} style={styles.comment}>
            <Text style={styles.commentAuthor}>Usuário</Text>
            <Text style={styles.commentContent}>{c.content}</Text>
          </View>
        ))}
        <View style={styles.commentInput}>
          <TextInput style={styles.input} placeholder="Escreva um comentário..." value={comment} onChangeText={setComment} />
          <TouchableOpacity onPress={handleComment}><Text style={styles.sendBtn}>Enviar</Text></TouchableOpacity>
        </View>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#f5f5f5' },
  card: { backgroundColor: '#fff', margin: 12, padding: 16, borderRadius: 8 },
  headerRow: { flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 8 },
  title: { fontSize: 18, fontWeight: 'bold', flex: 1 },
  badge: { backgroundColor: '#ff4444', borderRadius: 4, paddingHorizontal: 8, paddingVertical: 2 },
  badgeText: { color: '#fff', fontSize: 11, fontWeight: 'bold' },
  answered: { color: '#4caf50', fontWeight: '600', marginBottom: 8 },
  content: { fontSize: 15, color: '#333', marginBottom: 8 },
  category: { fontSize: 13, color: '#1a73e8', marginBottom: 4 },
  views: { fontSize: 12, color: '#999' },
  actions: { flexDirection: 'row', margin: 12, gap: 8 },
  actionBtn: { flex: 1, backgroundColor: '#fff', padding: 12, borderRadius: 8, alignItems: 'center', elevation: 1 },
  actionText: { fontSize: 14 },
  section: { backgroundColor: '#fff', margin: 12, padding: 16, borderRadius: 8 },
  sectionTitle: { fontSize: 16, fontWeight: '600', marginBottom: 12, color: '#1a73e8' },
  comment: { marginBottom: 12 },
  commentAuthor: { fontSize: 13, fontWeight: '600', color: '#555' },
  commentContent: { fontSize: 14, color: '#333', marginTop: 2 },
  commentInput: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  input: { flex: 1, backgroundColor: '#f5f5f5', borderRadius: 8, padding: 10, fontSize: 14 },
  sendBtn: { color: '#1a73e8', fontWeight: '600', fontSize: 14 },
});
