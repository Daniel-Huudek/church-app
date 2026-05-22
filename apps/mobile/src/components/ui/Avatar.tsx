import React from 'react';
import { View, Text, Image, ImageSourcePropType } from 'react-native';
import { useColorScheme } from '../../hooks/useColorScheme';

type AvatarSize = 'sm' | 'md' | 'lg' | 'xl';

export interface AvatarProps {
  source?: ImageSourcePropType;
  initials?: string;
  size?: AvatarSize;
  showOnline?: boolean;
  badge?: React.ReactNode;
  ring?: boolean;
  className?: string;
}

const sizeConfig: Record<AvatarSize, { dim: number; text: string; online: number; ringW: number }> = {
  sm: { dim: 32, text: 'text-xs', online: 8, ringW: 1.5 },
  md: { dim: 40, text: 'text-sm', online: 10, ringW: 2 },
  lg: { dim: 56, text: 'text-lg', online: 12, ringW: 2 },
  xl: { dim: 80, text: 'text-2xl', online: 14, ringW: 3 },
};

const gradientColors = [
  ['#008CFF', '#EC4899'],
  ['#3B82F6', '#06B6D4'],
  ['#10B981', '#34D399'],
  ['#F59E0B', '#EF4444'],
  ['#008CFF', '#6366F1'],
];

function getInitialColors(name: string): [string, string] {
  let hash = 0;
  for (let i = 0; i < name.length; i++) {
    hash = name.charCodeAt(i) + ((hash << 5) - hash);
  }
  return gradientColors[Math.abs(hash) % gradientColors.length];
}

export function Avatar({
  source,
  initials,
  size = 'md',
  showOnline = false,
  badge,
  ring = false,
  className = '',
}: AvatarProps) {
  const { isDark } = useColorScheme();
  const config = sizeConfig[size];
  const [colorA, colorB] = getInitialColors(initials || '?');

  return (
    <View className={`relative ${className}`} style={{ width: config.dim, height: config.dim }}>
      <View
        style={{
          width: config.dim,
          height: config.dim,
          borderRadius: config.dim / 2,
          borderWidth: ring ? config.ringW : 0,
          borderColor: isDark ? '#374151' : '#E5E7EB',
        }}
      >
        {source ? (
          <Image
            source={source}
            style={{
              width: config.dim,
              height: config.dim,
              borderRadius: config.dim / 2,
            }}
          />
        ) : (
          <View
            style={{
              width: config.dim,
              height: config.dim,
              borderRadius: config.dim / 2,
              backgroundColor: colorA,
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <Text className={`font-bold text-white ${config.text}`}>
              {initials ? initials.slice(0, 2).toUpperCase() : '?'}
            </Text>
          </View>
        )}
      </View>

      {showOnline && (
        <View
          className="absolute bottom-0 right-0 rounded-full bg-green-500 border-2 border-white dark:border-[#0A0A0F]"
          style={{ width: config.online, height: config.online }}
        />
      )}

      {badge && (
        <View className="absolute -top-1 -right-1">{badge}</View>
      )}
    </View>
  );
}
