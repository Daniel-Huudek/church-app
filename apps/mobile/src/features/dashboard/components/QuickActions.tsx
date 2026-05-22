import React from 'react';
import { View, Text, ScrollView, TouchableOpacity } from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withTiming,
  withDelay,
  Easing,
} from 'react-native-reanimated';
import { useColorScheme } from '../../../hooks/useColorScheme';

interface QuickAction {
  id: string;
  icon: React.ReactNode;
  label: string;
  onPress: () => void;
  roles?: string[];
}

interface QuickActionsProps {
  actions?: QuickAction[];
  userRole?: string;
}

const defaultActions: QuickAction[] = [
  {
    id: 'nova-escala',
    icon: <Text className="text-xl">📅</Text>,
    label: 'Nova Escala',
    onPress: () => {},
    roles: ['ADMINISTRADOR', 'PASTOR'],
  },
  {
    id: 'novo-evento',
    icon: <Text className="text-xl">🎉</Text>,
    label: 'Novo Evento',
    onPress: () => {},
    roles: ['ADMINISTRADOR', 'PASTOR'],
  },
  {
    id: 'pedido-oracao',
    icon: <Text className="text-xl">🙏</Text>,
    label: 'Pedido Oração',
    onPress: () => {},
  },
  {
    id: 'nova-transacao',
    icon: <Text className="text-xl">💰</Text>,
    label: 'Nova Transação',
    onPress: () => {},
    roles: ['ADMINISTRADOR', 'FINANCEIRO'],
  },
  {
    id: 'mensagem',
    icon: <Text className="text-xl">💬</Text>,
    label: 'Mensagem',
    onPress: () => {},
  },
];

export function QuickActions({
  actions = defaultActions,
  userRole,
}: QuickActionsProps) {
  const { isDark } = useColorScheme();

  const filteredActions = userRole
    ? actions.filter(
        (a) => !a.roles || a.roles.includes(userRole)
      )
    : actions;

  return (
    <View className="mb-6">
      <Text
        className="text-lg font-bold mb-4 px-6"
        style={{ color: isDark ? '#F9FAFB' : '#111827' }}
      >
        Ações Rápidas
      </Text>
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={{ paddingHorizontal: 20, gap: 12 }}
      >
        {filteredActions.map((action, index) => (
          <ActionItem
            key={action.id}
            action={action}
            index={index}
            isDark={isDark}
          />
        ))}
      </ScrollView>
    </View>
  );
}

function ActionItem({
  action,
  index,
  isDark,
}: {
  action: QuickAction;
  index: number;
  isDark: boolean;
}) {
  const opacity = useSharedValue(0);
  const translateY = useSharedValue(20);

  React.useEffect(() => {
    opacity.value = withDelay(
      index * 80,
      withTiming(1, { duration: 400, easing: Easing.out(Easing.cubic) })
    );
    translateY.value = withDelay(
      index * 80,
      withTiming(0, { duration: 400, easing: Easing.out(Easing.cubic) })
    );
  }, [index]);

  const animatedStyle = useAnimatedStyle(() => ({
    opacity: opacity.value,
    transform: [{ translateY: translateY.value }],
  }));

  return (
    <Animated.View style={animatedStyle}>
      <TouchableOpacity
        onPress={action.onPress}
        activeOpacity={0.7}
        className="items-center"
        style={{ width: 72 }}
      >
        <View
          className="w-14 h-14 rounded-2xl items-center justify-center mb-2"
          style={{
            backgroundColor: isDark ? '#1A1A2E' : '#F5F3FF',
          }}
        >
          {action.icon}
        </View>
        <Text
          className="text-xs text-center font-medium leading-tight"
          style={{ color: isDark ? '#D4D4D4' : '#525252' }}
          numberOfLines={2}
        >
          {action.label}
        </Text>
      </TouchableOpacity>
    </Animated.View>
  );
}
