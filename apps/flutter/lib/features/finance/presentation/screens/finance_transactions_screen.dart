import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/finance_provider.dart';

class FinanceTransactionsScreen extends ConsumerWidget {
  const FinanceTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC);
    final card = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final t1 = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final t2 = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final border = isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);
    final state = ref.watch(transactionListProvider);

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
        title: Text('Transações',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t1)),
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Erro: ${state.error}'))
              : state.data.isEmpty
                  ? Center(child: Text('Nenhuma transação', style: TextStyle(color: t2)))
                  : RefreshIndicator(
                      onRefresh: () => ref.read(transactionListProvider.notifier).load(),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: state.data.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final t = state.data[i];
                          final isIncome = t.isIncome;
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: (isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(isIncome ? '💰' : '💳', style: const TextStyle(fontSize: 20)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(t.description,
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t1)),
                                      const SizedBox(height: 4),
                                      Text(Formatters.formatDate(t.date),
                                          style: TextStyle(fontSize: 13, color: t2)),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${isIncome ? '+' : '-'} ${Formatters.formatCurrency(t.amount)}',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
