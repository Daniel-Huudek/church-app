import { View, Text, ScrollView, TextInput, TouchableOpacity, StyleSheet, Alert } from 'react-native';
import { useLocalSearchParams, router } from 'expo-router';
import { useState, useEffect, useCallback } from 'react';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useColorScheme } from '../../../../src/hooks/useColorScheme';
import { useAuth } from '../../../../src/hooks/useAuth';
import { prayersService } from '../../../../src/services/prayers';
import type { Prayer, PrayerComment } from '../../../../src/types';

const reactions = [
  { type: 'PRAYING', emoji: '🙏', label: 'Orando' },
  { type: 'AMEN', emoji: '❤️', label: 'Amém' },
  { type: 'INTERCEDE', emoji: '✝️', label: 'Interceder' },
];

export default function PrayerDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { isDark } = useColorScheme();
  const { user } = useAuth();
  const insets = useSafeAreaInsets();
  const [prayer, setPrayer] = useState<Prayer | null>(null);
  const [loading, setLoading] = useState(true);
  const [commentText, setCommentText] = useState('');
  const [sendingComment, setSendingComment] = useState(false);

  const loadPrayer = useCallback(async () => {
    setLoading(true);
    try {
      const res = await prayersService.getById(id);
      setPrayer(res as any);
    } catch {} finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => { loadPrayer(); }, [loadPrayer]);

  const handleReact = useCallback(async (type: string) => {
    if (!prayer) return;
    try {
      if (type === 'INTERCEDE') {
        await prayersService.intercede(prayer.id);
        loadPrayer();
        Alert.alert('🔥', 'Você está intercedendo!');
      } else {
        await prayersService.toggleReaction(prayer.id, type as any);
        loadPrayer();
      }
    } catch (e: any) {
      Alert.alert('Erro', e?.response?.data?.message || e?.message || 'Erro ao reagir');
    }
  }, [prayer, loadPrayer]);

  const handleSendComment = useCallback(async () => {
    if (!prayer || !commentText.trim()) return;
    setSendingComment(true);
    try {
      await prayersService.addComment(prayer.id, commentText.trim());
      setCommentText('');
      loadPrayer();
    } catch {} finally {
      setSendingComment(false);
    }
  }, [prayer, commentText, loadPrayer]);

  const isAuthor = user?.id === prayer?.authorId;
  const bgColor = isDark ? '#0A0A0F' : '#F8FAFC';
  const cardBg = isDark ? '#1A1A2E' : '#FFFFFF';
  const textPrimary = isDark ? '#F9FAFB' : '#111827';
  const textSecondary = isDark ? '#9CA3AF' : '#6B7280';
  const borderColor = isDark ? '#1F2937' : '#E5E7EB';

  if (loading || !prayer) {
    return (
      <View style={[styles.container, { backgroundColor: bgColor, paddingTop: insets.top }]}>
        <View style={styles.header}>
          <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}>
            <Text style={[styles.backText, { color: textPrimary }]}>←</Text>
          </TouchableOpacity>
        </View>
        <View style={styles.loadingContainer}>
          <Text style={{ color: textSecondary }}>Carregando...</Text>
        </View>
      </View>
    );
  }

  return (
    <View style={[styles.container, { backgroundColor: bgColor, paddingTop: insets.top }]}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}>
          <Text style={[styles.backText, { color: textPrimary }]}>←</Text>
        </TouchableOpacity>
      </View>

      <ScrollView contentContainerStyle={styles.scrollContent} keyboardShouldPersistTaps="handled">
        <View style={[styles.card, { backgroundColor: cardBg }]}>
          <View style={styles.authorRow}>
            <View style={[styles.avatar, { backgroundColor: prayer.isAnonymous ? '#6B7280' : '#8B5CF6' }]}>
              <Text style={styles.avatarText}>{prayer.isAnonymous ? '??' : '?'}</Text>
            </View>
            <View style={styles.authorInfo}>
              <Text style={[styles.authorName, { color: textPrimary }]}>
                {prayer.isAnonymous ? 'Anônimo' : prayer.authorName}
              </Text>
              <Text style={[styles.time, { color: textSecondary }]}>
                {new Date(prayer.createdAt).toLocaleDateString('pt-BR', { day: 'numeric', month: 'short', year: 'numeric' })}
              </Text>
            </View>
            {prayer.isUrgent && (
              <View style={styles.urgentBadge}>
                <Text style={styles.urgentText}>⚠️ Urgente</Text>
              </View>
            )}
          </View>

          <Text style={[styles.prayerTitle, { color: textPrimary }]}>{prayer.title}</Text>
          <Text style={[styles.prayerContent, { color: isDark ? '#D4D4D4' : '#374151' }]}>
            {prayer.content}
          </Text>

          <View style={[styles.statsRow, { borderTopColor: borderColor }]}>
            <Text style={[styles.statText, { color: textSecondary }]}>🙏 {prayer.intercessionCount}</Text>
            <Text style={[styles.statText, { color: textSecondary }]}>💬 {prayer.commentsCount}</Text>
            <Text style={[styles.statText, { color: textSecondary }]}>❤️ {prayer.reactionsCount}</Text>
            {prayer.isAnswered && <Text style={styles.answeredText}>✅ Atendido</Text>}
          </View>
        </View>

        <Text style={[styles.sectionTitle, { color: textSecondary }]}>Reagir</Text>
        <View style={styles.reactionsRow}>
          {reactions.map((r) => {
            const isActive = r.type === 'INTERCEDE'
              ? prayer.intercessors?.some((i: any) => i.userId === user?.id)
              : prayer.reactions?.some((re: any) => re.type === r.type);
            return (
              <TouchableOpacity
                key={r.type}
                onPress={() => handleReact(r.type)}
                style={[styles.reactionBtn, { borderColor, backgroundColor: isActive ? '#8B5CF620' : cardBg }]}
              >
                <Text style={styles.reactionEmoji}>{r.emoji}</Text>
                <Text style={[styles.reactionLabel, { color: isActive ? '#8B5CF6' : textPrimary }]}>{r.label}</Text>
              </TouchableOpacity>
            );
          })}
        </View>

        <Text style={[styles.sectionTitle, { color: textSecondary }]}>Comentários ({prayer.commentsCount})</Text>
        {prayer.comments && prayer.comments.length > 0 ? (
          <View style={[styles.commentsList, { backgroundColor: cardBg }]}>
            {prayer.comments.map((comment: PrayerComment) => (
              <View key={comment.id} style={[styles.commentItem, { borderBottomColor: borderColor }]}>
                <View style={styles.commentHeader}>
                  <View style={[styles.commentAvatar, { backgroundColor: isDark ? '#374151' : '#E5E7EB' }]}>
                    <Text style={styles.commentAvatarText}>{comment.authorName?.charAt(0) || '?'}</Text>
                  </View>
                  <View style={styles.commentInfo}>
                    <Text style={[styles.commentAuthor, { color: textPrimary }]}>{comment.authorName}</Text>
                    <Text style={[styles.commentTime, { color: textSecondary }]}>
                      {new Date(comment.createdAt).toLocaleDateString('pt-BR', { day: 'numeric', month: 'short' })}
                    </Text>
                  </View>
                </View>
                <Text style={[styles.commentContent, { color: isDark ? '#D4D4D4' : '#374151' }]}>{comment.content}</Text>
              </View>
            ))}
          </View>
        ) : (
          <View style={styles.emptyComments}>
            <Text style={{ color: textSecondary, textAlign: 'center' }}>Nenhum comentário ainda</Text>
          </View>
        )}
      </ScrollView>

      <View style={[styles.commentInput, { backgroundColor: cardBg, borderTopColor: borderColor, paddingBottom: insets.bottom + 8 }]}>
        <TextInput
          value={commentText}
          onChangeText={setCommentText}
          placeholder="Comentar..."
          placeholderTextColor={textSecondary}
          style={[styles.commentField, { backgroundColor: isDark ? '#0A0A0F' : '#F3F4F6', color: textPrimary }]}
          multiline
        />
        <TouchableOpacity
          onPress={handleSendComment}
          disabled={!commentText.trim() || sendingComment}
          style={[styles.sendBtn, { backgroundColor: commentText.trim() ? '#8B5CF6' : '#6B7280' }]}
        >
          <Text style={styles.sendBtnText}>{sendingComment ? '…' : '→'}</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  header: { paddingHorizontal: 20, paddingVertical: 12 },
  backBtn: { width: 40, height: 40, alignItems: 'center', justifyContent: 'center' },
  backText: { fontSize: 28 },
  loadingContainer: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  scrollContent: { padding: 20, paddingBottom: 100 },
  card: { borderRadius: 16, padding: 16, marginBottom: 20 },
  authorRow: { flexDirection: 'row', alignItems: 'center', marginBottom: 16 },
  avatar: { width: 44, height: 44, borderRadius: 22, alignItems: 'center', justifyContent: 'center', marginRight: 12 },
  avatarText: { fontSize: 16, fontWeight: 'bold', color: '#FFFFFF' },
  authorInfo: { flex: 1 },
  authorName: { fontSize: 15, fontWeight: '600' },
  time: { fontSize: 12, marginTop: 2 },
  urgentBadge: { backgroundColor: '#EF444420', paddingHorizontal: 10, paddingVertical: 4, borderRadius: 12 },
  urgentText: { fontSize: 12, color: '#EF4444', fontWeight: '600' },
  prayerTitle: { fontSize: 22, fontWeight: 'bold', marginBottom: 12 },
  prayerContent: { fontSize: 15, lineHeight: 22, marginBottom: 16 },
  statsRow: { flexDirection: 'row', gap: 16, paddingTop: 12, borderTopWidth: 1 },
  statText: { fontSize: 13 },
  answeredText: { fontSize: 13, color: '#10B981', fontWeight: '500' },
  sectionTitle: { fontSize: 13, fontWeight: '600', marginBottom: 12, textTransform: 'uppercase', letterSpacing: 0.5 },
  reactionsRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginBottom: 24 },
  reactionBtn: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 14, paddingVertical: 10, borderRadius: 20, borderWidth: 1 },
  reactionEmoji: { fontSize: 16, marginRight: 6 },
  reactionLabel: { fontSize: 13 },
  commentsList: { borderRadius: 16, padding: 16, marginBottom: 24 },
  commentItem: { paddingVertical: 12, borderBottomWidth: 1 },
  commentHeader: { flexDirection: 'row', alignItems: 'center', marginBottom: 8 },
  commentAvatar: { width: 32, height: 32, borderRadius: 16, alignItems: 'center', justifyContent: 'center', marginRight: 10 },
  commentAvatarText: { fontSize: 13, fontWeight: 'bold', color: '#8B5CF6' },
  commentInfo: { flex: 1 },
  commentAuthor: { fontSize: 14, fontWeight: '600' },
  commentTime: { fontSize: 11, marginTop: 1 },
  commentContent: { fontSize: 14, lineHeight: 20 },
  emptyComments: { padding: 40, alignItems: 'center', marginBottom: 24 },
  commentInput: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 16, paddingVertical: 12, borderTopWidth: 1 },
  commentField: { flex: 1, borderRadius: 12, paddingHorizontal: 14, paddingVertical: 10, fontSize: 15, marginRight: 8, maxHeight: 80 },
  sendBtn: { width: 40, height: 40, borderRadius: 20, alignItems: 'center', justifyContent: 'center' },
  sendBtnText: { fontSize: 18, color: '#FFFFFF' },
});