import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/offline/offline_guard.dart';
import '../../../../../shared/providers/auth_provider.dart';
import '../../domain/worship_models.dart';
import '../../../events/domain/event_model.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../providers/worship_provider.dart';
import 'segmented_tab.dart';

class ScaleCardData {
  final WorshipEvent worshipEvent;
  final EventModel? event;
  ScaleCardData({required this.worshipEvent, this.event});
}

class ScalePage extends ConsumerStatefulWidget {
  final bool isDark;
  final int scaleTab;
  final ValueChanged<int> onTabChanged;
  final bool canCreate;

  const ScalePage({
    super.key,
    required this.isDark,
    required this.scaleTab,
    required this.onTabChanged,
    required this.canCreate,
  });

  @override
  ConsumerState<ScalePage> createState() => _ScalePageState();
}

class _ScalePageState extends ConsumerState<ScalePage> {
  List<ScaleCardData> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final worshipRepo = ref.read(worshipRepositoryProvider);
      final eventRepo = ref.read(eventRepositoryProvider);

      final cachedEvents = worshipRepo.peekWorshipEventsCache();
      if (cachedEvents != null && cachedEvents.isNotEmpty && mounted) {
        final cachedItems = <ScaleCardData>[];
        for (final we in cachedEvents) {
          final eventModel = eventRepo.peekDetailCache(we.eventId);
          cachedItems.add(ScaleCardData(worshipEvent: we, event: eventModel));
        }
        setState(() {
          _items = cachedItems;
          _loading = false;
        });
      }

      final result = await worshipRepo.listWorshipEvents(limit: 50);
      final items = <ScaleCardData>[];
      for (final we in result.data) {
        EventModel? eventModel;
        try {
          eventModel = (await eventRepo.getById(we.eventId)).data;
        } catch (_) {
          eventModel = eventRepo.peekDetailCache(we.eventId);
        }
        items.add(ScaleCardData(worshipEvent: we, event: eventModel));
      }
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted && _items.isEmpty) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final scaleTab = widget.scaleTab;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentUser = ref.read(authProvider).user;
    final currentUserId = currentUser?.id;
    final showAll = currentUser?.hasAnyRole(['ADMINISTRADOR', 'PASTOR', 'LIDER', 'LIDER_LOUVOR']) ?? false;

    final filtered = _items.where((item) {
      if (!showAll) {
        final musicians = item.worshipEvent.musicians ?? [];
        if (currentUserId != null && musicians.isNotEmpty && !musicians.any((m) => m.memberId == currentUserId)) return false;
      }
      final date = item.event?.date ?? item.worshipEvent.createdAt;
      final eventDate = DateTime(date.year, date.month, date.day);
      return scaleTab == 0 ? eventDate.isAfter(today.subtract(const Duration(days: 1))) : eventDate.isBefore(today);
    }).toList()
      ..sort((a, b) {
        final aDate = a.event?.date ?? a.worshipEvent.createdAt;
        final bDate = b.event?.date ?? b.worshipEvent.createdAt;
        return scaleTab == 0 ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
      });

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text('Minhas Escalas',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: const Color(0xFF008CFF))),
              ),
              const SizedBox(height: 20),
              SegmentedTab(
                isDark: isDark, currentTab: scaleTab, onTabChanged: widget.onTabChanged,
                labels: const ['Próximas', 'Anteriores'],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? Center(
                            child: Text(
                              scaleTab == 0 ? 'Nenhuma escala futura' : 'Nenhuma escala passada',
                              style: TextStyle(fontSize: 14, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 14),
                            itemBuilder: (_, i) {
                              final item = filtered[i];
                              final we = item.worshipEvent;
                              final ev = item.event;
                              final songs = we.songs ?? [];
                              final musicians = we.musicians ?? [];
                              final startTime = ev?.startTime ?? '--:--';
                              final confirmedCount = musicians.where((m) => m.isConfirmed).length;
                              final title = ev?.title ?? 'Evento';
                              final date = ev?.date ?? we.createdAt;
                              final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
                              final day = date.day.toString().padLeft(2, '0');
                              final month = months[date.month - 1];

                              return GestureDetector(
                                onTap: () => context.push('/worship/scale/${we.id}'),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF008CFF),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF008CFF), width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF008CFF).withValues(alpha: 0.3),
                                        blurRadius: 12, offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 48, height: 48,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 24),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(title,
                                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.schedule_rounded, size: 14, color: Colors.white70),
                                                    const SizedBox(width: 4),
                                                    Text(startTime, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Column(
                                              children: [
                                                Text(day,
                                                  style: const TextStyle(color: Color(0xFF008CFF), fontSize: 18, fontWeight: FontWeight.w800)),
                                                Text(month,
                                                  style: const TextStyle(color: Color(0xFF008CFF), fontSize: 10, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        child: Divider(height: 1, color: Colors.white.withValues(alpha: 0.2)),
                                      ),
                                      Row(
                                        children: [
                                          _statBadge(Icons.music_note_rounded, '${songs.length} músicas', isDark),
                                          const SizedBox(width: 10),
                                          _statBadge(Icons.people_rounded, '$confirmedCount/${musicians.length} pessoas', isDark),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
        if (widget.canCreate)
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20, bottom: 20),
              child: Opacity(
                opacity: watchIsOnline(ref) ? 1 : 0.45,
                child: GestureDetector(
                  onTap: guardOnlineAction(context, ref, () async {
                    await context.push('/worship/scale/create');
                    _load();
                  }),
                  child: Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF008CFF),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _statBadge(IconData icon, String label, bool isDark, {Color? color}) {
    final c = color ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c)),
        ],
      ),
    );
  }
}
