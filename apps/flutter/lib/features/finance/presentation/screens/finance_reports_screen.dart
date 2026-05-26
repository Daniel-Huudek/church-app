import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/finance_provider.dart';

class FinanceReportsScreen extends ConsumerWidget {
  const FinanceReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC);
    final card = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final t1 = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final t2 = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final border = isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);
    final state = ref.watch(reportMonthlyProvider);

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
        title: Text('Relatórios',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t1)),
        actions: [
          if (state.report != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.read(reportMonthlyProvider.notifier).load(),
                color: t2,
              ),
            ),
        ],
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Erro: ${state.error}'))
              : state.report != null
                  ? ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _summaryCard('Receitas Totais', state.report!['totalRevenue'] ?? 0, true, card, t1, t2, border),
                        const SizedBox(height: 12),
                        _summaryCard('Despesas Totais', state.report!['totalExpenses'] ?? 0, false, card, t1, t2, border),
                        const SizedBox(height: 12),
                        _summaryCard('Saldo', state.report!['balance'] ?? 0, true, card, t1, t2, border),
                      ],
                    )
                  : _reportMenu(ref, t1, t2, card, border, bg),
    );
  }

  Widget _reportMenu(WidgetRef ref, Color t1, Color t2, Color card, Color border, Color bg) {
    final reports = [
      ('Receitas Mensais', '📊'),
      ('Despesas Mensais', '📉'),
      ('Balanço Anual', '📋'),
      ('Dízimos', '💰'),
      ('Ofertas', '🙏'),
    ];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        return GestureDetector(
          onTap: () => ref.read(reportMonthlyProvider.notifier).load(),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Text(reports[i].$2, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Text(reports[i].$1,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t1)),
                const Spacer(),
                Icon(Icons.chevron_right, color: t2, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _summaryCard(String label, dynamic value, bool isPositive, Color card, Color t1, Color t2, Color border) {
    final amount = (value is num) ? value.toDouble() : 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: t2)),
          const SizedBox(height: 8),
          Text(
            Formatters.formatCurrency(amount),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: amount >= 0 ? (isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)) : (isPositive ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
            ),
          ),
        ],
      ),
    );
  }
}
