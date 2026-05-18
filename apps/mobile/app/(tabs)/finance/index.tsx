import { View, Text, ScrollView, StyleSheet, TouchableOpacity, ActivityIndicator } from 'react-native';
import { useRouter } from 'expo-router';
import { useEffect, useState } from 'react';
import { financeService } from '../../../services/finance';

export default function FinanceDashboardScreen() {
  const router = useRouter();
  const [dashboard, setDashboard] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadDashboard();
  }, []);

  const loadDashboard = async () => {
    try {
      const res = await financeService.getDashboard();
      setDashboard(res.data.data);
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
      <View style={styles.balanceCard}>
        <Text style={styles.balanceTitle}>Saldo Atual</Text>
        <Text style={styles.balanceValue}>{formatMoney(dashboard?.balance?.balance || 0)}</Text>
        <View style={styles.balanceRow}>
          <View style={styles.balanceItem}>
            <Text style={styles.incomeText}>Entradas</Text>
            <Text style={styles.incomeValue}>{formatMoney(dashboard?.balance?.income || 0)}</Text>
          </View>
          <View style={styles.balanceItem}>
            <Text style={styles.expenseText}>Saídas</Text>
            <Text style={styles.expenseValue}>{formatMoney(dashboard?.balance?.expense || 0)}</Text>
          </View>
        </View>
      </View>

      <View style={styles.menu}>
        <TouchableOpacity style={styles.menuItem} onPress={() => router.push('/(tabs)/finance/transactions')}>
          <Text style={styles.menuIcon}>📋</Text>
          <Text style={styles.menuText}>Lançamentos</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.menuItem} onPress={() => router.push('/(tabs)/finance/reports')}>
          <Text style={styles.menuIcon}>📊</Text>
          <Text style={styles.menuText}>Relatórios</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.menuItem} onPress={() => router.push('/(tabs)/finance/cash-flow')}>
          <Text style={styles.menuIcon}>💵</Text>
          <Text style={styles.menuText}>Fluxo de Caixa</Text>
        </TouchableOpacity>
      </View>

      {dashboard?.monthlyHistory && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Histórico Mensal</Text>
          {dashboard.monthlyHistory.map((m: any, i: number) => (
            <View key={i} style={styles.historyRow}>
              <Text style={styles.month}>{m.month}</Text>
              <Text style={styles.incomeValue}>{formatMoney(m.income)}</Text>
              <Text style={styles.expenseValue}>{formatMoney(m.expense)}</Text>
              <Text style={[styles.balanceValue, { fontSize: 14 }]}>{formatMoney(m.balance)}</Text>
            </View>
          ))}
        </View>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#f5f5f5' },
  balanceCard: { backgroundColor: '#1a73e8', margin: 16, padding: 20, borderRadius: 12 },
  balanceTitle: { color: 'rgba(255,255,255,0.8)', fontSize: 14 },
  balanceValue: { color: '#fff', fontSize: 28, fontWeight: 'bold', marginVertical: 8 },
  balanceRow: { flexDirection: 'row', justifyContent: 'space-between', marginTop: 12 },
  balanceItem: { flex: 1 },
  incomeText: { color: 'rgba(255,255,255,0.8)', fontSize: 12 },
  incomeValue: { color: '#4caf50', fontSize: 16, fontWeight: '600' },
  expenseText: { color: 'rgba(255,255,255,0.8)', fontSize: 12 },
  expenseValue: { color: '#ff5252', fontSize: 16, fontWeight: '600' },
  menu: { flexDirection: 'row', margin: 16, gap: 8 },
  menuItem: { flex: 1, backgroundColor: '#fff', padding: 16, borderRadius: 8, alignItems: 'center', elevation: 1 },
  menuIcon: { fontSize: 24, marginBottom: 4 },
  menuText: { fontSize: 13, fontWeight: '500' },
  section: { backgroundColor: '#fff', margin: 16, marginTop: 0, padding: 16, borderRadius: 8 },
  sectionTitle: { fontSize: 16, fontWeight: '600', color: '#1a73e8', marginBottom: 12 },
  historyRow: { flexDirection: 'row', justifyContent: 'space-between', paddingVertical: 6, borderBottomWidth: 1, borderBottomColor: '#f0f0f0' },
  month: { fontSize: 13, color: '#555', flex: 1 },
});
