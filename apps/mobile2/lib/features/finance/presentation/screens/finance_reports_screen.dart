import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FinanceReportsScreen extends StatelessWidget {
  const FinanceReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC);
    final card = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final t1 = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final t2 = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final border = isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);

    final reports = [
      ('Receitas Mensais', '📊'),
      ('Despesas Mensais', '📉'),
      ('Balanço Anual', '📋'),
      ('Dízimos', '💰'),
      ('Ofertas', '🙏'),
    ];

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
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: reports.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          return Container(
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
          );
        },
      ),
    );
  }
}
