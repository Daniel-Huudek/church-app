import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/offline/offline_guard.dart';
import '../../../../core/utils/calendar_date.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/utils/person_name.dart';
import '../../../../shared/widgets/scale_month_picker.dart';
import '../../../events/domain/event_model.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../members/data/member_api.dart';
import '../../domain/worship_models.dart';
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
  bool _copying = false;
  String? _myMemberId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  Future<void> _copyMonthForWhatsApp() async {
    if (_copying) return;

    final availableDates = _items
        .map((item) => item.event?.date ?? item.worshipEvent.createdAt)
        .toList();

    if (availableDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma escala para copiar')),
      );
      return;
    }

    final selectedMonth = await showScaleMonthPicker(
      context: context,
      dates: availableDates,
    );
    if (selectedMonth == null || !mounted) return;

    final monthItems = _items.where((item) {
      final date = item.event?.date ?? item.worshipEvent.createdAt;
      return date.year == selectedMonth.year && date.month == selectedMonth.month;
    }).toList()
      ..sort((a, b) {
        final aDate = a.event?.date ?? a.worshipEvent.createdAt;
        final bDate = b.event?.date ?? b.worshipEvent.createdAt;
        return aDate.compareTo(bDate);
      });

    if (monthItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma escala neste mês para copiar')),
      );
      return;
    }

    setState(() => _copying = true);
    try {
      final memberApi = MemberApi(ref.read(apiClientProvider));
      final nameCache = <String, String>{};
      final buffer = StringBuffer();
      final monthLabel = _capitalize(
        DateFormat('MMMM/yyyy', 'pt_BR').format(selectedMonth),
      );

      buffer.writeln('*Escala de Louvor — $monthLabel*');
      buffer.writeln();

      for (final item in monthItems) {
        final we = item.worshipEvent;
        final date = item.event?.date ?? we.createdAt;
        final startTime = item.event?.startTime ?? '--:--';
        final title = item.event?.title ?? 'Evento';
        final dayLabel = _capitalize(
          DateFormat("EEEE, dd/MM", 'pt_BR').format(calendarDate(date)),
        );

        buffer.writeln('*$dayLabel — $startTime*');
        buffer.writeln(title);

        final ministerId = we.ministerMemberId;
        if (ministerId != null && ministerId.isNotEmpty) {
          var ministerLabel = nameCache[ministerId];
          if (ministerLabel == null) {
            try {
              final member = await memberApi.getById(ministerId);
              ministerLabel = scaleCopyDisplayName(
                name: member.name,
                nickname: member.nickname,
              );
            } catch (_) {
              ministerLabel = 'Ministro';
            }
            nameCache[ministerId] = ministerLabel!;
          }
          buffer.writeln('Ministro: $ministerLabel');
        }

        final musicians = we.musicians ?? [];
        if (musicians.isEmpty) {
          buffer.writeln('• (sem pessoas escaladas)');
        } else {
          for (final musician in musicians) {
            var label = nameCache[musician.memberId];
            if (label == null) {
              try {
                final member = await memberApi.getById(musician.memberId);
                label = scaleCopyDisplayName(
                  name: member.name,
                  nickname: member.nickname,
                );
              } catch (_) {
                label = 'Músico';
              }
              nameCache[musician.memberId] = label!;
            }
            final role = musician.instrument?.trim().isNotEmpty == true
                ? musician.instrument!
                : (musician.role?.trim().isNotEmpty == true ? musician.role! : 'Louvor');
            buffer.writeln('• $label — $role');
          }
        }
        buffer.writeln();
      }

      await Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Escala de $monthLabel copiada! Cole no WhatsApp')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao copiar: $e')),
      );
    } finally {
      if (mounted) setState(() => _copying = false);
    }
  }

  Future<void> _load() async {
    try {
      final worshipRepo = ref.read(worshipRepositoryProvider);
      final eventRepo = ref.read(eventRepositoryProvider);
      final memberApi = MemberApi(ref.read(apiClientProvider));

      try {
        final me = await memberApi.getMe();
        _myMemberId = me?.id;
      } catch (_) {}

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
    ref.listen<int>(worshipScaleRefreshProvider, (previous, next) {
      if (previous != next) _load();
    });

    final isDark = widget.isDark;
    final scaleTab = widget.scaleTab;
    final currentUser = ref.read(authProvider).user;
    final currentUserId = currentUser?.id;
    final showAll = currentUser?.hasAnyRole(['ADMINISTRADOR', 'PASTOR', 'LIDER', 'LIDER_LOUVOR']) ?? false;

    final filtered = _items.where((item) {
      if (!showAll) {
        final musicians = item.worshipEvent.musicians ?? [];
        if (currentUserId != null && musicians.isNotEmpty) {
          final isMine = musicians.any((m) =>
              m.memberId == currentUserId ||
              (_myMemberId != null && m.memberId == _myMemberId));
          if (!isMine) return false;
        }
      }
      final date = item.event?.date ?? item.worshipEvent.createdAt;
      return scaleTab == 0
          ? isCalendarDateTodayOrFuture(date)
          : isCalendarDateBeforeToday(date);
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
                padding: const EdgeInsets.only(left: 8, right: 4),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Minhas Escalas',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF008CFF)),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copiar escala do mês',
                      onPressed: _loading || _copying ? null : _copyMonthForWhatsApp,
                      icon: _copying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.content_copy_rounded, color: Color(0xFF008CFF)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SegmentedTab(
                isDark: isDark, currentTab: scaleTab, onTabChanged: widget.onTabChanged,
                labels: const ['Próximas', 'Anteriores'],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        color: const Color(0xFF008CFF),
                        onRefresh: _load,
                        child: filtered.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.35,
                                    child: Center(
                                      child: Text(
                                        scaleTab == 0 ? 'Nenhuma escala futura' : 'Nenhuma escala passada',
                                        style: TextStyle(fontSize: 14, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
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
                                  final date = calendarDate(ev?.date ?? we.createdAt);
                                  final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
                                  final day = date.day.toString().padLeft(2, '0');
                                  final month = months[date.month - 1];

                                  return GestureDetector(
                                    onTap: () async {
                                      await context.push('/worship/scale/${we.id}');
                                      if (mounted) _load();
                                    },
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
                  onTap: () async {
                    if (!watchIsOnline(ref)) {
                      showRequiresInternetSnackBar(context);
                      return;
                    }
                    final createdId = await context.push<String>('/worship/scale/create');
                    if (!mounted) return;
                    await _load();
                    if (!mounted) return;
                    if (createdId != null && createdId.isNotEmpty) {
                      await context.push('/worship/scale/$createdId');
                      if (mounted) await _load();
                    }
                  },
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
