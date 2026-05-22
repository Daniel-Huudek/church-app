import React from 'react';
import { View, Text, TouchableOpacity } from 'react-native';
import { useColorScheme } from '../../../hooks/useColorScheme';
import { FadeIn } from '../../../components/animations/FadeIn';
import { Member } from '../../../types';

interface MemberCardProps {
  member: Member;
  onPress?: () => void;
  index?: number;
}

export function MemberCard({
  member,
  onPress,
  index = 0,
}: MemberCardProps) {
  const { isDark } = useColorScheme();

  const initials = member.name
    .split(' ')
    .filter((n) => n.length > 0)
    .slice(0, 2)
    .map((n) => n[0].toUpperCase())
    .join('');

  const isActive = member.status === 'ATIVO';

  const gradientColors = [
    ['#008CFF', '#EC4899'],
    ['#3B82F6', '#06B6D4'],
    ['#10B981', '#34D399'],
    ['#F59E0B', '#EF4444'],
    ['#66B5FF', '#6366F1'],
  ];

  const hash = member.name.split('').reduce(
    (acc, char) => char.charCodeAt(0) + ((acc << 5) - acc),
    0
  );
  const [avatarBg] = gradientColors[Math.abs(hash) % gradientColors.length];

  return (
    <FadeIn direction="up" delay={index * 60} distance={15}>
      <TouchableOpacity
        onPress={onPress}
        activeOpacity={0.7}
        className="flex-row items-center rounded-2xl px-4 py-3.5 mb-2"
        style={{
          backgroundColor: isDark ? '#1A1A2E' : '#FFFFFF',
          shadowColor: isDark ? '#000' : '#000',
          shadowOffset: { width: 0, height: 1 },
          shadowOpacity: isDark ? 0.3 : 0.04,
          shadowRadius: 4,
          elevation: 2,
        }}
      >
        <View className="relative">
          <View
            className="w-12 h-12 rounded-full items-center justify-center"
            style={{ backgroundColor: avatarBg }}
          >
            <Text className="text-sm font-bold text-white">{initials}</Text>
          </View>
          <View
            className={`absolute -bottom-0.5 -right-0.5 w-3.5 h-3.5 rounded-full border-2 ${
              isActive
                ? 'bg-green-500'
                : 'bg-neutral-400'
            }`}
            style={{
              borderColor: isDark ? '#1A1A2E' : '#FFFFFF',
            }}
          />
        </View>

        <View className="flex-1 ml-3">
          <Text
            className="text-base font-semibold"
            style={{ color: isDark ? '#F9FAFB' : '#111827' }}
            numberOfLines={1}
          >
            {member.name}
          </Text>
          <View className="flex-row items-center mt-0.5">
            {member.ministries && member.ministries.length > 0 && (
              <>
                <Text
                  className="text-xs"
                  style={{ color: isDark ? '#66B5FF' : '#0066CC' }}
                >
                  ◆
                </Text>
                <Text
                  className="text-xs ml-1 mr-2"
                  style={{ color: isDark ? '#A3A3A3' : '#6B7280' }}
                  numberOfLines={1}
                >
                  {member.ministries[0]}
                </Text>
              </>
            )}
            <Text
              className="text-xs"
              style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}
            >
              {member.phone || member.email}
            </Text>
          </View>
        </View>

        <View
          className={`rounded-full px-2.5 py-0.5 ${
            isActive
              ? isDark
                ? 'bg-green-500/20'
                : 'bg-green-50'
              : isDark
              ? 'bg-neutral-800'
              : 'bg-neutral-100'
          }`}
        >
          <Text
            className={`text-xs font-medium ${
              isActive
                ? 'text-green-600'
                : isDark
                ? 'text-neutral-400'
                : 'text-neutral-500'
            }`}
          >
            {isActive ? 'Ativo' : 'Inativo'}
          </Text>
        </View>

        <Text
          className="ml-2 text-base"
          style={{ color: isDark ? '#4B5563' : '#D1D5DB' }}
        >
          ›
        </Text>
      </TouchableOpacity>
    </FadeIn>
  );
}
