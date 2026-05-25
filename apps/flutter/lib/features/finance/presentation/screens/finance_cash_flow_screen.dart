import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/finance_provider.dart';

class FinanceCashFlowScreen extends ConsumerWidget {
  const FinanceCashFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC);
    final card = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final t1 = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final t2 = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final border = isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);
    final state = ref.watch(cashFlowProvider);

    final totalRevenue = state.months.fold<double>(0, (sum, m) => sum + m.revenue);
    final totalExpenses = state.months.fold<double>(0, (sum, m) => sum + m.expenses);
    final currentBalance = state.months.isNotEmpty ? state.months.last.balance : 0.0;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Text('←', style: TextStyle(fontSize: 24)),
          ),
        ),
        title: Text('Fluxo de Caixa',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t1)),
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Erro: ${state.error}'))
              : RefreshIndicator(
                  onRefresh: () => ref.read(cashFlowProvider.notifier).load(),
                  child: ListView(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF008CFF), Color(0xFF0066CC)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Saldo Atual',
                                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
                            const SizedBox(height: 8),
                            Text(
                              Formatters.formatCurrency(currentBalance),
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _stat('Receitas', Formatters.formatCurrency(totalRevenue), Colors.greenAccent),
                                const SizedBox(width: 24),
                                _stat('Despesas', Formatters.formatCurrency(totalExpenses), Colors.redAccent),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text('Mensal',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t1)),
                      ),
                      const SizedBox(height: 12),
                      ...state.months.map((m) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(m.month,
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t1)),
                            ),
                            Text(Formatters.formatCurrency(m.revenue),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF10B981))),
                            const SizedBox(width: 16),
                            Text(Formatters.formatCurrency(m.expenses),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
                          ],
                        ),
                      )),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _stat(String label, String value, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: accent)),
      ],
    );
  }
}
