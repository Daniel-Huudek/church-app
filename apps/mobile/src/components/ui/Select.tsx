import React, { useState, useCallback, useMemo } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  TextInput,
  Modal,
  FlatList,
} from 'react-native';
import { useColorScheme } from '../../hooks/useColorScheme';

interface SelectOption {
  label: string;
  value: string;
}

export interface SelectProps {
  options: SelectOption[];
  value?: string | string[];
  onChange: (value: string | string[]) => void;
  placeholder?: string;
  label?: string;
  multiple?: boolean;
  searchable?: boolean;
  error?: string;
  className?: string;
}

export function Select({
  options,
  value,
  onChange,
  placeholder = 'Select...',
  label,
  multiple = false,
  searchable = false,
  error,
  className = '',
}: SelectProps) {
  const { isDark } = useColorScheme();
  const [visible, setVisible] = useState(false);
  const [search, setSearch] = useState('');

  const isMulti = multiple;

  const selectedValues = useMemo(() => {
    if (!value) return [];
    return Array.isArray(value) ? value : [value];
  }, [value]);

  const filteredOptions = useMemo(() => {
    if (!searchable || !search) return options;
    return options.filter((o) =>
      o.label.toLowerCase().includes(search.toLowerCase())
    );
  }, [options, search, searchable]);

  const displayText = useMemo(() => {
    if (!value || (Array.isArray(value) && value.length === 0)) {
      return placeholder;
    }
    const selected = options.filter((o) =>
      Array.isArray(value) ? value.includes(o.value) : o.value === value
    );
    if (selected.length === 0) return placeholder;
    return selected.map((s) => s.label).join(', ');
  }, [value, options, placeholder]);

  const handleSelect = useCallback(
    (option: SelectOption) => {
      if (isMulti) {
        const current = Array.isArray(value) ? value : [];
        const exists = current.includes(option.value);
        const next = exists
          ? current.filter((v) => v !== option.value)
          : [...current, option.value];
        onChange(next);
      } else {
        onChange(option.value);
        setVisible(false);
      }
    },
    [isMulti, value, onChange]
  );

  const isSelected = (optionValue: string) => selectedValues.includes(optionValue);

  return (
    <View className={`mb-4 ${className}`}>
      {label && (
        <Text
          className={`text-sm font-medium mb-1.5 ${
            isDark ? 'text-neutral-200' : 'text-neutral-700'
          }`}
        >
          {label}
        </Text>
      )}
      <TouchableOpacity
        onPress={() => setVisible(true)}
        className={`
          flex-row items-center justify-between rounded-xl px-4 py-3.5 border
          ${isDark ? 'border-neutral-700 bg-[#1A1A2E]' : 'border-neutral-200 bg-white'}
          ${error ? 'border-red-500' : ''}
        `}
        activeOpacity={0.7}
      >
        <Text
          className={`text-base flex-1 ${
            value && (Array.isArray(value) ? value.length > 0 : true)
              ? isDark ? 'text-neutral-100' : 'text-neutral-900'
              : isDark ? 'text-neutral-500' : 'text-neutral-400'
          }`}
          numberOfLines={1}
        >
          {displayText}
        </Text>
        <Text className={isDark ? 'text-neutral-400' : 'text-neutral-500'}>
          ▼
        </Text>
      </TouchableOpacity>
      {error && <Text className="text-red-500 text-xs mt-1 ml-1">{error}</Text>}

      <Modal
        visible={visible}
        transparent
        animationType="slide"
        onRequestClose={() => setVisible(false)}
      >
        <View className="flex-1 justify-end">
          <TouchableOpacity
            className="flex-1 bg-black/50"
            activeOpacity={1}
            onPress={() => setVisible(false)}
          />
          <View
            className={`
              max-h-[60%] rounded-t-3xl px-4 pt-4 pb-8
              ${isDark ? 'bg-[#12121A]' : 'bg-white'}
            `}
          >
            <View className="items-center mb-4">
              <View
                className={`w-10 h-1 rounded-full ${
                  isDark ? 'bg-neutral-700' : 'bg-neutral-300'
                }`}
              />
            </View>

            {searchable && (
              <TextInput
                className={`
                  rounded-xl px-4 py-3 mb-3 text-base border
                  ${isDark ? 'bg-neutral-800 border-neutral-700 text-neutral-100' : 'bg-neutral-100 border-neutral-200 text-neutral-900'}
                `}
                placeholder="Search..."
                placeholderTextColor={isDark ? '#6B7280' : '#9CA3AF'}
                value={search}
                onChangeText={setSearch}
              />
            )}

            {isMulti && (
              <TouchableOpacity
                onPress={() => setVisible(false)}
                className="self-end mb-2 px-4 py-2"
              >
                <Text className="text-purple-600 font-semibold">Done</Text>
              </TouchableOpacity>
            )}

            <FlatList
              data={filteredOptions}
              keyExtractor={(item) => item.value}
              showsVerticalScrollIndicator={false}
              renderItem={({ item }) => {
                const sel = isSelected(item.value);
                return (
                  <TouchableOpacity
                    onPress={() => handleSelect(item)}
                    className={`
                      flex-row items-center justify-between px-4 py-3.5 rounded-xl mb-1
                      ${sel ? (isDark ? 'bg-purple-900/30' : 'bg-purple-50') : ''}
                    `}
                    activeOpacity={0.7}
                  >
                    <Text
                      className={`text-base ${
                        sel
                          ? isDark ? 'text-purple-300 font-medium' : 'text-purple-700 font-medium'
                          : isDark ? 'text-neutral-200' : 'text-neutral-700'
                      }`}
                    >
                      {item.label}
                    </Text>
                    {sel && <Text className="text-purple-600 text-lg">✓</Text>}
                  </TouchableOpacity>
                );
              }}
              ListEmptyComponent={
                <Text
                  className={`text-center py-8 ${
                    isDark ? 'text-neutral-500' : 'text-neutral-400'
                  }`}
                >
                  No options found
                </Text>
              }
            />
          </View>
        </View>
      </Modal>
    </View>
  );
}
