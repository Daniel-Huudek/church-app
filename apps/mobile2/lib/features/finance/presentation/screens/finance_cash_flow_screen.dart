import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FinanceCashFlowScreen extends StatelessWidget {
  const FinanceCashFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC);
    final card = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final t1 = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final t2 = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final border = isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);

    final months = [
      ('Janeiro', 'R\$ 8.500,00', 'R\$ 6.200,00'),
      ('Fevereiro', 'R\$ 7.800,00', 'R\$ 5.900,00'),
      ('Março', 'R\$ 9.200,00', 'R\$ 7.100,00'),
      ('Abril', 'R\$ 7.500,00', 'R\$ 6.800,00'),
      ('Maio', 'R\$ 8.100,00', 'R\$ 5.500,00'),
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
        title: Text('Fluxo de Caixa',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t1)),
      ),
      body: Column(
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
                const Text('R\$ 8.100,00',
                    style: TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _stat('Receitas', 'R\$ 41.100,00', Colors.greenAccent),
                    const SizedBox(width: 24),
                    _stat('Despesas', 'R\$ 31.500,00', Colors.redAccent),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: months.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final m = months[i];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(m.$1,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t1)),
                      ),
                      Text(m.$2,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF10B981))),
                      const SizedBox(width: 16),
                      Text(m.$3,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
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
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: accent)),
      ],
    );
  }
}
