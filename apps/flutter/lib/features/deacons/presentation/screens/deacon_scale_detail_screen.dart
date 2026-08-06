import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/offline/offline_guard.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/calendar_date.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../members/presentation/providers/member_provider.dart';
import '../../../schedules/domain/schedule_model.dart';
import '../../../schedules/presentation/providers/schedule_provider.dart';
import '../widgets/deacon_scale_print_card.dart';
import 'deacon_scale_print_preview_screen.dart';

const _sky = Color(0xFF0EA5E9);
const _skyDark = Color(0xFF0284C7);
const _success = Color(0xFF10B981);
const _warning = Color(0xFFF59E0B);
const _errorColor = Color(0xFFEF4444);

class DeaconScaleDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const DeaconScaleDetailScreen({super.key, required this.id});

  @override
  ConsumerState<DeaconScaleDetailScreen> createState() =>
      _DeaconScaleDetailScreenState();
}

class _DeaconScaleDetailScreenState
    extends ConsumerState<DeaconScaleDetailScreen> {
  bool _loading = true;
  String? _error;
  ScheduleModel? _schedule;
  String _title = 'Escala de Diáconos';
  Map<String, String> _memberNames = {};
  Map<String, String?> _memberUserIds = {};
  Map<String, String?> _memberEmails = {};
  String? _selectedPositionId;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = _schedule == null;
      _error = null;
    });
    try {
      final scheduleRepo = ref.read(scheduleRepositoryProvider);
      final eventRepo = ref.read(eventRepositoryProvider);
      final memberRepo = ref.read(memberRepositoryProvider);

      final cached = scheduleRepo.peekDetailCache(widget.id);
      if (cached != null && mounted) {
        setState(() {
          _schedule = cached;
          _title = cached.eventName ?? _title;
          _loading = false;
        });
      }

      final schedule = (await scheduleRepo.getById(widget.id)).data;
      var title = schedule.eventName ?? 'Escala de Diáconos';
      if (schedule.eventId != null) {
        try {
          final event = (await eventRepo.getById(schedule.eventId!)).data;
          title = event.title;
        } catch (_) {}
      }

      final names = <String, String>{};
      final userIds = <String, String?>{};
      final emails = <String, String?>{};
      for (final position in schedule.positionDetails) {
        final memberId = position.memberId;
        if (memberId == null) continue;
        try {
          final member = (await memberRepo.getById(memberId)).data;
          names[memberId] = member.name;
          userIds[memberId] = member.userId;
          emails[memberId] = member.email;
        } catch (_) {
          names[memberId] = position.memberName ?? 'Membro';
        }
      }

      if (!mounted) return;

      final user = ref.read(authProvider).user;
      SchedulePosition? mine;
      for (final p in schedule.positionDetails) {
        if (_isMine(p, user)) {
          mine = p;
          break;
        }
      }
      final keepSelection =
          schedule.positionDetails.any((p) => p.id == _selectedPositionId);

      setState(() {
        _schedule = schedule;
        _title = title;
        _memberNames = names;
        _memberUserIds = userIds;
        _memberEmails = emails;
        _loading = false;
        if (!keepSelection) {
          _selectedPositionId = mine?.id;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_schedule == null) _error = e.toString();
      });
    }
  }

  bool _isMine(SchedulePosition position, UserModel? user) {
    if (user == null) return false;
    final linkedUserId = _memberUserIds[position.memberId];
    final memberEmail = _memberEmails[position.memberId]?.trim().toLowerCase();
    final userEmail = user.email.trim().toLowerCase();
    return position.memberId == user.id ||
        linkedUserId == user.id ||
        (userEmail.isNotEmpty &&
            memberEmail != null &&
            memberEmail == userEmail);
  }

  Future<void> _confirm(SchedulePosition position, bool confirmed) async {
    try {
      final outcome = await ref.read(scheduleRepositoryProvider).confirmPresence(
            _schedule!.id,
            position.id,
            confirmed: confirmed,
          );
      await _load();
      if (!mounted) return;
      if (outcome.queued) {
        notifyMutationQueueChanged(ref);
        showQueuedSyncSnackBar(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  Future<void> _deleteScale() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir escala'),
        content: const Text(
          'Tem certeza que deseja excluir esta escala de diáconos? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      await ref.read(scheduleRepositoryProvider).delete(widget.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escala excluída')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir: $e')),
      );
    }
  }

  Color _statusColor(SchedulePosition position) {
    if (position.isConfirmed) return _success;
    if (position.isSubstituted) return _errorColor;
    return _warning;
  }

  String _statusLabel(SchedulePosition position) {
    if (position.isConfirmed) return 'Confirmado';
    if (position.isSubstituted) return 'Indisponível';
    return 'Pendente';
  }

  String _initials(String name) {
    final parts = name
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0])
        .join()
        .toUpperCase();
    return parts.isEmpty ? '?' : parts;
  }

  SchedulePosition? _findById(ScheduleModel schedule, String? id) {
    if (id == null) return null;
    for (final p in schedule.positionDetails) {
      if (p.id == id) return p;
    }
    return null;
  }

  SchedulePosition? _findMine(ScheduleModel schedule, UserModel? user) {
    for (final p in schedule.positionDetails) {
      if (_isMine(p, user)) return p;
    }
    return null;
  }

  DeaconScalePrintCardData _buildPrintData(ScheduleModel schedule) {
    return DeaconScalePrintCardData.fromPositions(
      date: schedule.date,
      eventTitle: _title,
      startTime: schedule.startTime,
      endTime: schedule.endTime,
      positions: schedule.positionDetails
          .map(
            (p) => (
              position: p.position,
              name: _memberNames[p.memberId] ?? p.memberName ?? 'Membro',
            ),
          )
          .toList(),
    );
  }

  Future<void> _openPrintCard() async {
    final schedule = _schedule;
    if (schedule == null) return;
    await openDeaconScalePrintPreview(
      context: context,
      data: _buildPrintData(schedule),
    );
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
    final canManage =
        user?.hasAnyRole(['ADMINISTRADOR', 'PASTOR', 'LIDER_DIACONOS']) ?? false;

    if (_loading && _schedule == null) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _schedule == null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          leading: BackButton(color: t1),
        ),
        body: Center(
          child: Text(
            _error ?? 'Escala não encontrada',
            style: TextStyle(color: t2),
          ),
        ),
      );
    }

    final schedule = _schedule!;
    final confirmedCount =
        schedule.positionDetails.where((p) => p.isConfirmed).length;
    final totalCount = schedule.positionDetails.length;
    final mine = _findMine(schedule, user);
    final selected = _findById(schedule, _selectedPositionId) ?? mine;
    final showActions = selected != null &&
        (_isMine(selected, user) || canManage);
    final selectedIsMine = selected != null && _isMine(selected, user);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: t1, size: 20),
        ),
        title: Text(
          'Escala',
          style: TextStyle(color: t1, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 8, right: 4),
            decoration: BoxDecoration(
              color: _sky.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              tooltip: 'Card para print',
              icon: const Icon(Icons.grid_on_rounded, color: _sky, size: 22),
              onPressed: _openPrintCard,
            ),
          ),
          if (canManage) ...[
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8, right: 4),
              decoration: BoxDecoration(
                color: _sky.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                tooltip: 'Editar escala',
                onPressed: () async {
                  await context.push(AppRoutes.deaconEdit(widget.id));
                  if (mounted) _load();
                },
                icon: const Icon(Icons.edit_outlined, color: _sky, size: 22),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8, right: 8),
              decoration: BoxDecoration(
                color: _errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                tooltip: 'Excluir escala',
                onPressed: _deleteScale,
                icon: const Icon(
                  Icons.delete_outline,
                  color: _errorColor,
                  size: 22,
                ),
              ),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: _sky,
              onRefresh: _load,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  showActions ? 16 : 28,
                ),
                children: [
                  _SummaryBanner(
                    title: _title,
                    date: schedule.date,
                    startTime: schedule.startTime,
                    endTime: schedule.endTime,
                    confirmed: confirmedCount,
                    total: totalCount,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Equipe',
                    style: TextStyle(
                      color: t1,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (schedule.positionDetails.isEmpty)
                    Text(
                      'Nenhuma função atribuída.',
                      style: TextStyle(color: t2),
                    )
                  else
                    _EquipeList(
                      positions: schedule.positionDetails,
                      memberNames: _memberNames,
                      selectedId: selected?.id,
                      canSelect: canManage || mine != null,
                      card: card,
                      border: border,
                      t1: t1,
                      t2: t2,
                      isDark: isDark,
                      statusColor: _statusColor,
                      statusLabel: _statusLabel,
                      initials: _initials,
                      onSelect: (id) {
                        if (!canManage && mine?.id != id) return;
                        setState(() => _selectedPositionId = id);
                      },
                    ),
                ],
              ),
            ),
          ),
          if (showActions && selected != null)
            _BottomActionPanel(
              positionLabel: selected.position,
              isMine: selectedIsMine,
              isDark: isDark,
              onConfirm: () => _confirm(selected, true),
              onUnavailable: () => _confirm(selected, false),
            ),
        ],
      ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  final String title;
  final DateTime date;
  final String startTime;
  final String endTime;
  final int confirmed;
  final int total;
  final bool isDark;

  const _SummaryBanner({
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.confirmed,
    required this.total,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat("dd 'de' MMMM 'de' yyyy (EEEE)", 'pt_BR')
        .format(calendarDate(date));
    final progress = total == 0 ? 0.0 : confirmed / total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0C4A6E), Color(0xFF082F49)]
              : const [Color(0xFF38BDF8), _sky, _skyDark],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 15,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dateLabel,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$startTime – $endTime',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 58,
            height: 58,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 58,
                  height: 58,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                Text(
                  '$confirmed/$total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EquipeList extends StatelessWidget {
  final List<SchedulePosition> positions;
  final Map<String, String> memberNames;
  final String? selectedId;
  final bool canSelect;
  final Color card;
  final Color border;
  final Color t1;
  final Color t2;
  final bool isDark;
  final Color Function(SchedulePosition) statusColor;
  final String Function(SchedulePosition) statusLabel;
  final String Function(String) initials;
  final ValueChanged<String> onSelect;

  const _EquipeList({
    required this.positions,
    required this.memberNames,
    required this.selectedId,
    required this.canSelect,
    required this.card,
    required this.border,
    required this.t1,
    required this.t2,
    required this.isDark,
    required this.statusColor,
    required this.statusLabel,
    required this.initials,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < positions.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: border, indent: 68),
            _EquipeRow(
              position: positions[i],
              memberName: memberNames[positions[i].memberId] ??
                  positions[i].memberName ??
                  'Membro',
              selected: positions[i].id == selectedId,
              canSelect: canSelect,
              t1: t1,
              t2: t2,
              isDark: isDark,
              statusColor: statusColor(positions[i]),
              statusLabel: statusLabel(positions[i]),
              initials: initials(
                memberNames[positions[i].memberId] ??
                    positions[i].memberName ??
                    'Membro',
              ),
              onTap: () => onSelect(positions[i].id),
            ),
          ],
        ],
      ),
    );
  }
}

class _EquipeRow extends StatelessWidget {
  final SchedulePosition position;
  final String memberName;
  final bool selected;
  final bool canSelect;
  final Color t1;
  final Color t2;
  final bool isDark;
  final Color statusColor;
  final String statusLabel;
  final String initials;
  final VoidCallback onTap;

  const _EquipeRow({
    required this.position,
    required this.memberName,
    required this.selected,
    required this.canSelect,
    required this.t1,
    required this.t2,
    required this.isDark,
    required this.statusColor,
    required this.statusLabel,
    required this.initials,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? _sky.withValues(alpha: isDark ? 0.12 : 0.06)
          : Colors.transparent,
      child: InkWell(
        onTap: canSelect ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _sky.withValues(alpha: isDark ? 0.22 : 0.12),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF7DD3FC) : _skyDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      position.position,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: t2,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      memberName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: t1,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomActionPanel extends StatelessWidget {
  final String positionLabel;
  final bool isMine;
  final bool isDark;
  final VoidCallback onConfirm;
  final VoidCallback onUnavailable;

  const _BottomActionPanel({
    required this.positionLabel,
    required this.isMine,
    required this.isDark,
    required this.onConfirm,
    required this.onUnavailable,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPad),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF122033)
            : const Color(0xFFEAF6FE),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFD7ECFA),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 18,
                color: isDark ? const Color(0xFF7DD3FC) : _skyDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(
                      color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF334155),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(
                        text: isMine ? 'Sua função: ' : 'Função selecionada: ',
                      ),
                      TextSpan(
                        text: positionLabel,
                        style: TextStyle(
                          color: isDark ? const Color(0xFF7DD3FC) : _skyDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onConfirm,
            style: FilledButton.styleFrom(
              backgroundColor: _sky,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isMine ? 'Confirmar presença' : 'Confirmar',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: onUnavailable,
            style: TextButton.styleFrom(
              foregroundColor: isDark ? const Color(0xFF7DD3FC) : _skyDark,
            ),
            child: const Text(
              'Marcar indisponível',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
