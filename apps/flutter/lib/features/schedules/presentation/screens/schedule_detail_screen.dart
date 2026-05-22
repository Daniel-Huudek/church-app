import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScheduleDetailScreen extends StatelessWidget {
  final String id;
  const ScheduleDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC);
    final t1 = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);

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
        title: Text('Escala', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t1)),
      ),
      body: const Center(child: Text('Detalhes da escala - em construção')),
    );
  }
}
