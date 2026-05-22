import React, { useState, useCallback } from 'react';
import { View, Text, TouchableOpacity, ScrollView } from 'react-native';
import { useColorScheme } from '../../../hooks/useColorScheme';
import { ScheduleStatus, ScheduleFilter as ScheduleFilterType } from '../../../types';

interface ScheduleFilterProps {
  filters: ScheduleFilterType;
  onChange: (filters: ScheduleFilterType) => void;
}

const statusOptions: { value: ScheduleStatus | ''; label: string }[] = [
  { value: '', label: 'Todas' },
  { value: 'AGENDADO', label: 'Agendado' },
  { value: 'CONFIRMADO', label: 'Confirmado' },
  { value: 'EM_ANDAMENTO', label: 'Em Andamento' },
  { value: 'CONCLUIDO', label: 'Concluído' },
  { value: 'CANCELADO', label: 'Cancelado' },
];

const ministries = [
  'Louvor',
  'Ensino',
  'Infantil',
  'Juventude',
  'Missões',
  'Ação Social',
  'Diaconia',
  'Intercessão',
];

const presetRanges = [
  { label: 'Hoje', days: 0 },
  { label: '7 Dias', days: 7 },
  { label: '30 Dias', days: 30 },
  { label: '90 Dias', days: 90 },
];

function getDateRange(days: number): { start: string; end: string } {
  const now = new Date();
  const start = new Date(now);
  start.setDate(start.getDate() - (days > 0 ? 0 : 0));
  const end = new Date(now);
  end.setDate(end.getDate() + (days || 1));
  return {
    start: start.toISOString().split('T')[0],
    end: end.toISOString().split('T')[0],
  };
}

export function ScheduleFilter({ filters, onChange }: ScheduleFilterProps) {
  const { isDark } = useColorScheme();
  const [showDatePicker, setShowDatePicker] = useState(false);

  const handleStatusChange = useCallback(
    (status: ScheduleStatus | '') => {
      onChange({ ...filters, status: status || undefined });
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

  const handleMinistryChange = useCallback(
    (ministry: string) => {
      onChange({
        ...filters,
        ministryId: filters.ministryId === ministry ? undefined : ministry,
      });
    },
    [filters, onChange]
  );

  return (
    <View className="mb-4">
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={{ paddingHorizontal: 20, gap: 8 }}
        className="mb-3"
      >
        {presetRanges.map((range) => (
          <TouchableOpacity
            key={range.label}
            onPress={() => handleDateRange(range.days)}
            activeOpacity={0.7}
            className={`rounded-full px-4 py-2 ${
              filters.startDate === getDateRange(range.days).start
                ? 'bg-purple-600'
                : isDark
                ? 'bg-neutral-800'
                : 'bg-neutral-100'
            }`}
          >
            <Text
              className={`text-sm font-medium ${
                filters.startDate === getDateRange(range.days).start
                  ? 'text-white'
                  : isDark
                  ? 'text-neutral-200'
                  : 'text-neutral-700'
              }`}
            >
              {range.label}
            </Text>
          </TouchableOpacity>
        ))}
      </ScrollView>

      <View className="px-6 mb-3">
        <Text
          className="text-xs font-semibold uppercase tracking-wider mb-2"
          style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}
        >
          Status
        </Text>
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={{ gap: 8 }}
        >
          {statusOptions.map((opt) => {
            const isActive = opt.value
              ? filters.status === opt.value
              : !filters.status;
            return (
              <TouchableOpacity
                key={opt.value || 'all'}
                onPress={() => handleStatusChange(opt.value)}
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

      <View className="px-6">
        <Text
          className="text-xs font-semibold uppercase tracking-wider mb-2"
          style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}
        >
          Ministério
        </Text>
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={{ gap: 8 }}
        >
          {ministries.map((ministry) => {
            const isActive = filters.ministryId === ministry;
            return (
              <TouchableOpacity
                key={ministry}
                onPress={() => handleMinistryChange(ministry)}
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
                  {ministry}
                </Text>
              </TouchableOpacity>
            );
          })}
        </ScrollView>
      </View>
    </View>
  );
}
