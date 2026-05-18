import { View, Text, ScrollView, TextInput, TouchableOpacity, KeyboardAvoidingView, Platform, Alert } from 'react-native';
import { useLocalSearchParams, router } from 'expo-router';
import { useState, useEffect, useCallback } from 'react';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useColorScheme } from '../../../../src/hooks/useColorScheme';
import { useAuth } from '../../../../src/hooks/useAuth';
import { prayersService } from '../../../../src/services/prayers';
import type { Prayer, PrayerComment, PrayerReactionType } from '../../../../src/types';
import { Avatar, Card, Chip, Divider, Button, Skeleton, ErrorState } from '../../../../src/components/ui';
import { FadeIn, SlideUp } from '../../../../src/components/animations';
import { getRelativeTime, formatDate } from '../../../../src/utils/format';

const REACTION_OPTIONS: { type: PrayerReactionType; emoji: string; label: string }[] = [
  { type: 'ORANDO', emoji: '🙏', label: 'Orando' },
  { type: 'AMEM', emoji: '❤️', label: 'Amém' },
  { type: 'GRATO', emoji: '✝️', label: 'Grato' },
  { type: 'FORCA', emoji: '💪', label: 'Força' },
  { type: 'FE', emoji: '✨', label: 'Fé' },
  { type: 'PAZ', emoji: '🕊️', label: 'Paz' },
];

function ArrowLeftIcon() {
  return <Text className="text-xl">‹</Text>;
}

function PrayerDetailSkeleton({ isDark }: { isDark: boolean }) {
  return (
    <ScrollView className="flex-1" style={{ backgroundColor: isDark ? '#0A0A0F' : '#F9FAFB' }}>
      <View className="pt-12 px-4 pb-4">
        <Skeleton variant="circular" width={36} height={36} />
      </View>
      <View className="px-4">
        <Skeleton variant="card" width="100%" height={250} className="mb-4" />
        <Skeleton variant="card" width="100%" height={100} className="mb-4" />
        <Skeleton variant="card" width="100%" height={200} className="mb-4" />
      </View>
    </ScrollView>
  );
}

function PrayerDetailHeader({
  prayer,
  isDark,
  onBack,
}: {
  prayer: Prayer;
  isDark: boolean;
  onBack: () => void;
}) {
  return (
    <FadeIn direction="down" distance={10} duration={300}>
      <View className="pt-12 px-4 pb-2">
        <TouchableOpacity
          onPress={onBack}
          className="w-9 h-9 items-center justify-center rounded-full"
          style={{ backgroundColor: isDark ? '#1A1A2E' : '#F3F4F6' }}
        >
          <ArrowLeftIcon />
        </TouchableOpacity>
      </View>
    </FadeIn>
  );
}

function PrayerContentSection({ prayer, isDark }: { prayer: Prayer; isDark: boolean }) {
  const initials = prayer.authorName
    ? prayer.authorName.split(' ').filter((n) => n.length > 0).slice(0, 2).map((n) => n[0].toUpperCase()).join('')
    : '?';

  return (
    <SlideUp distance={20} delay={100} duration={400}>
      <Card variant={isDark ? 'filled' : 'elevated'} padding="lg" className="mx-4 mb-4">
        {prayer.isUrgent && (
          <View className="flex-row items-center mb-4">
            <View className="bg-red-500 rounded-full px-3 py-1">
              <Text className="text-xs font-bold text-white uppercase tracking-wider">🔴 Urgente</Text>
            </View>
          </View>
        )}

        <View className="flex-row items-center mb-4">
          <Avatar
            source={prayer.authorAvatar ? { uri: prayer.authorAvatar } : undefined}
            initials={prayer.isAnonymous ? '??' : initials}
            size="md"
            ring
          />
          <View className="flex-1 ml-3">
            <Text className="text-sm font-semibold" style={{ color: isDark ? '#F9FAFB' : '#111827' }}>
              {prayer.isAnonymous ? 'Anônimo' : prayer.authorName}
            </Text>
            <Text className="text-xs" style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}>
              {getRelativeTime(prayer.createdAt)}
            </Text>
          </View>
          {prayer.category && (
            <Chip
              label={prayer.category.name}
              size="sm"
              selected
            />
          )}
        </View>

        <Text className="text-xl font-bold mb-3" style={{ color: isDark ? '#F9FAFB' : '#111827', letterSpacing: -0.3 }}>
          {prayer.title}
        </Text>

        <Text className="text-base leading-6 mb-4" style={{ color: isDark ? '#D4D4D4' : '#525252' }}>
          {prayer.description}
        </Text>

        {prayer.isAnswered && (
          <View
            className="rounded-xl p-4 mb-2"
            style={{
              backgroundColor: isDark ? 'rgba(16,185,129,0.15)' : '#ECFDF5',
              borderWidth: 1,
              borderColor: isDark ? 'rgba(16,185,129,0.3)' : '#D1FAE5',
            }}
          >
            <View className="flex-row items-center mb-1">
              <Text className="text-base mr-2">✅</Text>
              <Text className="text-sm font-semibold" style={{ color: isDark ? '#34D399' : '#059669' }}>
                Pedido atendido
              </Text>
            </View>
            {prayer.answerDescription && (
              <Text className="text-sm mt-1" style={{ color: isDark ? '#D4D4D4' : '#525252' }}>
                {prayer.answerDescription}
              </Text>
            )}
            {prayer.answeredAt && (
              <Text className="text-xs mt-1" style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}>
                {formatDate(prayer.answeredAt)}
              </Text>
            )}
          </View>
        )}

        <View
          className="flex-row items-center pt-4 mt-2"
          style={{
            borderTopWidth: 1,
            borderTopColor: isDark ? '#1F2937' : '#F3F4F6',
          }}
        >
          <View className="flex-row items-center mr-5">
            <Text className="text-sm mr-1.5">🙏</Text>
            <Text className="text-sm font-medium" style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}>
              {prayer.intercessionCount} {prayer.intercessionCount === 1 ? 'intercessor' : 'intercessores'}
            </Text>
          </View>
          <View className="flex-row items-center">
            <Text className="text-sm mr-1.5">💬</Text>
            <Text className="text-sm font-medium" style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}>
              {prayer.comments?.length || 0} {prayer.comments?.length === 1 ? 'comentário' : 'comentários'}
            </Text>
          </View>
        </View>
      </Card>
    </SlideUp>
  );
}

function ReactionsSection({
  prayer,
  isDark,
  onReact,
}: {
  prayer: Prayer;
  isDark: boolean;
  onReact: (type: PrayerReactionType) => void;
}) {
  return (
    <SlideUp distance={20} delay={200} duration={400}>
      <View className="px-4 mb-4">
        <View className="flex-row flex-wrap gap-2">
          {REACTION_OPTIONS.map((reaction) => {
            const isActive = prayer.reactions?.some((r) => r.type === reaction.type);
            return (
              <TouchableOpacity
                key={reaction.type}
                onPress={() => onReact(reaction.type)}
                activeOpacity={0.6}
                className={`flex-row items-center rounded-full px-3.5 py-2 ${
                  isActive
                    ? isDark
                      ? 'bg-purple-900/40'
                      : 'bg-purple-100'
                    : isDark
                    ? 'bg-neutral-800'
                    : 'bg-neutral-100'
                }`}
              >
                <Text className="text-base mr-1.5">{reaction.emoji}</Text>
                <Text
                  className={`text-sm font-medium ${
                    isActive
                      ? 'text-purple-600'
                      : isDark
                      ? 'text-neutral-300'
                      : 'text-neutral-600'
                  }`}
                >
                  {reaction.label}
                </Text>
              </TouchableOpacity>
            );
          })}
        </View>
      </View>
    </SlideUp>
  );
}

function IntercessorsSection({ prayer, isDark }: { prayer: Prayer; isDark: boolean }) {
  if (!prayer.intercessors || prayer.intercessors.length === 0) return null;
  return (
    <SlideUp distance={20} delay={300} duration={400}>
      <View className="px-4 mb-4">
        <Text className="text-xs font-semibold uppercase tracking-widest mb-3" style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}>
          Intercessores
        </Text>
        <Card variant={isDark ? 'filled' : 'elevated'} padding="md">
          <View className="flex-row flex-wrap gap-2">
            {prayer.intercessors.map((intercessor) => (
              <View key={intercessor.id} className="flex-row items-center">
                <Avatar initials={intercessor.memberName} size="sm" />
                <Text className="text-sm ml-1.5" style={{ color: isDark ? '#F9FAFB' : '#111827' }}>
                  {intercessor.memberName}
                </Text>
              </View>
            ))}
          </View>
        </Card>
      </View>
    </SlideUp>
  );
}

function CommentsSection({
  comments,
  isDark,
  onSendComment,
  commentText,
  onChangeComment,
}: {
  comments: PrayerComment[];
  isDark: boolean;
  onSendComment: () => void;
  commentText: string;
  onChangeComment: (text: string) => void;
}) {
  return (
    <SlideUp distance={20} delay={400} duration={400}>
      <View className="px-4 mb-4">
        <Text className="text-xs font-semibold uppercase tracking-widest mb-3" style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}>
          Comentários ({comments.length})
        </Text>

        {comments.length > 0 ? (
          <Card variant={isDark ? 'filled' : 'elevated'} padding="md" className="mb-3">
            {comments.map((comment, idx) => (
              <View key={comment.id}>
                {idx > 0 && <Divider />}
                <View className="flex-row items-start py-2">
                  <Avatar initials={comment.authorName} size="sm" className="mr-2.5" />
                  <View className="flex-1">
                    <View className="flex-row items-center mb-0.5">
                      <Text className="text-sm font-semibold" style={{ color: isDark ? '#F9FAFB' : '#111827' }}>
                        {comment.authorName}
                      </Text>
                      <Text className="text-xs ml-2" style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}>
                        {getRelativeTime(comment.createdAt)}
                      </Text>
                    </View>
                    <Text className="text-sm leading-5" style={{ color: isDark ? '#D4D4D4' : '#525252' }}>
                      {comment.content}
                    </Text>
                  </View>
                </View>
              </View>
            ))}
          </Card>
        ) : (
          <View className="items-center py-6">
            <Text className="text-2xl mb-2">💭</Text>
            <Text className="text-sm" style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}>
              Nenhum comentário ainda
            </Text>
            <Text className="text-xs mt-1" style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}>
              Seja o primeiro a comentar
            </Text>
          </View>
        )}
      </View>
    </SlideUp>
  );
}

export default function PrayerDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { isDark, colors: themeColors } = useColorScheme();
  const { user } = useAuth();
  const insets = useSafeAreaInsets();

  const [prayer, setPrayer] = useState<Prayer | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [commentText, setCommentText] = useState('');
  const [sendingComment, setSendingComment] = useState(false);

  const loadPrayer = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await prayersService.getById(id);
      setPrayer(res);
    } catch {
      setError('Não foi possível carregar o pedido de oração.');
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => {
    loadPrayer();
  }, [loadPrayer]);

  const handleReact = useCallback(async (type: PrayerReactionType) => {
    if (!prayer) return;
    try {
      await prayersService.toggleReaction(prayer.id, type);
      setPrayer((prev) => {
        if (!prev) return prev;
        const hasReaction = prev.reactions?.some((r) => r.type === type && r.memberId === user?.id);
        return {
          ...prev,
          reactions: hasReaction
            ? (prev.reactions?.filter((r) => !(r.type === type && r.memberId === user?.id)) || [])
            : [...(prev.reactions || []), {
                id: '',
                prayerId: prev.id,
                memberId: user?.id || '',
                memberName: user?.name || '',
                type,
                createdAt: new Date().toISOString(),
              }],
        };
      });
    } catch {
      // handled
    }
  }, [prayer, user]);

  const handleIntercede = useCallback(async () => {
    if (!prayer) return;
    try {
      await prayersService.intercede(prayer.id);
      setPrayer((prev) => prev ? { ...prev, intercessionCount: prev.intercessionCount + 1 } : prev);
      Alert.alert('🙏', 'Você está intercedendo por este pedido!');
    } catch {
      Alert.alert('Erro', 'Não foi possível interceder.');
    }
  }, [prayer]);

  const handleMarkAnswered = useCallback(async () => {
    if (!prayer) return;
    Alert.alert(
      'Marcar como atendido',
      'Deseja marcar este pedido como atendido?',
      [
        { text: 'Cancelar', style: 'cancel' },
        {
          text: 'Confirmar',
          onPress: async () => {
            try {
              await prayersService.markAnswered(prayer.id);
              await loadPrayer();
              Alert.alert('✅', 'Pedido marcado como atendido!');
            } catch {
              Alert.alert('Erro', 'Não foi possível marcar como atendido.');
            }
          },
        },
      ]
    );
  }, [prayer, loadPrayer]);

  const handleSendComment = useCallback(async () => {
    if (!prayer || !commentText.trim()) return;
    setSendingComment(true);
    try {
      await prayersService.addComment(prayer.id, commentText.trim());
      setCommentText('');
      await loadPrayer();
    } catch {
      Alert.alert('Erro', 'Não foi possível enviar o comentário.');
    } finally {
      setSendingComment(false);
    }
  }, [prayer, commentText, loadPrayer]);

  const isAuthor = user?.id === prayer?.authorId;

  if (loading) {
    return (
      <View className="flex-1" style={{ backgroundColor: isDark ? '#0A0A0F' : '#F9FAFB' }}>
        <PrayerDetailSkeleton isDark={isDark} />
      </View>
    );
  }

  if (error || !prayer) {
    return (
      <View className="flex-1" style={{ backgroundColor: isDark ? '#0A0A0F' : '#F9FAFB' }}>
        <PrayerDetailHeader prayer={null as any} isDark={isDark} onBack={() => router.back()} />
        <ErrorState
          title="Erro ao carregar"
          message={error || 'Pedido não encontrado'}
          retryLabel="Tentar novamente"
          onRetry={loadPrayer}
        />
      </View>
    );
  }

  return (
    <KeyboardAvoidingView
      className="flex-1"
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      keyboardVerticalOffset={Platform.OS === 'ios' ? 0 : 0}
    >
      <View className="flex-1" style={{ backgroundColor: isDark ? '#0A0A0F' : '#F9FAFB' }}>
        <PrayerDetailHeader prayer={prayer} isDark={isDark} onBack={() => router.back()} />

        <ScrollView
          className="flex-1"
          contentContainerStyle={{ paddingBottom: 100 }}
          showsVerticalScrollIndicator={false}
          keyboardShouldPersistTaps="handled"
        >
          <PrayerContentSection prayer={prayer} isDark={isDark} />

          <ReactionsSection prayer={prayer} isDark={isDark} onReact={handleReact} />

          <View className="flex-row gap-3 px-4 mb-4">
            <View className="flex-1">
              <Button
                variant="primary"
                size="md"
                fullWidth
                onPress={handleIntercede}
              >
                🙏 Interceder
              </Button>
            </View>
            {isAuthor && !prayer.isAnswered && (
              <View className="flex-1">
                <Button
                  variant="success"
                  size="md"
                  fullWidth
                  onPress={handleMarkAnswered}
                >
                  ✅ Atendido
                </Button>
              </View>
            )}
          </View>

          <IntercessorsSection prayer={prayer} isDark={isDark} />

          <Divider variant="middle" />

          <CommentsSection
            comments={prayer.comments || []}
            isDark={isDark}
            commentText={commentText}
            onChangeComment={setCommentText}
            onSendComment={handleSendComment}
          />
        </ScrollView>

        <View
          className="flex-row items-center px-4 py-3"
          style={{
            backgroundColor: isDark ? '#12121A' : '#FFFFFF',
            borderTopWidth: 1,
            borderTopColor: isDark ? '#1F2937' : '#E5E7EB',
            paddingBottom: insets.bottom + 8,
          }}
        >
          <TextInput
            value={commentText}
            onChangeText={setCommentText}
            placeholder="Escreva um comentário..."
            placeholderTextColor={isDark ? '#6B7280' : '#9CA3AF'}
            className="flex-1 text-base rounded-xl px-4 py-2.5 mr-2"
            style={{
              color: isDark ? '#F9FAFB' : '#111827',
              backgroundColor: isDark ? '#1A1A2E' : '#F3F4F6',
            }}
            multiline
            maxLength={500}
          />
          <TouchableOpacity
            onPress={handleSendComment}
            disabled={!commentText.trim() || sendingComment}
            className="w-10 h-10 rounded-full items-center justify-center"
            style={{
              backgroundColor: commentText.trim() ? '#7C3AED' : isDark ? '#374151' : '#D1D5DB',
            }}
          >
            <Text className="text-white text-sm font-bold">
              {sendingComment ? '…' : '→'}
            </Text>
          </TouchableOpacity>
        </View>
      </View>
    </KeyboardAvoidingView>
  );
}


