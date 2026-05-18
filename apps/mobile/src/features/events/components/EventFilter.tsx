import React, { useCallback, useMemo } from 'react';
import { View, Text, TouchableOpacity, ScrollView } from 'react-native';
import { useColorScheme } from '../../../hooks/useColorScheme';
import { EventFilter as EventFilterType, EventType } from '../../../types';

interface EventFilterProps {
  filters: EventFilterType;
  onChange: (filters: EventFilterType) => void;
}

const eventTypeOptions: { value: EventType | ''; label: string }[] = [
  { value: '', label: 'Todos' },
  { value: 'CULTO', label: 'Culto' },
  { value: 'REUNIAO', label: 'Reunião' },
  { value: 'ESTUDO', label: 'Estudo' },
  { value: 'EVENTO_SOCIAL', label: 'Social' },
  { value: 'EVENTO_ESPECIAL', label: 'Especial' },
  { value: 'ESCOLA_DOMINICAL', label: 'E. Dominical' },
  { value: 'JEJUM', label: 'Jejum' },
  { value: 'VIGILIA', label: 'Vigília' },
  { value: 'RETIRO', label: 'Retiro' },
  { value: 'OUTRO', label: 'Outro' },
];

function getMonths(): { label: string; value: string }[] {
  const months: { label: string; value: string }[] = [];
  const now = new Date();
  for (let i = -1; i < 4; i++) {
    const d = new Date(now.getFullYear(), now.getMonth() + i, 1);
    months.push({
      label: d.toLocaleDateString('pt-BR', { month: 'long', year: 'numeric' }),
      value: `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`,
    });
  }
  return months;
}

const presetRanges = [
  { label: 'Hoje', days: 0 },
  { label: '7 Dias', days: 7 },
  { label: '30 Dias', days: 30 },
  { label: '90 Dias', days: 90 },
];

function getDateRange(days: number): { start: string; end: string } {
  const now = new Date();
  const start = new Date(now);
  const end = new Date(now);
  end.setDate(end.getDate() + (days || 1));
  return {
    start: start.toISOString().split('T')[0],
    end: end.toISOString().split('T')[0],
  };
}

export function EventFilter({ filters, onChange }: EventFilterProps) {
  const { isDark } = useColorScheme();
  const months = useMemo(() => getMonths(), []);

  const handleTypeChange = useCallback(
    (type: EventType | '') => {
      onChange({ ...filters, type: type || undefined });
    },
    [filters, onChange]
  );

  const handleDateRange = useCallback(
    (days: number) => {
      const range = getDateRange(days);
      onChange({
        ...filters,
        startDate: range.start,
        endDate: range.end,
      });
    },
    [filters, onChange]
  );

  const handleMonthSelect = useCallback(
    (month: string) => {
      const [year, monthNum] = month.split('-');
      const startDate = `${month}-01`;
      const lastDay = new Date(Number(year), Number(monthNum), 0).getDate();
      const endDate = `${month}-${String(lastDay).padStart(2, '0')}`;
      onChange({
        ...filters,
        startDate,
        endDate,
      });
    },
    [filters, onChange]
  );

  const currentMonth = `${new Date().getFullYear()}-${String(new Date().getMonth() + 1).padStart(2, '0')}`;

  return (
    <View className="mb-4">
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={{ paddingHorizontal: 20, gap: 8 }}
        className="mb-3"
      >
        {presetRanges.map((range) => {
          const rangeDates = getDateRange(range.days);
          const isActive =
            filters.startDate === rangeDates.start &&
            filters.endDate === rangeDates.end;
          return (
            <TouchableOpacity
              key={range.label}
              onPress={() => handleDateRange(range.days)}
              activeOpacity={0.7}
              className={`rounded-full px-4 py-2 ${
                isActive
                  ? 'bg-purple-600'
                  : isDark
                  ? 'bg-neutral-800'
                  : 'bg-neutral-100'
              }`}
            >
              <Text
                className={`text-sm font-medium ${
                  isActive
                    ? 'text-white'
                    : isDark
                    ? 'text-neutral-200'
                    : 'text-neutral-700'
                }`}
              >
                {range.label}
              </Text>
            </TouchableOpacity>
          );
        })}
      </ScrollView>

      <View className="px-6 mb-3">
        <Text
          className="text-xs font-semibold uppercase tracking-wider mb-2"
          style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}
        >
          Mês
        </Text>
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={{ gap: 8 }}
        >
          {months.map((month) => {
            const isActive = filters.startDate?.startsWith(month.value);
            return (
              <TouchableOpacity
                key={month.value}
                onPress={() => handleMonthSelect(month.value)}
                activeOpacity={0.7}
                className={`rounded-full px-4 py-2 ${
                  isActive
                    ? 'bg-purple-600'
                    : isDark
                    ? 'bg-neutral-800'
                    : 'bg-neutral-100'
                }`}
              >
                <Text
                  className={`text-sm font-medium ${
                    isActive
                      ? 'text-white'
                      : isDark
                      ? 'text-neutral-200'
                      : 'text-neutral-700'
                  }`}
                >
                  {month.label.charAt(0).toUpperCase() + month.label.slice(1)}
                </Text>
              </TouchableOpacity>
            );
          })}
        </ScrollView>
      </View>

      <View className="px-6">
        <Text
          className="text-xs font-semibold uppercase tracking-wider mb-2"
          style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}
        >
          Tipo
        </Text>
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={{ gap: 8 }}
        >
          {eventTypeOptions.map((opt) => {
            const isActive = opt.value
              ? filters.type === opt.value
              : !filters.type;
            return (
              <TouchableOpacity
                key={opt.value || 'all'}
                onPress={() => handleTypeChange(opt.value)}
                activeOpacity={0.7}
                className={`rounded-full px-4 py-2 ${
                  isActive
                    ? 'bg-purple-600'
                    : isDark
                    ? 'bg-neutral-800'
                    : 'bg-neutral-100'
                }`}
              >
                <Text
                  className={`text-sm font-medium ${
                    isActive
                      ? 'text-white'
                      : isDark
                      ? 'text-neutral-300'
                      : 'text-neutral-700'
                  }`}
                >
                  {opt.label}
                </Text>
              </TouchableOpacity>
            );
          })}
        </ScrollView>
      </View>
    </View>
  );
}
