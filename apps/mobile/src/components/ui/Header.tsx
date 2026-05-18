import React from 'react';
import { View, Text, TouchableOpacity, Platform } from 'react-native';
import { useColorScheme } from '../../hooks/useColorScheme';

export interface HeaderProps {
  title: string;
  subtitle?: string;
  largeTitle?: boolean;
  leftIcon?: React.ReactNode;
  onLeftPress?: () => void;
  rightActions?: { icon: React.ReactNode; onPress: () => void }[];
  className?: string;
}

export function Header({
  title,
  subtitle,
  largeTitle = false,
  leftIcon,
  onLeftPress,
  rightActions,
  className = '',
}: HeaderProps) {
  const { isDark } = useColorScheme();

  const paddingTop = Platform.OS === 'ios' ? 56 : 16;

  return (
    <View
      style={{ paddingTop }}
      className={`
        px-4 pb-4
        ${isDark ? 'bg-[#0A0A0F]' : 'bg-white'}
        ${className}
      `}
    >
      <View className="flex-row items-center justify-between">
        <View className="flex-row items-center flex-1">
          {leftIcon && (
            <TouchableOpacity
              onPress={onLeftPress}
              className="mr-3 w-9 h-9 items-center justify-center rounded-full"
              hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
            >
              {leftIcon}
            </TouchableOpacity>
          )}
          <View className="flex-1">
            {largeTitle ? (
              <Text
                className={`text-3xl font-bold ${
                  isDark ? 'text-neutral-100' : 'text-neutral-900'
                }`}
                style={{ letterSpacing: -0.5 }}
              >
                {title}
              </Text>
            ) : (
              <Text
                className={`text-lg font-semibold ${
                  isDark ? 'text-neutral-100' : 'text-neutral-900'
                }`}
              >
                {title}
              </Text>
            )}
            {subtitle && (
              <Text
                className={`text-sm mt-0.5 ${
                  isDark ? 'text-neutral-400' : 'text-neutral-500'
                }`}
              >
                {subtitle}
              </Text>
            )}
          </View>
        </View>

        {rightActions && rightActions.length > 0 && (
          <View className="flex-row items-center gap-1">
            {rightActions.map((action, index) => (
              <TouchableOpacity
                key={index}
                onPress={action.onPress}
                className="w-9 h-9 items-center justify-center rounded-full"
                hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
              >
                {action.icon}
              </TouchableOpacity>
            ))}
          </View>
        )}
      </View>
    </View>
  );
}
