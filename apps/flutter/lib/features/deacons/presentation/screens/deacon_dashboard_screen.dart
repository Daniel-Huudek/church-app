import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/offline/offline_guard.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../events/data/event_api.dart';
import '../../../members/data/member_api.dart';
import '../../../schedules/data/schedule_api.dart';
import '../../../schedules/domain/schedule_model.dart';
import '../../data/deacon_ministry_helper.dart';

class DeaconDashboardScreen extends ConsumerStatefulWidget {
  const DeaconDashboardScreen({super.key});

  @override
  ConsumerState<DeaconDashboardScreen> createState() => _DeaconDashboardScreenState();
}

class _DeaconDashboardScreenState extends ConsumerState<DeaconDashboardScreen> {
  int _tab = 0;
  bool _loading = true;
  bool _copying = false;
  String? _error;
  String? _ministryId;
  List<_DeaconScaleItem> _items = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final memberApi = MemberApi(ref.read(apiClientProvider));
      final scheduleApi = ScheduleApi(ref.read(apiClientProvider));
      final eventApi = EventApi(ref.read(apiClientProvider));

      final ministry = await DeaconMinistryHelper.ensureMinistry(memberApi);
      final schedules = await scheduleApi.list(ministryId: ministry.id);

      final enriched = <_DeaconScaleItem>[];
      for (final schedule in schedules) {
        String title = schedule.eventName ?? 'Escala de Diáconos';
        if (schedule.eventId != null) {
          try {
            final event = await eventApi.getById(schedule.eventId!);
            title = event.title;
          } catch (_) {}
        }
        enriched.add(_DeaconScaleItem(schedule: schedule, title: title));
      }

      if (!mounted) return;
      setState(() {
        _ministryId = ministry.id;
        _items = enriched;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  Future<void> _copyMonthForWhatsApp() async {
    if (_copying) return;
    final now = DateTime.now();
    final monthItems = _items.where((item) {
      final date = item.schedule.date;
      return date.year == now.year && date.month == now.month;
    }).toList()
      ..sort((a, b) => a.schedule.date.compareTo(b.schedule.date));

    if (monthItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma escala neste mês para copiar')),
      );
      return;
    }

    setState(() => _copying = true);
    try {
      final memberApi = MemberApi(ref.read(apiClientProvider));
      final scheduleApi = ScheduleApi(ref.read(apiClientProvider));
      final nameCache = <String, String>{};
      final buffer = StringBuffer();
      final monthLabel = _capitalize(DateFormat('MMMM/yyyy', 'pt_BR').format(now));

      buffer.writeln('*Escala de Diáconos — $monthLabel*');
      buffer.writeln();

      for (final item in monthItems) {
        ScheduleModel schedule = item.schedule;
        try {
          schedule = await scheduleApi.getById(item.schedule.id);
        } catch (_) {}

        final dayLabel = _capitalize(
          DateFormat("EEEE, dd/MM", 'pt_BR').format(schedule.date),
        );
        buffer.writeln('*$dayLabel — ${schedule.startTime}*');
        if (item.title.trim().isNotEmpty) {
          buffer.writeln(item.title.trim());
        }

        if (schedule.positionDetails.isEmpty) {
          buffer.writeln('• (sem funções atribuídas)');
        } else {
          for (final position in schedule.positionDetails) {
            final memberId = position.memberId;
            var name = position.memberName?.trim();
            if ((name == null || name.isEmpty) && memberId != null) {
              if (nameCache.containsKey(memberId)) {
                name = nameCache[memberId];
              } else {
                try {
                  final member = await memberApi.getById(memberId);
                  name = member.name;
                  nameCache[memberId] = member.name;
                } catch (_) {
                  name = 'Membro';
                  nameCache[memberId] = name!;
                }
              }
            }
            name ??= 'Membro';
            buffer.writeln('• $name — ${position.position}');
          }
        }
        buffer.writeln();
      }

      await Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escala do mês copiada! Cole no WhatsApp')),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authProvider).user;
    final canCreate = user != null &&
        user.hasAnyRole(['ADMINISTRADOR', 'PASTOR', 'LIDER_DIACONOS']);

    final bg = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC);
    final card = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final t1 = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final t2 = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final border = isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);

    final today = DateTime.now();
    final filtered = _items.where((item) {
      final date = item.schedule.date;
      return _tab == 0
          ? !date.isBefore(DateTime(today.year, today.month, today.day))
          : date.isBefore(DateTime(today.year, today.month, today.day));
    }).toList()
      ..sort((a, b) => _tab == 0
          ? a.schedule.date.compareTo(b.schedule.date)
          : b.schedule.date.compareTo(a.schedule.date));

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.home),
                    child: const Text('←', style: TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Escala de Diáconos',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: t1),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copiar mês para WhatsApp',
                    onPressed: _loading || _copying ? null : _copyMonthForWhatsApp,
                    icon: _copying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.content_copy_rounded, color: Color(0xFF008CFF)),
                  ),
                  if (canCreate)
                    Opacity(
                      opacity: watchIsOnline(ref) ? 1 : 0.45,
                      child: IconButton(
                        onPressed: guardOnlineAction(context, ref, () async {
                          await context.push(AppRoutes.deaconsCreate);
                          _load();
                        }),
                        icon: const Icon(Icons.add_circle, color: Color(0xFF008CFF)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _tabChip('Próximas', 0, t1, t2, border),
                  const SizedBox(width: 8),
                  _tabChip('Passadas', 1, t1, t2, border),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text('Erro: $_error', style: TextStyle(color: t2)))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: filtered.isEmpty
                              ? ListView(
                                  children: [
                                    const SizedBox(height: 80),
                                    Center(
                                      child: Text(
                                        _tab == 0 ? 'Nenhuma escala futura' : 'Nenhuma escala passada',
                                        style: TextStyle(color: t2),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final item = filtered[index];
                                    final schedule = item.schedule;
                                    return InkWell(
                                      onTap: () async {
                                        await context.push(AppRoutes.deaconDetail(schedule.id));
                                        _load();
                                      },
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: card,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: border),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item.title,
                                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t1)),
                                            const SizedBox(height: 6),
                                            Text(
                                              DateFormat("EEEE, dd/MM/yyyy", 'pt_BR').format(schedule.date),
                                              style: TextStyle(color: t2, fontSize: 13),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${schedule.startTime} - ${schedule.endTime}',
                                              style: TextStyle(color: t2, fontSize: 13),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              '${schedule.confirmed}/${schedule.positions} confirmados',
                                              style: const TextStyle(color: Color(0xFF008CFF), fontSize: 12, fontWeight: FontWeight.w600),
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
      floatingActionButton: canCreate
          ? Opacity(
              opacity: watchIsOnline(ref) ? 1 : 0.45,
              child: FloatingActionButton.extended(
                onPressed: guardOnlineAction(context, ref, () async {
                  await context.push(
                    AppRoutes.deaconsCreate,
                    extra: _ministryId,
                  );
                  _load();
                }),
                backgroundColor: const Color(0xFF008CFF),
                icon: const Icon(Icons.add),
                label: const Text('Nova escala'),
              ),
            )
          : null,
    );
  }

  Widget _tabChip(String label, int value, Color t1, Color t2, Color border) {
    final selected = _tab == value;
    return GestureDetector(
      onTap: () => setState(() => _tab = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF008CFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? const Color(0xFF008CFF) : border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : t2,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _DeaconScaleItem {
  final ScheduleModel schedule;
  final String title;
  const _DeaconScaleItem({required this.schedule, required this.title});
}
