import { View, Text, ScrollView, StyleSheet, ActivityIndicator } from 'react-native';
import { useEffect, useState } from 'react';
import { financeService } from '../../../services/finance';

export default function ReportsScreen() {
  const [report, setReport] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadReport();
  }, []);

  const loadReport = async () => {
    try {
      const now = new Date();
      const res = await financeService.getMonthlyReport(now.getFullYear(), now.getMonth() + 1);
      setReport(res.data.data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <ActivityIndicator style={{ marginTop: 40 }} />;

  const formatMoney = (val: number) =>
    `R$ ${val.toLocaleString('pt-BR', { minimumFractionDigits: 2 })}`;

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Relatório Mensal</Text>
        <Text style={styles.headerSub}>{report?.period}</Text>
      </View>

      <View style={styles.summary}>
        <View style={styles.summaryItem}>
          <Text style={styles.label}>Entradas</Text>
          <Text style={styles.incomeValue}>{formatMoney(report?.income || 0)}</Text>
        </View>
        <View style={styles.summaryItem}>
          <Text style={styles.label}>Saídas</Text>
          <Text style={styles.expenseValue}>{formatMoney(report?.expense || 0)}</Text>
        </View>
        <View style={styles.summaryItem}>
          <Text style={styles.label}>Dízimos</Text>
          <Text style={styles.titheValue}>{formatMoney(report?.tithes || 0)}</Text>
        </View>
        <View style={styles.summaryItem}>
          <Text style={styles.label}>Ofertas</Text>
          <Text style={styles.offeringValue}>{formatMoney(report?.offerings || 0)}</Text>
        </View>
        <View style={[styles.summaryItem, styles.balanceSummary]}>
          <Text style={styles.label}>Saldo</Text>
          <Text style={[styles.balanceValue, { color: (report?.balance || 0) >= 0 ? '#4caf50' : '#ff5252' }]}>
            {formatMoney(report?.balance || 0)}
          </Text>
        </View>
      </View>

      {report?.byCategory?.length > 0 && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Por Categoria</Text>
          {report.byCategory.map((c: any, i: number) => (
            <View key={i} style={styles.row}>
              <Text style={styles.rowLabel}>{c.category}</Text>
              <Text style={styles.rowValue}>{formatMoney(c.value)}</Text>
            </View>
          ))}
        </View>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#f5f5f5' },
  header: { backgroundColor: '#1a73e8', padding: 20, alignItems: 'center' },
  headerTitle: { color: '#fff', fontSize: 18, fontWeight: 'bold' },
  headerSub: { color: 'rgba(255,255,255,0.8)', fontSize: 14, marginTop: 4 },
  summary: { backgroundColor: '#fff', margin: 16, padding: 16, borderRadius: 8, gap: 12 },
  summaryItem: {},
  label: { fontSize: 13, color: '#666' },
  incomeValue: { fontSize: 18, fontWeight: 'bold', color: '#4caf50' },
  expenseValue: { fontSize: 18, fontWeight: 'bold', color: '#ff5252' },
  titheValue: { fontSize: 18, fontWeight: 'bold', color: '#ff9800' },
  offeringValue: { fontSize: 18, fontWeight: 'bold', color: '#9c27b0' },
  balanceSummary: { borderTopWidth: 1, borderTopColor: '#f0f0f0', paddingTop: 12 },
  balanceValue: { fontSize: 22, fontWeight: 'bold' },
  section: { backgroundColor: '#fff', margin: 16, marginTop: 0, padding: 16, borderRadius: 8 },
  sectionTitle: { fontSize: 16, fontWeight: '600', color: '#1a73e8', marginBottom: 12 },
  row: { flexDirection: 'row', justifyContent: 'space-between', paddingVertical: 8, borderBottomWidth: 1, borderBottomColor: '#f5f5f5' },
  rowLabel: { fontSize: 14, color: '#333' },
  rowValue: { fontSize: 14, fontWeight: '600' },
});
