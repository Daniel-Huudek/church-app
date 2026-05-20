import React from 'react';
import { View, Text, TouchableOpacity, Image } from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withTiming,
  Easing,
} from 'react-native-reanimated';
import { useColorScheme } from '../../../hooks/useColorScheme';
import { ChatMessage, MessageType } from '../../../types';
import { formatTime } from '../../../utils/format';

interface ChatBubbleProps {
  message: ChatMessage;
  isSent: boolean;
  onLongPress?: () => void;
  onReplyPress?: () => void;
}

const messageTypeLabels: Record<MessageType, string> = {
  TEXTO: '',
  IMAGEM: '📷 Imagem',
  AUDIO: '🎵 Áudio',
  VIDEO: '🎬 Vídeo',
  DOCUMENTO: '📎 Documento',
  LOCALIZACAO: '📍 Localização',
  SISTEMA: '📢',
};

export function ChatBubble({
  message,
  isSent,
  onLongPress,
  onReplyPress,
}: ChatBubbleProps) {
  const { isDark } = useColorScheme();
  const isSystem = message.type === 'SISTEMA';

  const opacity = useSharedValue(0);
  const scale = useSharedValue(0.9);

  React.useEffect(() => {
    opacity.value = withTiming(1, { duration: 200, easing: Easing.out(Easing.cubic) });
    scale.value = withTiming(1, { duration: 200, easing: Easing.out(Easing.back) });
  }, []);

  const animatedStyle = useAnimatedStyle(() => ({
    opacity: opacity.value,
    transform: [{ scale: scale.value }],
  }));

  if (isSystem) {
    return (
      <View className="items-center my-3">
        <View
          className="rounded-full px-4 py-1.5"
          style={{
            backgroundColor: isDark ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.05)',
          }}
        >
          <Text
            className="text-xs font-medium"
            style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}
          >
            {message.content}
          </Text>
        </View>
      </View>
    );
  }

  const readStatusIcon =
    message.readBy && message.readBy.length > 1
      ? '✓✓'
      : message.deliveredAt
      ? '✓'
      : '○';

  const readStatusColor =
    message.readBy && message.readBy.length > 1
      ? '#3B82F6'
      : isDark
      ? '#6B7280'
      : '#9CA3AF';

  return (
    <Animated.View
      style={animatedStyle}
      className={`mb-2 ${isSent ? 'items-end' : 'items-start'}`}
    >
      {message.replyTo && (
        <TouchableOpacity
          onPress={onReplyPress}
          activeOpacity={0.7}
          className={`max-w-[75%] rounded-lg px-3 py-2 mb-1 ${
            isSent
              ? 'bg-purple-800/40 rounded-tr-none'
              : isDark
              ? 'bg-neutral-800 rounded-tl-none'
              : 'bg-neutral-100 rounded-tl-none'
          }`}
          style={{
            borderLeftWidth: 3,
            borderLeftColor: isSent ? '#66B5FF' : '#008CFF',
          }}
        >
          <Text
            className="text-xs font-semibold mb-0.5"
            style={{ color: isSent ? '#C4B5FD' : '#008CFF' }}
          >
            {message.replyTo.senderName}
          </Text>
          <Text
            className="text-xs"
            style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}
            numberOfLines={2}
          >
            {message.replyTo.content}
          </Text>
        </TouchableOpacity>
      )}

      <TouchableOpacity
        onLongPress={onLongPress}
        activeOpacity={0.9}
        className={`max-w-[75%] rounded-2xl px-4 py-2.5 ${
          isSent
            ? 'bg-purple-600 rounded-tr-sm'
            : isDark
            ? 'bg-neutral-800 rounded-tl-sm'
            : 'bg-neutral-100 rounded-tl-sm'
        }`}
      >
        {!isSent && message.senderName && (
          <Text className="text-xs font-semibold text-purple-400 mb-0.5">
            {message.senderName}
          </Text>
        )}

        {message.type === 'IMAGEM' && message.metadata?.fileUrl ? (
          <View className="overflow-hidden rounded-xl mb-1">
            <Image
              source={{ uri: message.metadata.fileUrl }}
              className="w-48 h-48 rounded-xl"
              resizeMode="cover"
            />
          </View>
        ) : message.type !== 'TEXTO' ? (
          <View className="flex-row items-center py-1">
            <Text className="text-base mr-2">
              {messageTypeLabels[message.type]?.split(' ')[0]}
            </Text>
            <View>
              <Text
                className={`text-sm font-medium ${
                  isSent ? 'text-white' : isDark ? 'text-neutral-200' : 'text-neutral-900'
                }`}
              >
                {messageTypeLabels[message.type]?.split(' ').slice(1).join(' ')}
              </Text>
              {message.metadata?.fileName && (
                <Text
                  className="text-xs mt-0.5"
                  style={{
                    color: isSent ? 'rgba(255,255,255,0.7)' : isDark ? '#9CA3AF' : '#6B7280',
                  }}
                >
                  {message.metadata.fileName}
                </Text>
              )}
            </View>
          </View>
        ) : (
          <Text
            className={`text-sm leading-5 ${
              isSent ? 'text-white' : isDark ? 'text-neutral-200' : 'text-neutral-900'
            }`}
          >
            {message.content}
          </Text>
        )}

        <View
          className={`flex-row items-center mt-1 ${isSent ? 'justify-end' : 'justify-start'}`}
        >
          <Text
            className="text-[10px]"
            style={{
              color: isSent ? 'rgba(255,255,255,0.6)' : isDark ? '#6B7280' : '#9CA3AF',
            }}
          >
            {formatTime(message.createdAt)}
          </Text>
          {isSent && (
            <Text
              className="text-[10px] ml-1"
              style={{ color: readStatusColor }}
            >
              {readStatusIcon}
            </Text>
          )}
        </View>
      </TouchableOpacity>
    </Animated.View>
  );
}
