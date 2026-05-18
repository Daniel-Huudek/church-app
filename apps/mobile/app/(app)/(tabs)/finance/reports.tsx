import React, { useState } from 'react';
import { View, Text, ScrollView, TouchableOpacity, Platform } from 'react-native';
import { useRouter } from 'expo-router';
import { useColorScheme } from '../../../../src/hooks/useColorScheme';
import { FadeIn } from '../../../../src/components/animations/FadeIn';
import { SlideUp } from '../../../../src/components/animations/SlideUp';
import { ScaleIn } from '../../../../src/components/animations/ScaleIn';
import { AnimatedCard } from '../../../../src/components/animations/AnimatedCard';
import { Card } from '../../../../src/components/ui/Card';
import { Button } from '../../../../src/components/ui/Button';
import { Divider } from '../../../../src/components/ui/Divider';

type ExportFormat = 'PDF' | 'CSV' | 'Excel';
type DateRange = 'mensal' | 'trimestral' | 'semestral' | 'anual';

interface ReportType {
  id: string;
  title: string;
  description: string;
  icon: string;
  color: string;
  bgColor: string;
}

const reportTypes: ReportType[] = [
  {
    id: 'monthly',
    title: 'Relatório Mensal',
    description: 'Resumo completo de receitas e despesas do mês',
    icon: '📅',
    color: '#8B5CF6',
    bgColor: 'bg-purple-500/15',
  },
  {
    id: 'category',
    title: 'Relatório por Categoria',
    description: 'Análise detalhada agrupada por categorias',
    icon: '📁',
    color: '#3B82F6',
    bgColor: 'bg-blue-500/15',
  },
  {
    id: 'tithes',
    title: 'Relatório de Dízimos/Ofertas',
    description: 'Relatório específico de dízimos e ofertas',
    icon: '❤️',
    color: '#EC4899',
    bgColor: 'bg-pink-500/15',
  },
  {
    id: 'full',
    title: 'Extrato Completo',
    description: 'Extrato geral com todas as movimentações',
    icon: '📄',
    color: '#10B981',
    bgColor: 'bg-green-500/15',
  },
];

const exportFormats: { id: ExportFormat; label: string; icon: string }[] = [
  { id: 'PDF', label: 'PDF', icon: '📕' },
  { id: 'CSV', label: 'CSV', icon: '📗' },
  { id: 'Excel', label: 'Excel', icon: '📘' },
];

const dateRanges: { id: DateRange; label: string }[] = [
  { id: 'mensal', label: 'Mensal' },
  { id: 'trimestral', label: 'Trimestral' },
  { id: 'semestral', label: 'Semestral' },
  { id: 'anual', label: 'Anual' },
];

export default function ReportsScreen() {
  const router = useRouter();
  const { isDark } = useColorScheme();

  const [selectedReport, setSelectedReport] = useState<string | null>(null);
  const [selectedRange, setSelectedRange] = useState<DateRange>('mensal');
  const [selectedExport, setSelectedExport] = useState<ExportFormat>('PDF');

  return (
    <View className="flex-1" style={{ backgroundColor: isDark ? '#0A0A0F' : '#F9FAFB' }}>
      <View
        className="px-4 pb-2"
        style={{ paddingTop: 56, backgroundColor: isDark ? '#0A0A0F' : '#F9FAFB' }}
      >
        <Text
          className="text-3xl font-bold"
          style={{ color: isDark ? '#F9FAFB' : '#111827', letterSpacing: -0.5 }}
        >
          Relatórios
        </Text>
      </View>

      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={{ paddingHorizontal: 16, paddingBottom: 100 }}
      >
        <SlideUp delay={100}>
          <Text
            className="text-sm font-semibold mb-3 uppercase tracking-wider"
            style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}
          >
            Tipo de Relatório
          </Text>
        </SlideUp>

        {reportTypes.map((report, idx) => (
          <ScaleIn key={report.id} delay={150 + idx * 80}>
            <AnimatedCard
              className="mb-3"
              onPress={() => setSelectedReport(report.id === selectedReport ? null : report.id)}
            >
              <View
                className={`rounded-2xl p-5 ${
                  selectedReport === report.id
                    ? isDark
                      ? 'bg-purple-900/20 border border-purple-500/30'
                      : 'bg-purple-50 border border-purple-200'
                    : ''
                }`}
                style={{
                  backgroundColor: isDark
                    ? selectedReport === report.id
                      ? 'rgba(139, 92, 246, 0.1)'
                      : '#12121A'
                    : selectedReport === report.id
                    ? '#F5F3FF'
                    : '#FFFFFF',
                  shadowColor: isDark ? '#000' : '#000',
                  shadowOffset: { width: 0, height: 2 },
                  shadowOpacity: isDark ? 0.3 : 0.06,
                  shadowRadius: 8,
                  elevation: 3,
                  borderWidth: selectedReport === report.id ? 1 : 0,
                  borderColor:
                    selectedReport === report.id
                      ? isDark
                        ? 'rgba(139, 92, 246, 0.3)'
                        : '#C4B5FD'
                      : 'transparent',
                }}
              >
                <View className="flex-row items-center">
                  <View
                    className={`w-14 h-14 rounded-2xl items-center justify-center ${report.bgColor}`}
                  >
                    <Text className="text-2xl">{report.icon}</Text>
                  </View>
                  <View className="flex-1 ml-4">
                    <Text
                      className="text-base font-bold"
                      style={{ color: isDark ? '#F9FAFB' : '#111827' }}
                    >
                      {report.title}
                    </Text>
                    <Text
                      className="text-xs mt-1 leading-4"
                      style={{ color: isDark ? '#6B7280' : '#9CA3AF' }}
                    >
                      {report.description}
                    </Text>
                  </View>
                  <View
                    className={`w-6 h-6 rounded-full items-center justify-center border-2 ${
                      selectedReport === report.id
                        ? 'border-purple-500 bg-purple-500'
                        : isDark
                        ? 'border-neutral-600'
                        : 'border-neutral-300'
                    }`}
                  >
                    {selectedReport === report.id && (
                      <Text className="text-white text-xs font-bold">✓</Text>
                    )}
                  </View>
                </View>

                {selectedReport === report.id && (
                  <View className="mt-4 pt-4" style={{ borderTopWidth: 1, borderTopColor: isDark ? '#1F2937' : '#E5E7EB' }}>
                    <Text
                      className="text-xs font-semibold mb-3"
                      style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}
                    >
                      PERÍODO
                    </Text>
                    <View className="flex-row gap-2 mb-4">
                      {dateRanges.map((range) => (
                        <TouchableOpacity
                          key={range.id}
                          onPress={() => setSelectedRange(range.id)}
                          activeOpacity={0.7}
                          className={`px-3 py-2 rounded-full ${
                            selectedRange === range.id
                              ? 'bg-purple-600'
                              : isDark
                              ? 'bg-neutral-800'
                              : 'bg-neutral-100'
                          }`}
                        >
                          <Text
                            className={`text-xs font-semibold ${
                              selectedRange === range.id
                                ? 'text-white'
                                : isDark
                                ? 'text-neutral-300'
                                : 'text-neutral-600'
                            }`}
                          >
                            {range.label}
                          </Text>
                        </TouchableOpacity>
                      ))}
                    </View>

                    <Text
                      className="text-xs font-semibold mb-3"
                      style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}
                    >
                      FORMATO DE EXPORTAÇÃO
                    </Text>
                    <View className="flex-row gap-3 mb-4">
                      {exportFormats.map((fmt) => (
                        <TouchableOpacity
                          key={fmt.id}
                          onPress={() => setSelectedExport(fmt.id)}
                          activeOpacity={0.7}
                          className={`flex-1 items-center py-3 rounded-xl ${
                            selectedExport === fmt.id
                              ? isDark
                                ? 'bg-purple-600'
                                : 'bg-purple-600'
                              : isDark
                              ? 'bg-neutral-800'
                              : 'bg-neutral-100'
                          }`}
                        >
                          <Text className="text-xl mb-1">{fmt.icon}</Text>
                          <Text
                            className={`text-xs font-semibold ${
                              selectedExport === fmt.id
                                ? 'text-white'
                                : isDark
                                ? 'text-neutral-300'
                                : 'text-neutral-600'
                            }`}
                          >
                            {fmt.label}
                          </Text>
                        </TouchableOpacity>
                      ))}
                    </View>

                    <Button
                      variant="primary"
                      size="md"
                      fullWidth
                      onPress={() => {}}
                    >
                      Gerar Relatório
                    </Button>
                  </View>
                )}
              </View>
            </AnimatedCard>
          </ScaleIn>
        ))}

        <Divider variant="middle" className="my-6" label="EXPORTAÇÃO RÁPIDA" />

        <FadeIn delay={600}>
          <Card variant="elevated" padding="lg" className="mb-4">
            <Text
              className="text-base font-bold mb-4"
              style={{ color: isDark ? '#F9FAFB' : '#111827' }}
            >
              Exportar Dados
            </Text>
            <Text
              className="text-sm mb-4 leading-5"
              style={{ color: isDark ? '#9CA3AF' : '#6B7280' }}
            >
              Exporte todas as transações financeiras no formato desejado para análise externa.
            </Text>

            <View className="flex-row gap-3 mb-4">
              {exportFormats.map((fmt) => (
                <TouchableOpacity
                  key={fmt.id}
                  onPress={() => setSelectedExport(fmt.id)}
                  activeOpacity={0.7}
                  className={`flex-1 items-center py-3 rounded-xl ${
                    selectedExport === fmt.id
                      ? isDark
                        ? 'bg-purple-900/30 border border-purple-500/40'
                        : 'bg-purple-50 border border-purple-200'
                      : isDark
                      ? 'bg-neutral-800'
                      : 'bg-neutral-50'
                  }`}
                >
                  <Text className="text-2xl mb-1">{fmt.icon}</Text>
                  <Text
                    className={`text-xs font-semibold ${
                      selectedExport === fmt.id
                        ? isDark
                          ? 'text-purple-300'
                          : 'text-purple-700'
                        : isDark
                        ? 'text-neutral-300'
                        : 'text-neutral-600'
                    }`}
                  >
                    {fmt.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>

            <Button
              variant="primary"
              size="md"
              fullWidth
              onPress={() => {}}
            >
              Exportar {selectedExport}
            </Button>
          </Card>
        </FadeIn>
      </ScrollView>
    </View>
  );
}
