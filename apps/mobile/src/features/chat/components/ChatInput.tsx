import React, { useState, useRef, useCallback, useEffect } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withTiming,
  Easing,
} from 'react-native-reanimated';
import { useColorScheme } from '../../../hooks/useColorScheme';

interface ChatInputProps {
  onSend: (text: string) => void;
  onAttach?: () => void;
  onEmoji?: () => void;
  onAudio?: () => void;
  placeholder?: string;
  disabled?: boolean;
  typingUsers?: string[];
}

export function ChatInput({
  onSend,
  onAttach,
  onEmoji,
  onAudio,
  placeholder = 'Digite uma mensagem...',
  disabled = false,
  typingUsers = [],
}: ChatInputProps) {
  const { isDark } = useColorScheme();
  const [text, setText] = useState('');
  const [inputHeight, setInputHeight] = useState(40);
  const inputRef = useRef<TextInput>(null);
  const typingOpacity = useSharedValue(0);

  useEffect(() => {
    typingOpacity.value = withTiming(typingUsers.length > 0 ? 1 : 0, {
      duration: 200,
      easing: Easing.out(Easing.cubic),
    });
  }, [typingUsers.length]);

  const typingStyle = useAnimatedStyle(() => ({
    opacity: typingOpacity.value,
    marginBottom: typingOpacity.value * 4,
  }));

  const handleSend = useCallback(() => {
    const trimmed = text.trim();
    if (trimmed.length === 0) return;
    onSend(trimmed);
    setText('');
    setInputHeight(40);
  }, [text, onSend]);

  const isEmpty = text.trim().length === 0;

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      keyboardVerticalOffset={Platform.OS === 'ios' ? 90 : 0}
    >
      <Animated.View style={typingStyle} className="px-4">
        {typingUsers.length > 0 && (
          <View className="flex-row items-center">
            <View className="flex-row">
              {[0, 1, 2].map((i) => (
                <View
                  key={i}
                  className="w-1.5 h-1.5 rounded-full mx-0.5 bg-purple-500"
                  style={{
                    opacity: 0.4 + i * 0.3,
                  }}
                />
              ))}
            </View>
            <Text
              className="text-xs ml-2 font-medium"
              style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}
            >
              {typingUsers.join(', ')}{' '}
              {typingUsers.length === 1 ? 'está' : 'estão'} digitando...
            </Text>
          </View>
        )}
      </Animated.View>

      <View
        className="flex-row items-end px-3 py-2"
        style={{
          backgroundColor: isDark ? '#12121A' : '#F9FAFB',
          borderTopWidth: 1,
          borderTopColor: isDark ? '#1F2937' : '#E5E7EB',
        }}
      >
        <TouchableOpacity
          onPress={onAttach}
          className="w-10 h-10 rounded-full items-center justify-center mb-0.5"
          activeOpacity={0.6}
        >
          <Text
            className="text-xl"
            style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}
          >
            📎
          </Text>
        </TouchableOpacity>

        <View
          className="flex-1 rounded-2xl px-4 mx-1"
          style={{
            backgroundColor: isDark ? '#1A1A2E' : '#FFFFFF',
            borderWidth: 1,
            borderColor: isDark ? '#1F2937' : '#E5E7EB',
          }}
        >
          <TextInput
            ref={inputRef}
            className="text-base py-2.5 max-h-24"
            style={{
              color: isDark ? '#F9FAFB' : '#111827',
              minHeight: inputHeight,
            }}
            placeholder={placeholder}
            placeholderTextColor={isDark ? '#6B7280' : '#9CA3AF'}
            value={text}
            onChangeText={setText}
            onContentSizeChange={(e) =>
              setInputHeight(Math.min(e.nativeEvent.contentSize.height, 96))
            }
            multiline
            maxLength={2000}
          />
        </View>

        <TouchableOpacity
          onPress={onEmoji}
          className="w-10 h-10 rounded-full items-center justify-center mb-0.5"
          activeOpacity={0.6}
        >
          <Text
            className="text-xl"
            style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}
          >
            😊
          </Text>
        </TouchableOpacity>

        {isEmpty ? (
          <TouchableOpacity
            onPress={onAudio}
            className="w-10 h-10 rounded-full items-center justify-center mb-0.5"
            activeOpacity={0.6}
          >
            <Text
              className="text-xl"
              style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}
            >
              🎤
            </Text>
          </TouchableOpacity>
        ) : (
          <TouchableOpacity
            onPress={handleSend}
            disabled={disabled}
            className="w-10 h-10 rounded-full items-center justify-center mb-0.5 bg-purple-600"
            activeOpacity={0.7}
          >
            <Text className="text-base text-white">➤</Text>
          </TouchableOpacity>
        )}
      </View>
    </KeyboardAvoidingView>
  );
}
