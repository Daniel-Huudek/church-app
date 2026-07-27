import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../events/data/event_api.dart';
import '../../../members/data/member_api.dart';
import '../../../schedules/data/schedule_api.dart';
import '../../../schedules/domain/schedule_model.dart';

class DeaconScaleDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const DeaconScaleDetailScreen({super.key, required this.id});

  @override
  ConsumerState<DeaconScaleDetailScreen> createState() => _DeaconScaleDetailScreenState();
}

class _DeaconScaleDetailScreenState extends ConsumerState<DeaconScaleDetailScreen> {
  bool _loading = true;
  String? _error;
  ScheduleModel? _schedule;
  String _title = 'Escala de Diáconos';
  Map<String, String> _memberNames = {};
  Map<String, String?> _memberUserIds = {};

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
      final scheduleApi = ScheduleApi(ref.read(apiClientProvider));
      final eventApi = EventApi(ref.read(apiClientProvider));
      final memberApi = MemberApi(ref.read(apiClientProvider));

      final schedule = await scheduleApi.getById(widget.id);
      var title = schedule.eventName ?? 'Escala de Diáconos';
      if (schedule.eventId != null) {
        try {
          final event = await eventApi.getById(schedule.eventId!);
          title = event.title;
        } catch (_) {}
      }

      final names = <String, String>{};
      final userIds = <String, String?>{};
      for (final position in schedule.positionDetails) {
        final memberId = position.memberId;
        if (memberId == null) continue;
        try {
          final member = await memberApi.getById(memberId);
          names[memberId] = member.name;
          userIds[memberId] = member.userId;
        } catch (_) {
          names[memberId] = position.memberName ?? 'Membro';
        }
      }

      if (!mounted) return;
      setState(() {
        _schedule = schedule;
        _title = title;
        _memberNames = names;
        _memberUserIds = userIds;
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

  Future<void> _confirm(SchedulePosition position, bool confirmed) async {
    try {
      final scheduleApi = ScheduleApi(ref.read(apiClientProvider));
      await scheduleApi.confirmPresence(_schedule!.id, position.id, confirmed: confirmed);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authProvider).user;
    final bg = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC);
    final card = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final t1 = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final t2 = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final border = isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);

    if (_loading) {
      return Scaffold(backgroundColor: bg, body: const Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _schedule == null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(backgroundColor: bg, elevation: 0, leading: BackButton(color: t1)),
        body: Center(child: Text(_error ?? 'Escala não encontrada', style: TextStyle(color: t2))),
      );
    }

    final schedule = _schedule!;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back, color: t1),
        ),
        title: Text('Detalhe da escala', style: TextStyle(color: t1, fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat("EEEE, dd 'de' MMMM", 'pt_BR').format(schedule.date),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                  ),
                  const SizedBox(height: 4),
                  Text('${schedule.startTime} - ${schedule.endTime}', style: TextStyle(color: Colors.white.withValues(alpha: 0.9))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Funções', style: TextStyle(color: t1, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (schedule.positionDetails.isEmpty)
              Text('Nenhuma função atribuída.', style: TextStyle(color: t2))
            else
              ...schedule.positionDetails.map((position) {
                final name = _memberNames[position.memberId] ?? position.memberName ?? 'Membro';
                final linkedUserId = _memberUserIds[position.memberId];
                final isMine = user != null &&
                    (position.memberId == user.id || linkedUserId == user.id);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(position.position, style: TextStyle(color: t1, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(name, style: TextStyle(color: t2)),
                      const SizedBox(height: 8),
                      Text(
                        position.isConfirmed
                            ? 'Confirmado'
                            : position.isSubstituted
                                ? 'Indisponível'
                                : 'Pendente',
                        style: TextStyle(
                          color: position.isConfirmed
                              ? const Color(0xFF10B981)
                              : position.isSubstituted
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFFF59E0B),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      if (isMine || (user?.hasAnyRole(['ADMINISTRADOR', 'PASTOR', 'LIDER_DIACONOS']) ?? false)) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => _confirm(position, true),
                              child: Text(isMine ? 'Confirmar presença' : 'Confirmar'),
                            ),
                            TextButton(
                              onPressed: () => _confirm(position, false),
                              child: Text(isMine ? 'Indisponível' : 'Cancelar'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
