import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/schedule_provider.dart';

class ScheduleDetailScreen extends ConsumerWidget {
  final String id;
  const ScheduleDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC);
    final card = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final t1 = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final t2 = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final border = isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);
    final state = ref.watch(scheduleDetailProvider(id));

    if (state.loading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(child: Text('Erro: ${state.error}')),
      );
    }

    final schedule = state.schedule!;

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
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
                  Text(schedule.eventName ?? 'Escala',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(
                    '${DateFormat("EEEE, dd 'de' MMMM 'de' yyyy", 'pt_BR').format(schedule.date)}',
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
                  ),
                  const SizedBox(height: 4),
                  Text('${schedule.startTime} - ${schedule.endTime}',
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9))),
                  const SizedBox(height: 12),
                  if (schedule.ministryName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(schedule.ministryName!,
                          style: const TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Detalhes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t1)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Column(
                children: [
                  _detailRow('Status', schedule.status, t1, t2),
                  const Divider(),
                  _detailRow('Posições', '${schedule.positions}', t1, t2),
                  const Divider(),
                  _detailRow('Confirmados', '${schedule.confirmed}', t1, t2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, Color t1, Color t2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: t2)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t1)),
        ],
      ),
    );
  }
}
