import React, { useRef } from 'react';
import { View, Text, TouchableOpacity, Animated as RNAnimated, PanResponder } from 'react-native';
import { useColorScheme } from '../../../hooks/useColorScheme';
import { FadeIn } from '../../../components/animations/FadeIn';
import { getRelativeTime } from '../../../utils/format';

type NotificationType = 'calendar' | 'prayer' | 'finance' | 'schedule' | 'chat' | 'system';

interface NotificationItemData {
  id: string;
  type: NotificationType;
  title: string;
  description: string;
  createdAt: string;
  isRead: boolean;
  actionLabel?: string;
  onAction?: () => void;
}

interface NotificationItemProps {
  notification: NotificationItemData;
  onPress?: () => void;
  onDismiss?: (id: string) => void;
  index?: number;
}

const typeIcons: Record<NotificationType, { icon: string; bg: string }> = {
  calendar: { icon: '📅', bg: 'bg-blue-500/15' },
  prayer: { icon: '🙏', bg: 'bg-purple-500/15' },
  finance: { icon: '💰', bg: 'bg-green-500/15' },
  schedule: { icon: '⏰', bg: 'bg-amber-500/15' },
  chat: { icon: '💬', bg: 'bg-blue-500/15' },
  system: { icon: '📢', bg: 'bg-neutral-500/15' },
};

export function NotificationItem({
  notification,
  onPress,
  onDismiss,
  index = 0,
}: NotificationItemProps) {
  const { isDark } = useColorScheme();
  const translateX = useRef(new RNAnimated.Value(0)).current;
  const config = typeIcons[notification.type] || typeIcons.system;

  const panResponder = useRef(
    PanResponder.create({
      onMoveShouldSetPanResponder: (_, g) =>
        Math.abs(g.dx) > 15 && Math.abs(g.dx) > Math.abs(g.dy),
      onPanResponderMove: (_, g) => {
        if (g.dx < 0) {
          translateX.setValue(g.dx);
        }
      },
      onPanResponderRelease: (_, g) => {
        if (g.dx < -120) {
          onDismiss?.(notification.id);
        } else {
          RNAnimated.spring(translateX, { toValue: 0, useNativeDriver: true }).start();
        }
      },
    })
  ).current;

  return (
    <FadeIn direction="up" delay={index * 60} distance={15}>
      <RNAnimated.View
        style={{ transform: [{ translateX }] }}
        {...(onDismiss ? panResponder.panHandlers : {})}
      >
        <TouchableOpacity
          onPress={onPress}
          activeOpacity={0.7}
          className="flex-row items-start px-4 py-3.5"
          style={{
            backgroundColor: isDark
              ? notification.isRead
                ? 'transparent'
                : 'rgba(139,92,246,0.05)'
              : notification.isRead
              ? 'transparent'
              : '#F5F3FF',
          }}
        >
          <View className="relative">
            <View
              className={`w-10 h-10 rounded-xl items-center justify-center ${config.bg}`}
            >
              <Text className="text-base">{config.icon}</Text>
            </View>
            {!notification.isRead && (
              <View className="absolute -top-0.5 -right-0.5 w-3 h-3 rounded-full bg-purple-600 border-2" style={{ borderColor: isDark ? '#0A0A0F' : '#FFFFFF' }} />
            )}
          </View>

          <View className="flex-1 mx-3">
            <View className="flex-row items-center justify-between">
              <Text
                className={`text-sm font-semibold flex-1 ${
                  notification.isRead
                    ? isDark ? 'text-neutral-300' : 'text-neutral-700'
                    : isDark ? 'text-white' : 'text-neutral-900'
                }`}
                numberOfLines={1}
              >
                {notification.title}
              </Text>
              <Text
                className="text-[10px] ml-2"
                style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}
              >
                {getRelativeTime(notification.createdAt)}
              </Text>
            </View>
            <Text
              className="text-sm mt-0.5 leading-5"
              style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}
              numberOfLines={2}
            >
              {notification.description}
            </Text>
            {notification.actionLabel && notification.onAction && (
              <TouchableOpacity
                onPress={notification.onAction}
                className="mt-2"
                activeOpacity={0.7}
              >
                <Text className="text-sm font-semibold text-purple-600">
                  {notification.actionLabel}
                </Text>
              </TouchableOpacity>
            )}
          </View>

          <Text
            className="text-sm mt-1"
            style={{ color: isDark ? '#4B5563' : '#D1D5DB' }}
          >
            ›
          </Text>
        </TouchableOpacity>
      </RNAnimated.View>
    </FadeIn>
  );
}
