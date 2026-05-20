import React from 'react';
import { View, Text, TouchableOpacity } from 'react-native';
import { useColorScheme } from '../../../hooks/useColorScheme';
import { FadeIn } from '../../../components/animations/FadeIn';
import { Chat } from '../../../types';
import { getRelativeTime, truncateText } from '../../../utils/format';

interface ChatListItemProps {
  chat: Chat;
  onPress?: () => void;
  index?: number;
}

export function ChatListItem({
  chat,
  onPress,
  index = 0,
}: ChatListItemProps) {
  const { isDark } = useColorScheme();

  const isGroup = chat.type !== 'PRIVADO';
  const otherParticipant = chat.participants?.find(
    (p) => p.memberName !== 'Você'
  );

  const displayName =
    chat.name ||
    (isGroup
      ? chat.participants?.map((p) => p.memberName).join(', ')
      : otherParticipant?.memberName || 'Chat') ||
    'Chat';

  const isOnline = !isGroup && otherParticipant?.memberName === 'Online';

  const gradientColors = [
    ['#008CFF', '#EC4899'],
    ['#3B82F6', '#06B6D4'],
    ['#10B981', '#34D399'],
    ['#F59E0B', '#EF4444'],
    ['#008CFF', '#6366F1'],
  ];

  const hash = displayName.split('').reduce(
    (acc, char) => char.charCodeAt(0) + ((acc << 5) - acc),
    0
  );
  const [avatarBg] = gradientColors[Math.abs(hash) % gradientColors.length];

  const initials = displayName
    .split(' ')
    .filter((n) => n.length > 0)
    .slice(0, 2)
    .map((n) => n[0].toUpperCase())
    .join('');

  return (
    <FadeIn direction="up" delay={index * 60} distance={15}>
      <TouchableOpacity
        onPress={onPress}
        activeOpacity={0.7}
        className="flex-row items-center px-4 py-3.5"
        style={{
          backgroundColor: isDark ? '#0A0A0F' : '#FFFFFF',
        }}
      >
        <View className="relative">
          <View
            className={`w-12 h-12 rounded-full items-center justify-center ${
              isGroup ? '' : ''
            }`}
            style={{ backgroundColor: avatarBg }}
          >
            {isGroup ? (
              <View className="items-center justify-center">
                <Text className="text-base text-white">👥</Text>
              </View>
            ) : (
              <Text className="text-sm font-bold text-white">
                {initials}
              </Text>
            )}
          </View>
          {!isGroup && (
            <View
              className={`absolute -bottom-0.5 -right-0.5 w-3.5 h-3.5 rounded-full border-2 ${
                isOnline ? 'bg-green-500' : 'bg-neutral-400'
              }`}
              style={{
                borderColor: isDark ? '#0A0A0F' : '#FFFFFF',
              }}
            />
          )}
        </View>

        <View className="flex-1 ml-3">
          <View className="flex-row items-center justify-between">
            <View className="flex-row items-center flex-1">
              <Text
                className="text-base font-semibold"
                style={{ color: isDark ? '#F9FAFB' : '#111827' }}
                numberOfLines={1}
              >
                {displayName}
              </Text>
              {chat.isPinned && (
                <Text className="text-xs ml-1.5">📌</Text>
              )}
            </View>
            {chat.lastMessage && (
              <Text
                className="text-xs ml-2"
                style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}
              >
                {getRelativeTime(chat.lastMessage.createdAt)}
              </Text>
            )}
          </View>

          <View className="flex-row items-center mt-0.5">
            <Text
              className="text-sm flex-1"
              style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}
              numberOfLines={1}
            >
              {chat.lastMessage
                ? truncateText(chat.lastMessage.content, 40)
                : 'Nenhuma mensagem ainda'}
            </Text>
            {chat.unreadCount > 0 && (
              <View className="bg-purple-600 rounded-full min-w-[20px] h-5 items-center justify-center px-1.5 ml-2">
                <Text className="text-[10px] font-bold text-white">
                  {chat.unreadCount > 99 ? '99+' : chat.unreadCount}
                </Text>
              </View>
            )}
          </View>
        </View>
      </TouchableOpacity>
    </FadeIn>
  );
}
