import React, { useCallback, useEffect, useRef } from 'react';
import {
  View,
  ScrollView,
  Dimensions,
  TouchableWithoutFeedback,
} from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  withTiming,
  runOnJS,
} from 'react-native-reanimated';
import { PanGestureHandler, State } from 'react-native-gesture-handler';
import type { PanGestureHandlerEventPayload } from 'react-native-gesture-handler';
import { useColorScheme } from '../../hooks/useColorScheme';

const { height: SCREEN_HEIGHT } = Dimensions.get('window');

type SnapPoint = '25%' | '50%' | '75%' | '90%';

export interface BottomSheetProps {
  visible: boolean;
  onClose: () => void;
  snapPoint?: SnapPoint;
  children: React.ReactNode;
  className?: string;
  showHandle?: boolean;
}

const snapHeights: Record<SnapPoint, number> = {
  '25%': SCREEN_HEIGHT * 0.25,
  '50%': SCREEN_HEIGHT * 0.5,
  '75%': SCREEN_HEIGHT * 0.75,
  '90%': SCREEN_HEIGHT * 0.9,
};

export function BottomSheet({
  visible,
  onClose,
  snapPoint = '50%',
  children,
  className = '',
  showHandle = true,
}: BottomSheetProps) {
  const { isDark } = useColorScheme();
  const translateY = useSharedValue(SCREEN_HEIGHT);
  const backdropOpacity = useSharedValue(0);
  const sheetHeight = snapHeights[snapPoint];

  useEffect(() => {
    if (visible) {
      translateY.value = withSpring(SCREEN_HEIGHT - sheetHeight, {
        damping: 30,
        stiffness: 250,
      });
      backdropOpacity.value = withTiming(1, { duration: 300 });
    } else {
      translateY.value = withTiming(SCREEN_HEIGHT, { duration: 250 });
      backdropOpacity.value = withTiming(0, { duration: 250 });
    }
  }, [visible, sheetHeight, translateY, backdropOpacity]);

  const handleClose = useCallback(() => {
    'worklet';
    translateY.value = withTiming(SCREEN_HEIGHT, { duration: 200 });
    backdropOpacity.value = withTiming(0, { duration: 200 }, () => {
      runOnJS(onClose)();
    });
  }, [translateY, backdropOpacity, onClose]);

  const sheetAnimatedStyle = useAnimatedStyle(() => ({
    transform: [{ translateY: translateY.value }],
  }));

  const backdropAnimatedStyle = useAnimatedStyle(() => ({
    opacity: backdropOpacity.value,
  }));

  const onGestureEvent = (event: { nativeEvent: PanGestureHandlerEventPayload }) => {
    'worklet';
    const { translationY } = event.nativeEvent;
    if (translationY > 0) {
      translateY.value = SCREEN_HEIGHT - sheetHeight + translationY;
    }
  };

  const handleGestureEnd = (nativeEvent: PanGestureHandlerEventPayload) => {
    'worklet';
    const { translationY, velocityY } = nativeEvent;
    if (translationY > 60 || velocityY > 500) {
      handleClose();
    } else {
      translateY.value = withSpring(SCREEN_HEIGHT - sheetHeight, {
        damping: 30,
        stiffness: 250,
      });
    }
  };

  const panRef = useRef(null);

  return (
    <View className="absolute inset-0 z-50" pointerEvents={visible ? 'auto' : 'none'}>
      <TouchableWithoutFeedback onPress={onClose}>
        <Animated.View
          style={backdropAnimatedStyle}
          className="absolute inset-0 bg-black/50"
        />
      </TouchableWithoutFeedback>

      <PanGestureHandler
        onGestureEvent={onGestureEvent}
        onHandlerStateChange={({ nativeEvent }) => {
          if (nativeEvent.state === State.END) {
            handleGestureEnd(nativeEvent);
          }
        }}
      >
        <Animated.View
          style={[
            sheetAnimatedStyle,
            {
              height: sheetHeight,
              borderTopLeftRadius: 24,
              borderTopRightRadius: 24,
            },
          ]}
          className={`
            absolute bottom-0 left-0 right-0
            ${isDark ? 'bg-[#12121A]' : 'bg-white'}
            ${className}
          `}
        >
          {showHandle && (
            <View className="items-center py-3">
              <View
                className={`w-10 h-1 rounded-full ${
                  isDark ? 'bg-neutral-700' : 'bg-neutral-300'
                }`}
              />
            </View>
          )}
          <ScrollView
            className="flex-1 px-5"
            showsVerticalScrollIndicator={false}
            bounces={false}
          >
            {children}
          </ScrollView>
        </Animated.View>
      </PanGestureHandler>
    </View>
  );
}
