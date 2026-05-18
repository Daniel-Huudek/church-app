import React, { useEffect } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  ScrollView,
  Modal as RNModal,
  Platform,
} from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  withTiming,
} from 'react-native-reanimated';
import { useColorScheme } from '../../hooks/useColorScheme';

export interface ModalProps {
  visible: boolean;
  onClose: () => void;
  title?: string;
  children: React.ReactNode;
  footer?: React.ReactNode;
  className?: string;
}

export function Modal({
  visible,
  onClose,
  title,
  children,
  footer,
  className = '',
}: ModalProps) {
  const { isDark } = useColorScheme();
  const translateY = useSharedValue(600);
  const backdropOpacity = useSharedValue(0);

  useEffect(() => {
    if (visible) {
      translateY.value = withSpring(0, { damping: 25, stiffness: 250 });
      backdropOpacity.value = withTiming(1, { duration: 300 });
    } else {
      translateY.value = withTiming(600, { duration: 250 });
      backdropOpacity.value = withTiming(0, { duration: 250 });
    }
  }, [visible, translateY, backdropOpacity]);

  const backdropStyle = useAnimatedStyle(() => ({
    opacity: backdropOpacity.value,
  }));

  const sheetStyle = useAnimatedStyle(() => ({
    transform: [{ translateY: translateY.value }],
  }));

  return (
    <RNModal
      visible={visible}
      transparent
      animationType="none"
      onRequestClose={onClose}
      statusBarTranslucent
    >
      <View className="flex-1 justify-end">
        <Animated.View
          style={backdropStyle}
          className="absolute inset-0 bg-black/50"
        >
          <TouchableOpacity className="flex-1" activeOpacity={1} onPress={onClose} />
        </Animated.View>

        <Animated.View
          style={sheetStyle}
          className={`
            rounded-t-3xl pt-2 pb-8 max-h-[85%]
            ${isDark ? 'bg-[#12121A]' : 'bg-white'}
            ${className}
          `}
        >
          <View className="items-center pb-1">
            <View
              className={`w-10 h-1 rounded-full ${
                isDark ? 'bg-neutral-700' : 'bg-neutral-300'
              }`}
            />
          </View>

          {title && (
            <View className="flex-row items-center justify-between px-5 py-3">
              <Text
                className={`text-lg font-bold flex-1 ${
                  isDark ? 'text-neutral-100' : 'text-neutral-900'
                }`}
              >
                {title}
              </Text>
              <TouchableOpacity
                onPress={onClose}
                className="w-8 h-8 items-center justify-center rounded-full"
                hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
              >
                <Text
                  className={`text-lg ${
                    isDark ? 'text-neutral-400' : 'text-neutral-500'
                  }`}
                >
                  ✕
                </Text>
              </TouchableOpacity>
            </View>
          )}

          <ScrollView
            className="px-5"
            showsVerticalScrollIndicator={false}
            bounces={Platform.OS === 'ios'}
          >
            {children}
          </ScrollView>

          {footer && (
            <View
              className={`px-5 pt-4 mt-2 border-t ${
                isDark ? 'border-neutral-800' : 'border-neutral-200'
              }`}
            >
              {footer}
            </View>
          )}
        </Animated.View>
      </View>
    </RNModal>
  );
}
