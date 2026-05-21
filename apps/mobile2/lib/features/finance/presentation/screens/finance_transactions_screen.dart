import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FinanceTransactionsScreen extends StatelessWidget {
  const FinanceTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC);
    final card = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final t1 = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final t2 = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final border = isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);

    final transactions = [
      ('10/05', 'Dízimo', 'R\$ 150,00', true),
      ('12/05', 'Oferta', 'R\$ 75,00', true),
      ('15/05', 'Luz', 'R\$ 200,00', false),
      ('18/05', 'Dízimo', 'R\$ 300,00', true),
      ('20/05', 'Água', 'R\$ 120,00', false),
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
        title: Text('Transações',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t1)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: transactions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final t = transactions[i];
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
                    color: (t.$4 ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(t.$4 ? '💰' : '💳',
                        style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.$2,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t1)),
                      const SizedBox(height: 4),
                      Text(t.$1,
                          style: TextStyle(fontSize: 13, color: t2)),
                    ],
                  ),
                ),
                Text(t.$3,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: t.$4 ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
              ],
            ),
          );
        },
      ),
    );
  }
}
