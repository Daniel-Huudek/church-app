import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../core/config/theme/app_spacing.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/finance_provider.dart';

class FinanceDashboardScreen extends ConsumerWidget {
  const FinanceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(financeDashboardProvider);

    if (state.loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Finanças')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Finanças')),
        body: Center(child: Text('Erro: ${state.error}')),
      );
    }

    final dashboard = state.data!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finanças'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(financeDashboardProvider.notifier).load(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo Atual',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      Formatters.formatCurrency(dashboard.balance),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: dashboard.balance >= 0 ? AppColors.success : AppColors.error,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _BalanceRow(
                            label: 'Receitas',
                            value: Formatters.formatCurrency(dashboard.totalRevenue),
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _BalanceRow(
                            label: 'Despesas',
                            value: Formatters.formatCurrency(dashboard.totalExpenses),
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl2),
              Text(
                'Transações Recentes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              if (dashboard.recentTransactions.isEmpty)
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: Text(
                        'Nenhuma transação recente',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                )
              else
                ...dashboard.recentTransactions.map((t) => _TransactionItem(
                  description: t.description,
                  amount: t.amount,
                  type: t.type,
                  date: Formatters.relativeTime(t.createdAt),
                )),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BalanceRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 14),
        ),
      ],
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final String description;
  final double amount;
  final String type;
  final String date;

  const _TransactionItem({required this.description, required this.amount, required this.type, required this.date});

  @override
  Widget build(BuildContext context) {
    final isIncome = type == 'RECEITA' || type == 'INCOME';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: isIncome ? AppColors.success : AppColors.error,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(description, style: Theme.of(context).textTheme.titleSmall),
                  Text(date, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'} ${Formatters.formatCurrency(amount)}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isIncome ? AppColors.success : AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
