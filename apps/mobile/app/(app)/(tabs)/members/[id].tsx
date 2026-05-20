import { View, Text, ScrollView, TouchableOpacity, Linking, Platform } from 'react-native';
import { useLocalSearchParams, router } from 'expo-router';
import { useState, useEffect, useCallback } from 'react';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useColorScheme } from '../../../../src/hooks/useColorScheme';
import { useAuth } from '../../../../src/hooks/useAuth';
import { membersService } from '../../../../src/services/members';
import type { Member, MemberHistory } from '../../../../src/types';
import { Avatar, Badge, Card, Chip, Divider, Skeleton, Button, ErrorState } from '../../../../src/components/ui';
import { FadeIn, SlideUp } from '../../../../src/components/animations';

import { formatDate, formatPhone, formatAge, formatInitials } from '../../../../src/utils/format';

const ROLE_LABELS: Record<string, string> = {
  ADMINISTRADOR: 'Administrador',
  PASTOR: 'Pastor',
  FINANCEIRO: 'Financeiro',
  MEMBRO: 'Membro',
  VISITANTE: 'Visitante',
};

const MARITAL_STATUS_LABELS: Record<string, string> = {
  SOLTEIRO: 'Solteiro(a)',
  CASADO: 'Casado(a)',
  DIVORCIADO: 'Divorciado(a)',
  VIUVO: 'Viúvo(a)',
  SEPARADO: 'Separado(a)',
};

function ArrowLeftIcon() {
  return <Text className="text-xl">‹</Text>;
}

function EditIcon() {
  return <Text className="text-base">✏️</Text>;
}

function MessageIcon() {
  return <Text className="text-base">💬</Text>;
}

function CalendarIcon() {
  return <Text className="text-base">📋</Text>;
}

function SectionTitle({ title, isDark }: { title: string; isDark: boolean }) {
  return (
    <Text
      className="text-xs font-semibold uppercase tracking-widest mb-3"
      style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}
    >
      {title}
    </Text>
  );
}

function InfoRow({ label, value, isDark }: { label: string; value?: string | null }) {
  if (!value) return null;
  return (
    <View className="flex-row justify-between items-center py-2">
      <Text className="text-sm" style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}>
        {label}
      </Text>
      <Text
        className="text-sm font-medium text-right max-w-[60%]"
        style={{ color: isDark ? '#F9FAFB' : '#111827' }}
      >
        {value}
      </Text>
    </View>
  );
}

function MemberDetailSkeleton({ isDark }: { isDark: boolean }) {
  return (
    <ScrollView className="flex-1" style={{ backgroundColor: isDark ? '#0A0A0F' : '#F9FAFB' }}>
      <View className="items-center pt-8 pb-6">
        <Skeleton variant="circular" width={96} height={96} className="mb-4" />
        <Skeleton variant="text" width={180} height={24} className="mb-2" />
        <Skeleton variant="text" width={120} height={16} className="mb-3" />
        <Skeleton variant="text" width={80} height={20} className="rounded-full" />
      </View>
      <View className="px-4">
        {[1, 2, 3].map((i) => (
          <View key={i} className="mb-4">
            <Skeleton variant="text" width={100} height={12} className="mb-3" />
            <Skeleton variant="rectangular" width="100%" height={100} className="rounded-2xl" />
          </View>
        ))}
      </View>
    </ScrollView>
  );
}

export default function MemberDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { isDark, colors: themeColors } = useColorScheme();
  const { user } = useAuth();
  const insets = useSafeAreaInsets();

  const [member, setMember] = useState<Member | null>(null);
  const [history, setHistory] = useState<MemberHistory[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadMember = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await membersService.getById(id);
      setMember(res);
      try {
        const histRes = await membersService.getHistory(id, 1, 10);
        setHistory(histRes.data.data || []);
      } catch {
        // history is optional
      }
    } catch {
      setError('Não foi possível carregar os dados do membro.');
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => {
    loadMember();
  }, [loadMember]);

  const handleCall = useCallback(() => {
    if (member?.phone) {
      Linking.openURL(`tel:${member.phone}`);
    }
  }, [member?.phone]);

  const handleEmail = useCallback(() => {
    if (member?.email) {
      Linking.openURL(`mailto:${member.email}`);
    }
  }, [member?.email]);

  const handleAddress = useCallback(() => {
    if (member?.address) {
      const { street, number, neighborhood, city, state } = member.address;
      const q = encodeURIComponent(`${street}, ${number} - ${neighborhood}, ${city} - ${state}`);
      const url = Platform.OS === 'ios'
        ? `maps://app?q=${q}`
        : `geo:0,0?q=${q}`;
      Linking.openURL(url);
    }
  }, [member?.address]);

  if (loading) {
    return (
      <View className="flex-1" style={{ backgroundColor: isDark ? '#0A0A0F' : '#F9FAFB' }}>
        <View className="pt-12 px-4 pb-2">
          <TouchableOpacity onPress={() => router.back()} className="w-9 h-9 items-center justify-center rounded-full" style={{ backgroundColor: isDark ? '#1A1A2E' : '#F3F4F6' }}>
            <ArrowLeftIcon />
          </TouchableOpacity>
        </View>
        <MemberDetailSkeleton isDark={isDark} />
      </View>
    );
  }

  if (error || !member) {
    return (
      <View className="flex-1" style={{ backgroundColor: isDark ? '#0A0A0F' : '#F9FAFB' }}>
        <View className="pt-12 px-4 pb-2">
          <TouchableOpacity onPress={() => router.back()} className="w-9 h-9 items-center justify-center rounded-full" style={{ backgroundColor: isDark ? '#1A1A2E' : '#F3F4F6' }}>
            <ArrowLeftIcon />
          </TouchableOpacity>
        </View>
        <ErrorState
          title="Erro ao carregar"
          message={error || 'Membro não encontrado'}
          retryLabel="Tentar novamente"
          onRetry={loadMember}
        />
      </View>
    );
  }

  const isActive = member.status === 'ATIVO';
  const initials = formatInitials(member.name);
  const age = member.birthDate ? formatAge(member.birthDate) : null;
  const canEdit = user?.id === member.id || user?.role === 'ADMINISTRADOR' || user?.role === 'PASTOR';

  const gradientColors: [string, string][] = [
    ['#8B5CF6', '#EC4899'],
    ['#3B82F6', '#06B6D4'],
    ['#10B981', '#34D399'],
    ['#F59E0B', '#EF4444'],
    ['#A78BFA', '#6366F1'],
  ];
  const hash = member.name.split('').reduce((acc, char) => char.charCodeAt(0) + ((acc << 5) - acc), 0);
  const [avatarGradA, avatarGradB] = gradientColors[Math.abs(hash) % gradientColors.length];

  return (
    <View className="flex-1" style={{ backgroundColor: isDark ? '#0A0A0F' : '#F9FAFB' }}>
      <ScrollView
        className="flex-1"
        contentContainerStyle={{ paddingBottom: insets.bottom + 100 }}
        showsVerticalScrollIndicator={false}
      >
        <FadeIn direction="down" distance={10} duration={300}>
          <View className="pt-12 px-4 pb-2">
            <TouchableOpacity
              onPress={() => router.back()}
              className="w-9 h-9 items-center justify-center rounded-full"
              style={{ backgroundColor: isDark ? '#1A1A2E' : '#F3F4F6' }}
            >
              <ArrowLeftIcon />
            </TouchableOpacity>
          </View>
        </FadeIn>

        <SlideUp distance={30} duration={500}>
          <View className="items-center px-6 pb-6">
            <View
              style={{
                width: 104,
                height: 104,
                borderRadius: 52,
                padding: 3,
                backgroundColor: isActive ? avatarGradA : isDark ? '#374151' : '#D1D5DB',
              }}
            >
              <Avatar source={member.avatar ? { uri: member.avatar } : undefined} initials={initials} size="xl" />
            </View>

            <Text
              className="text-2xl font-bold mt-4"
              style={{ color: isDark ? '#F9FAFB' : '#111827', letterSpacing: -0.5 }}
            >
              {member.name}
            </Text>

            <View className="flex-row items-center mt-2">
              <Badge variant={member.role === 'ADMINISTRADOR' || member.role === 'PASTOR' ? 'primary' : 'info'}>
                {ROLE_LABELS[member.role] || member.role}
              </Badge>
            </View>

            <View className="flex-row items-center mt-3">
              <View
                className="w-2.5 h-2.5 rounded-full mr-2"
                style={{ backgroundColor: isActive ? '#34D399' : '#9CA3AF' }}
              />
              <Text
                className="text-sm font-medium"
                style={{ color: isActive ? '#34D399' : isDark ? '#6B7280' : '#9CA3AF' }}
              >
                {isActive ? 'Ativo' : 'Inativo'}
              </Text>
            </View>
          </View>
        </SlideUp>

        <Divider variant="middle" />

        <SlideUp distance={20} delay={100} duration={400}>
          <View className="px-4 mb-4">
            <SectionTitle title="Contato" isDark={isDark} />
            <Card variant={isDark ? 'filled' : 'elevated'} padding="md">
              <TouchableOpacity onPress={handleCall} className="flex-row items-center py-2" disabled={!member.phone}>
                <Text className="text-base mr-3">📞</Text>
                <Text className="text-sm flex-1" style={{ color: isDark ? '#F9FAFB' : '#111827' }}>
                  {member.phone ? formatPhone(member.phone) : 'Telefone não cadastrado'}
                </Text>
                {member.phone && <Text className="text-lg" style={{ color: isDark ? '#4B5563' : '#D1D5DB' }}>›</Text>}
              </TouchableOpacity>
              <Divider />
              <TouchableOpacity onPress={handleEmail} className="flex-row items-center py-2" disabled={!member.email}>
                <Text className="text-base mr-3">✉️</Text>
                <Text className="text-sm flex-1" style={{ color: isDark ? '#F9FAFB' : '#111827' }}>
                  {member.email || 'Email não cadastrado'}
                </Text>
                {member.email && <Text className="text-lg" style={{ color: isDark ? '#4B5563' : '#D1D5DB' }}>›</Text>}
              </TouchableOpacity>
              {member.address && (
                <>
                  <Divider />
                  <TouchableOpacity onPress={handleAddress} className="flex-row items-center py-2">
                    <Text className="text-base mr-3">📍</Text>
                    <View className="flex-1">
                      <Text className="text-sm" style={{ color: isDark ? '#F9FAFB' : '#111827' }}>
                        {member.address.street}, {member.address.number}
                      </Text>
                      <Text className="text-xs mt-0.5" style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}>
                        {member.address.neighborhood} - {member.address.city}/{member.address.state}
                      </Text>
                    </View>
                    <Text className="text-lg" style={{ color: isDark ? '#4B5563' : '#D1D5DB' }}>›</Text>
                  </TouchableOpacity>
                </>
              )}
            </Card>
          </View>
        </SlideUp>

        <SlideUp distance={20} delay={200} duration={400}>
          <View className="px-4 mb-4">
            <SectionTitle title="Informações" isDark={isDark} />
            <Card variant={isDark ? 'filled' : 'elevated'} padding="md">
              <InfoRow label="Data de Nascimento" value={member.birthDate ? `${formatDate(member.birthDate)} (${age} anos)` : undefined} isDark={isDark} />
              {member.maritalStatus && <InfoRow label="Estado Civil" value={MARITAL_STATUS_LABELS[member.maritalStatus]} isDark={isDark} />}
              {member.baptismDate && <InfoRow label="Batismo" value={formatDate(member.baptismDate)} isDark={isDark} />}
              {member.conversionDate && <InfoRow label="Conversão" value={formatDate(member.conversionDate)} isDark={isDark} />}
              <InfoRow label="Membro desde" value={member.membershipDate ? formatDate(member.membershipDate) : undefined} isDark={isDark} />
              {member.profession && <InfoRow label="Profissão" value={member.profession} isDark={isDark} />}
            </Card>
          </View>
        </SlideUp>

        {member.ministries && member.ministries.length > 0 && (
          <SlideUp distance={20} delay={300} duration={400}>
            <View className="px-4 mb-4">
              <SectionTitle title="Ministérios" isDark={isDark} />
              <View className="flex-row flex-wrap gap-2">
                {member.ministries.map((ministry, idx) => (
                  <Chip key={`${ministry}-${idx}`} label={ministry} variant="outlined" />
                ))}
              </View>
            </View>
          </SlideUp>
        )}

        {history.length > 0 && (
          <SlideUp distance={20} delay={400} duration={400}>
            <View className="px-4 mb-4">
              <SectionTitle title="Histórico" isDark={isDark} />
              <Card variant={isDark ? 'filled' : 'elevated'} padding="md">
                {history.map((item, idx) => (
                  <View key={item.id}>
                    {idx > 0 && <Divider />}
                    <View className="flex-row items-start py-2">
                      <View className="flex-1">
                        <Text className="text-sm font-medium" style={{ color: isDark ? '#F9FAFB' : '#111827' }}>
                          {item.action}
                        </Text>
                        <Text className="text-xs mt-0.5" style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}>
                          {item.description}
                        </Text>
                      </View>
                      <Text className="text-xs" style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}>
                        {formatDate(item.createdAt)}
                      </Text>
                    </View>
                  </View>
                ))}
              </Card>
            </View>
          </SlideUp>
        )}

        <Divider variant="middle" />

        <SlideUp distance={20} delay={500} duration={400}>
          <View className="px-4 py-2">
            <Text className="text-xs font-semibold uppercase tracking-widest mb-3" style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}>
              Ações rápidas
            </Text>
            <View className="flex-row gap-3">
              {canEdit && (
                <View className="flex-1">
                  <Button
                    variant="secondary"
                    size="md"
                    fullWidth
                    leftIcon={<EditIcon />}
                    onPress={() => router.push(`/(app)/(tabs)/members/${id}/edit`)}
                  >
                    Editar
                  </Button>
                </View>
              )}
              <View className="flex-1">
                
              </View>
              <View className="flex-1">
                <Button
                  variant="secondary"
                  size="md"
                  fullWidth
                  leftIcon={<CalendarIcon />}
                  onPress={() => router.push(`/(app)/(tabs)/schedules?memberId=${id}`)}
                >
                  Escalas
                </Button>
              </View>
            </View>
          </View>
        </SlideUp>
      </ScrollView>
    </View>
  );
}
