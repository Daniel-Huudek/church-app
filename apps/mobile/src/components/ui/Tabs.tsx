import React, { useRef, useEffect } from 'react';
import { View, Text, ScrollView, TouchableOpacity, LayoutChangeEvent } from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSpring,
} from 'react-native-reanimated';
import { useColorScheme } from '../../hooks/useColorScheme';
import { Badge } from './Badge';

interface Tab {
  key: string;
  label: string;
  badgeCount?: number;
}

export interface TabsProps {
  tabs: Tab[];
  activeTab: string;
  onTabChange: (key: string) => void;
  className?: string;
}

export function Tabs({ tabs, activeTab, onTabChange, className = '' }: TabsProps) {
  const { isDark } = useColorScheme();
  const indicatorLeft = useSharedValue(0);
  const indicatorWidth = useSharedValue(0);
  const tabPositions = useRef<Map<string, { x: number; w: number }>>(new Map());

  useEffect(() => {
    const pos = tabPositions.current.get(activeTab);
    if (pos) {
      indicatorLeft.value = withSpring(pos.x, { damping: 20, stiffness: 200 });
      indicatorWidth.value = withSpring(pos.w, { damping: 20, stiffness: 200 });
    }
  }, [activeTab, indicatorLeft, indicatorWidth]);

  const indicatorStyle = useAnimatedStyle(() => ({
    left: indicatorLeft.value,
    width: indicatorWidth.value,
  }));

  const handleLayout = (key: string, event: LayoutChangeEvent) => {
    const { x, width } = event.nativeEvent.layout;
    tabPositions.current.set(key, { x, w: width });
    if (key === activeTab) {
      indicatorLeft.value = x;
      indicatorWidth.value = width;
    }
  };

  return (
    <View className={className}>
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        className="flex-1"
      >
        <View className={`flex-row border-b ${isDark ? 'border-neutral-800' : 'border-neutral-200'}`}>
          {tabs.map((tab) => {
            const isActive = tab.key === activeTab;
            return (
              <TouchableOpacity
                key={tab.key}
                onLayout={(e) => handleLayout(tab.key, e)}
                onPress={() => onTabChange(tab.key)}
                className="px-4 py-3 flex-row items-center"
                activeOpacity={0.7}
              >
                <Text
                  className={`text-sm font-medium ${
                    isActive
                      ? isDark ? 'text-purple-400' : 'text-purple-600'
                      : isDark ? 'text-neutral-400' : 'text-neutral-500'
                  }`}
                >
                  {tab.label}
                </Text>
                {tab.badgeCount !== undefined && tab.badgeCount > 0 && (
                  <View className="ml-1.5">
                    <Badge variant="primary" count={tab.badgeCount} />
                  </View>
                )}
              </TouchableOpacity>
            );
          })}
        </View>
        <Animated.View
          style={indicatorStyle}
          className={`absolute bottom-0 h-0.5 rounded-full ${
            isDark ? 'bg-purple-400' : 'bg-purple-600'
          }`}
        />
      </ScrollView>
    </View>
  );
}
