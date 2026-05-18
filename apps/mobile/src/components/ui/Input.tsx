import React, { useState, useCallback, useRef } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  TextInputProps,
} from 'react-native';
import Animated, {
  useAnimatedStyle,
  withTiming,
  useSharedValue,
} from 'react-native-reanimated';
import { useColorScheme } from '../../hooks/useColorScheme';

type InputVariant = 'outlined' | 'filled';

export interface InputProps extends TextInputProps {
  label?: string;
  error?: string;
  helperText?: string;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
  variant?: InputVariant;
  containerClassName?: string;
}

export function Input({
  label,
  error,
  helperText,
  leftIcon,
  rightIcon,
  variant = 'outlined',
  containerClassName = '',
  className = '',
  onFocus,
  onBlur,
  secureTextEntry,
  ...rest
}: InputProps) {
  const { isDark } = useColorScheme();
  const [isFocused, setIsFocused] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const borderOpacity = useSharedValue(0);
  const inputRef = useRef<TextInput>(null);

  const isPassword = secureTextEntry;

  const handleFocus = useCallback(
    (e: any) => {
      setIsFocused(true);
      borderOpacity.value = withTiming(1, { duration: 200 });
      onFocus?.(e);
    },
    [onFocus, borderOpacity]
  );

  const handleBlur = useCallback(
    (e: any) => {
      setIsFocused(false);
      borderOpacity.value = withTiming(0, { duration: 200 });
      onBlur?.(e);
    },
    [onBlur, borderOpacity]
  );

  const borderAnimatedStyle = useAnimatedStyle(() => ({
    borderColor: error
      ? '#EF4444'
      : isFocused
      ? isDark
        ? '#A78BFA'
        : '#7C3AED'
      : isDark
      ? '#374151'
      : '#E5E7EB',
    borderWidth: variant === 'outlined' ? 1 : 0,
    backgroundColor: variant === 'filled'
      ? isDark ? '#1A1A2E' : '#F3F4F6'
      : 'transparent',
    opacity: 1,
  }));

  return (
    <View className={`mb-4 ${containerClassName}`}>
      {label && (
        <Text
          className={`text-sm font-medium mb-1.5 ${
            isDark ? 'text-neutral-200' : 'text-neutral-700'
          }`}
        >
          {label}
        </Text>
      )}
      <TouchableOpacity activeOpacity={1} onPress={() => inputRef.current?.focus()}>
        <Animated.View
          style={borderAnimatedStyle}
          className={`
            flex-row items-center rounded-xl px-4 py-3
            ${variant === 'outlined' ? (isDark ? 'bg-transparent' : 'bg-white') : ''}
            ${error ? 'border-red-500' : ''}
          `}
        >
          {leftIcon && <View className="mr-3">{leftIcon}</View>}
          <TextInput
            ref={inputRef}
            className={`flex-1 text-base ${
              isDark ? 'text-neutral-100' : 'text-neutral-900'
            } ${className}`}
            placeholderTextColor={isDark ? '#6B7280' : '#9CA3AF'}
            onFocus={handleFocus}
            onBlur={handleBlur}
            secureTextEntry={isPassword && !showPassword}
            {...rest}
          />
          {isPassword && (
            <TouchableOpacity
              onPress={() => setShowPassword(!showPassword)}
              className="ml-2"
              hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
            >
              <Text className={isDark ? 'text-neutral-400' : 'text-neutral-500'}>
                {showPassword ? '🙈' : '👁️'}
              </Text>
            </TouchableOpacity>
          )}
          {rightIcon && !isPassword && <View className="ml-2">{rightIcon}</View>}
        </Animated.View>
      </TouchableOpacity>
      {error && (
        <Text className="text-red-500 text-xs mt-1 ml-1">{error}</Text>
      )}
      {helperText && !error && (
        <Text
          className={`text-xs mt-1 ml-1 ${
            isDark ? 'text-neutral-400' : 'text-neutral-500'
          }`}
        >
          {helperText}
        </Text>
      )}
    </View>
  );
}
