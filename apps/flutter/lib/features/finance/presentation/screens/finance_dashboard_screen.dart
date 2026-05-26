import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/finance_api.dart';
import '../providers/finance_provider.dart';

class FinanceDashboardScreen extends ConsumerStatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  ConsumerState<FinanceDashboardScreen> createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends ConsumerState<FinanceDashboardScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(financeDashboardProvider);

    if (state.loading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        appBar: _buildAppBar(isDark),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        appBar: _buildAppBar(isDark),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error.withValues(alpha: 0.6)),
                const SizedBox(height: 16),
                Text(state.error!, textAlign: TextAlign.center,
                  style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
              ],
            ),
          ),
        ),
      );
    }

    final dashboard = state.data!;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: _buildAppBar(isDark),
      body: RefreshIndicator(
        onRefresh: () => ref.read(financeDashboardProvider.notifier).load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            _BalanceHeroCard(dashboard: dashboard, isDark: isDark),
            const SizedBox(height: 20),
            _IncomeExpenseRow(dashboard: dashboard, isDark: isDark),
            const SizedBox(height: 20),
            _TabBar(index: _tabIndex, onChanged: (v) => setState(() => _tabIndex = v), isDark: isDark),
            const SizedBox(height: 16),
            if (_tabIndex == 0)
              _DailyView(dashboard: dashboard, isDark: isDark)
            else
              _MonthlyView(dashboard: dashboard, isDark: isDark),
          ],
        ),
      ),
      bottomNavigationBar: _bottomBar(isDark),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: GestureDetector(
          onTap: () {
            if (context.mounted) {
              if (context.canPop()) context.pop(); else context.go('/');
            }
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
      title: Text('Finanças', style: TextStyle(
        fontSize: 22, fontWeight: FontWeight.w700,
        color: isDark ? AppColors.darkText : AppColors.lightText,
      )),
      centerTitle: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => context.push('/finance/transactions'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.receipt_long_rounded, size: 22,
                color: isDark ? AppColors.darkText : AppColors.lightText),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : AppColors.lightBg,
        border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => context.push('/finance/create/EXPENSE'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.remove_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 6),
                      Text('Despesa', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => context.push('/finance/create/INCOME'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 6),
                      Text('Receita', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Tab Bar ----
class _TabBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final bool isDark;

  const _TabBar({required this.index, required this.onChanged, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: ['Diário', 'Mensal'].asMap().entries.map((e) => Expanded(
          child: GestureDetector(
            onTap: () => onChanged(e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: index == e.key
                    ? const Color(0xFF10B981)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(e.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: index == e.key ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }
}

// ---- Daily View ----
class _DailyView extends ConsumerWidget {
  final dynamic dashboard;
  final bool isDark;

  const _DailyView({required this.dashboard, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t2 = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final txState = ref.watch(transactionListProvider);

    if (txState.loading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(24), child: CircularProgressIndicator(),
      ));
    }

    if (txState.error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Erro ao carregar transações', style: TextStyle(color: t2)),
      );
    }

    final transactions = txState.data;
    if (transactions.isEmpty) {
      return _EmptyState(isDark: isDark, message: 'Nenhuma transação');
    }
    return Column(
      children: transactions.map((t) => _TransactionTile(
        description: t.description,
        amount: t.amount,
        type: t.type,
        date: t.date,
        isDark: isDark,
      )).toList(),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final String description;
  final double amount;
  final String type;
  final DateTime date;
  final bool isDark;

  const _TransactionTile({required this.description, required this.amount, required this.type, required this.date, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isIncome = type == 'INCOME' || type == 'TITHE' || type == 'OFFERING';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 4, height: 40,
            decoration: BoxDecoration(
              color: isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15,
                  color: isDark ? AppColors.darkText : AppColors.lightText)),
                const SizedBox(height: 2),
                Text(Formatters.formatDate(date), style: TextStyle(fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'} ${Formatters.formatCurrency(amount)}',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
              color: isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
          ),
        ],
      ),
    );
  }
}

// ---- Monthly View ----
class _MonthlyView extends StatelessWidget {
  final dynamic dashboard;
  final bool isDark;

  const _MonthlyView({required this.dashboard, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final list = dashboard.monthlyHistory;
    if (list is! List || list.isEmpty) {
      return _EmptyState(isDark: isDark, message: 'Nenhum dado mensal');
    }
    return Column(
      children: [
        for (int i = 0; i < list.length; i++)
          _MonthTile(
            index: i,
            month: list[i]['month']?.toString() ?? '',
            income: (list[i]['income'] is num ? (list[i]['income'] as num).toDouble() : double.tryParse(list[i]['income']?.toString() ?? '') ?? 0),
            expense: (list[i]['expense'] is num ? (list[i]['expense'] as num).toDouble() : double.tryParse(list[i]['expense']?.toString() ?? '') ?? 0),
            balance: (list[i]['balance'] is num ? (list[i]['balance'] as num).toDouble() : double.tryParse(list[i]['balance']?.toString() ?? '') ?? 0),
            isDark: isDark,
          ),
      ],
    );
  }
}

// ---- Shared Widgets ----

class _BalanceHeroCard extends StatelessWidget {
  final dynamic dashboard;
  final bool isDark;

  const _BalanceHeroCard({required this.dashboard, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final balance = (dashboard.balance as num?)?.toDouble() ?? 0;
    final isPositive = balance >= 0;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [const Color(0xFF059669), const Color(0xFF10B981)]
              : [const Color(0xFFDC2626), const Color(0xFFEF4444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                child: Icon(isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: Colors.white, size: 22),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                child: Text(isPositive ? 'POSITIVO' : 'NEGATIVO',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Saldo Atual', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(Formatters.formatCurrency(balance),
            style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _IncomeExpenseRow extends StatelessWidget {
  final dynamic dashboard;
  final bool isDark;

  const _IncomeExpenseRow({required this.dashboard, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final income = (dashboard.totalIncome as num?)?.toDouble() ?? 0;
    final expense = (dashboard.totalExpense as num?)?.toDouble() ?? 0;
    final total = income + expense;
    final incomePct = total > 0 ? income / total : 0.5;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _MiniStat(label: 'Receitas', value: Formatters.formatCurrency(income), color: const Color(0xFF10B981), isDark: isDark)),
              const SizedBox(width: 12),
              Expanded(child: _MiniStat(label: 'Despesas', value: Formatters.formatCurrency(expense), color: const Color(0xFFEF4444), isDark: isDark)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Flexible(flex: (incomePct * 100).round().clamp(1, 99), child: Container(color: const Color(0xFF10B981))),
                  Flexible(flex: ((1 - incomePct) * 100).round().clamp(1, 99), child: Container(color: const Color(0xFFEF4444))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _LegendDot(color: const Color(0xFF10B981), label: 'Receitas', pct: total > 0 ? incomePct : 0, isDark: isDark),
              const Spacer(),
              _LegendDot(color: const Color(0xFFEF4444), label: 'Despesas', pct: total > 0 ? 1 - incomePct : 0, isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _MiniStat({required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final double pct;
  final bool isDark;

  const _LegendDot({required this.color, required this.label, required this.pct, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label ${(pct * 100).round()}%',
          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final String message;

  const _EmptyState({required this.isDark, this.message = 'Nenhum dado mensal ainda'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.bar_chart_rounded, size: 40, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        ],
      ),
    );
  }
}

class _MonthTile extends StatelessWidget {
  final int index;
  final String month;
  final double income;
  final double expense;
  final double balance;
  final bool isDark;

  const _MonthTile({required this.index, required this.month, required this.income, required this.expense, required this.balance, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final maxVal = [income, expense].reduce((a, b) => a > b ? a : b);
    final incomeWidth = maxVal > 0 ? income / maxVal : 0.0;
    final expenseWidth = maxVal > 0 ? expense / maxVal : 0.0;

    return Padding(
      padding: EdgeInsets.only(top: index > 0 ? 8 : 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(month, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkText : AppColors.lightText)),
                ),
                const Spacer(),
                Text(Formatters.formatCurrency(balance),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                    color: balance >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
              ],
            ),
            const SizedBox(height: 12),
            _Bar(label: 'Receitas', width: incomeWidth, color: const Color(0xFF10B981), value: income, isDark: isDark),
            const SizedBox(height: 6),
            _Bar(label: 'Despesas', width: expenseWidth, color: const Color(0xFFEF4444), value: expense, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final double width;
  final Color color;
  final double value;
  final bool isDark;

  const _Bar({required this.label, required this.width, required this.color, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text(label, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary))),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Container(
              height: 12,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: width.clamp(0.01, 1.0),
                child: Container(color: color),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(width: 80, child: Text(Formatters.formatCurrency(value), textAlign: TextAlign.right,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color))),
      ],
    );
  }
}
