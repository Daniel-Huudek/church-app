import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/finance_provider.dart';

class FinanceTransactionsScreen extends ConsumerWidget {
  const FinanceTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : Colors.white;
    final t1 = isDark ? AppColors.darkText : AppColors.lightText;
    final t2 = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final state = ref.watch(transactionListProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: GestureDetector(
            onTap: () {
              ref.invalidate(financeDashboardProvider);
              context.pop();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_back_rounded, size: 22,
                color: isDark ? AppColors.darkText : AppColors.lightText),
            ),
          ),
        ),
        title: Text('Lançamentos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: t1)),
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Erro: ${state.error}', style: TextStyle(color: AppColors.error)))
              : state.data.isEmpty
                  ? Center(child: Text('Nenhum lançamento', style: TextStyle(color: t2)))
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
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: (isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(child: Text(isIncome ? '💰' : '💳', style: const TextStyle(fontSize: 20))),
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
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                                      color: isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Excluir'),
                                        content: Text('Excluir "${t.description}"?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir', style: TextStyle(color: Colors.red))),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await ref.read(transactionListProvider.notifier).delete(t.id);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                  ),
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
