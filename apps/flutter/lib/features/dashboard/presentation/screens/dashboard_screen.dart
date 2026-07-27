import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../events/domain/event_model.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../prayers/presentation/providers/prayer_provider.dart';
import '../../../schedules/presentation/providers/schedule_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await Future.wait([
        ref.read(eventListProvider.notifier).load(),
        ref.read(prayerFeedProvider.notifier).loadFeed(),
        ref.read(scheduleListProvider.notifier).load(),
      ]);
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(eventListProvider.notifier).load(),
      ref.read(prayerFeedProvider.notifier).loadFeed(),
      ref.read(scheduleListProvider.notifier).load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authProvider).user;
    final eventsState = ref.watch(eventListProvider);
    final prayersState = ref.watch(prayerFeedProvider);
    final schedulesState = ref.watch(scheduleListProvider);

    final bg = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC);
    final card = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final t1 = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final t2 = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final border = isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);

    final upcoming = [...(eventsState.data ?? <EventModel>[])]
      ..sort((a, b) => a.date.compareTo(b.date));
    final nextEvents = upcoming.where((e) => !e.date.isBefore(DateTime.now().subtract(const Duration(days: 1)))).take(3).toList();
    final prayerCount = prayersState.data?.length ?? 0;
    final scheduleCount = schedulesState.data?.length ?? 0;

    return Container(
      color: bg,
      child: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFF008CFF),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
          children: [
            Text(
              _greeting(),
              style: TextStyle(fontSize: 14, color: t2),
            ),
            const SizedBox(height: 4),
            Text(
              user?.name.split(' ').first ?? 'Irmão(ã)',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: t1),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _statCard('Orações', '$prayerCount', Icons.favorite_outline, const Color(0xFFEC4899), card, border, t1, t2, () => context.go(AppRoutes.prayers))),
                const SizedBox(width: 12),
                Expanded(child: _statCard('Escalas', '$scheduleCount', Icons.calendar_month_outlined, const Color(0xFF008CFF), card, border, t1, t2, () => context.go(AppRoutes.schedules))),
                const SizedBox(width: 12),
                Expanded(child: _statCard('Eventos', '${nextEvents.length}', Icons.event_outlined, const Color(0xFF10B981), card, border, t1, t2, () => context.go(AppRoutes.calendar))),
              ],
            ),
            const SizedBox(height: 28),
            Text('Atalhos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t1)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _chip('Bíblia', Icons.menu_book_outlined, () => context.go(AppRoutes.bible), card, border, t1),
                _chip('Oração', Icons.volunteer_activism_outlined, () => context.go(AppRoutes.prayers), card, border, t1),
                _chip('Agenda', Icons.event_note_outlined, () => context.go(AppRoutes.calendar), card, border, t1),
                _chip('Chat', Icons.chat_bubble_outline, () => context.go(AppRoutes.chat), card, border, t1),
                if (user != null && user.hasAnyRole(['ADMINISTRADOR', 'PASTOR', 'LIDER_LOUVOR', 'LOUVOR']))
                  _chip('Louvor', Icons.music_note_outlined, () => context.go(AppRoutes.worship), card, border, t1),
                if (user != null && user.hasAnyRole(['ADMINISTRADOR', 'PASTOR', 'FINANCEIRO']))
                  _chip('Finanças', Icons.account_balance_outlined, () => context.go(AppRoutes.finance), card, border, t1),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Text('Próximos eventos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t1)),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go(AppRoutes.calendar),
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (eventsState.loading && (eventsState.data == null || eventsState.data!.isEmpty))
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (nextEvents.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                ),
                child: Text('Nenhum evento próximo.', style: TextStyle(color: t2)),
              )
            else
              ...nextEvents.map((event) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => context.go(AppRoutes.calendarDetail(event.id)),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
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
                                color: const Color(0xFF008CFF).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.event, color: Color(0xFF008CFF)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(event.title, style: TextStyle(fontWeight: FontWeight.w600, color: t1)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_formatDate(event.date)} · ${event.startTime}${event.endTime != null && event.endTime!.isNotEmpty ? ' - ${event.endTime}' : ''}',
                                    style: TextStyle(fontSize: 13, color: t2),
                                  ),
                                ],
                              ),
                            ),
                            Text(_typeLabel(event.type), style: TextStyle(fontSize: 12, color: t2)),
                          ],
                        ),
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia,';
    if (hour < 18) return 'Boa tarde,';
    return 'Boa noite,';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'WORSHIP':
        return 'Culto';
      case 'REHEARSAL':
        return 'Ensaio';
      default:
        return 'Evento';
    }
  }

  Widget _statCard(String label, String value, IconData icon, Color color, Color card, Color border, Color t1, Color t2, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: t1)),
            Text(label, style: TextStyle(fontSize: 12, color: t2)),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, IconData icon, VoidCallback onTap, Color card, Color border, Color t1) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: t1),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: t1, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
