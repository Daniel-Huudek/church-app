import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/offline/offline_guard.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../members/presentation/providers/member_provider.dart';
import '../../../schedules/domain/schedule_model.dart';
import '../../../schedules/presentation/providers/schedule_provider.dart';

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
          _selectedPositionId ??= cached.positionDetails.isNotEmpty
              ? cached.positionDetails.first.id
              : null;
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
          _selectedPositionId = mine?.id ??
              (schedule.positionDetails.isNotEmpty
                  ? schedule.positionDetails.first.id
                  : null);
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

  SchedulePosition? _findSelected(ScheduleModel schedule) {
    for (final p in schedule.positionDetails) {
      if (p.id == _selectedPositionId) return p;
    }
    return schedule.positionDetails.isNotEmpty
        ? schedule.positionDetails.first
        : null;
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
    final selected = _findSelected(schedule);
    final canActOnSelected =
        selected != null && (_isMine(selected, user) || canManage);

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        color: _sky,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _DateHero(
                title: _title,
                date: schedule.date,
                startTime: schedule.startTime,
                endTime: schedule.endTime,
                isDark: isDark,
                canManage: canManage,
                onBack: () => context.pop(),
                onEdit: () async {
                  await context.push(AppRoutes.deaconEdit(widget.id));
                  if (mounted) _load();
                },
                onDelete: _deleteScale,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    'Postos',
                    style: TextStyle(
                      color: t1,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (schedule.positionDetails.isEmpty)
                    Text(
                      'Nenhuma função atribuída.',
                      style: TextStyle(color: t2),
                    )
                  else
                    _PostosGrid(
                      positions: schedule.positionDetails,
                      memberNames: _memberNames,
                      selectedId: selected?.id,
                      card: card,
                      border: border,
                      t1: t1,
                      t2: t2,
                      isDark: isDark,
                      statusColor: _statusColor,
                      statusLabel: _statusLabel,
                      initials: _initials,
                      onSelect: (id) => setState(() => _selectedPositionId = id),
                    ),
                  if (selected != null && canActOnSelected) ...[
                    const SizedBox(height: 22),
                    _ActionStrip(
                      position: selected,
                      memberName: _memberNames[selected.memberId] ??
                          selected.memberName ??
                          'Membro',
                      isMine: _isMine(selected, user),
                      t1: t1,
                      t2: t2,
                      card: card,
                      border: border,
                      onConfirm: () => _confirm(selected, true),
                      onUnavailable: () => _confirm(selected, false),
                    ),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateHero extends StatelessWidget {
  final String title;
  final DateTime date;
  final String startTime;
  final String endTime;
  final bool isDark;
  final bool canManage;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DateHero({
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isDark,
    required this.canManage,
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final day = DateFormat('d', 'pt_BR').format(date);
    final month = DateFormat('MMM', 'pt_BR')
        .format(date)
        .toUpperCase()
        .replaceAll('.', '');
    final weekday = DateFormat('EEEE', 'pt_BR').format(date);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPad + 8, 12, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0C4A6E), Color(0xFF082F49)]
              : const [
                  Color(0xFF38BDF8),
                  Color(0xFF0EA5E9),
                  Color(0xFF0284C7),
                ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                tooltip: 'Voltar',
              ),
              const Spacer(),
              if (canManage) ...[
                IconButton(
                  tooltip: 'Editar escala',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                ),
                IconButton(
                  tooltip: 'Excluir escala',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                day,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 72,
                  fontWeight: FontWeight.w700,
                  height: 0.9,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  month,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$weekday · $startTime – $endTime',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostosGrid extends StatelessWidget {
  final List<SchedulePosition> positions;
  final Map<String, String> memberNames;
  final String? selectedId;
  final Color card;
  final Color border;
  final Color t1;
  final Color t2;
  final bool isDark;
  final Color Function(SchedulePosition) statusColor;
  final String Function(SchedulePosition) statusLabel;
  final String Function(String) initials;
  final ValueChanged<String> onSelect;

  const _PostosGrid({
    required this.positions,
    required this.memberNames,
    required this.selectedId,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final tileWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final position in positions)
              SizedBox(
                width: tileWidth,
                child: _PostoTile(
                  position: position,
                  memberName: memberNames[position.memberId] ??
                      position.memberName ??
                      'Membro',
                  selected: position.id == selectedId,
                  card: card,
                  border: border,
                  t1: t1,
                  t2: t2,
                  isDark: isDark,
                  statusColor: statusColor(position),
                  statusLabel: statusLabel(position),
                  initials: initials(
                    memberNames[position.memberId] ??
                        position.memberName ??
                        'Membro',
                  ),
                  onTap: () => onSelect(position.id),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PostoTile extends StatelessWidget {
  final SchedulePosition position;
  final String memberName;
  final bool selected;
  final Color card;
  final Color border;
  final Color t1;
  final Color t2;
  final bool isDark;
  final Color statusColor;
  final String statusLabel;
  final String initials;
  final VoidCallback onTap;

  const _PostoTile({
    required this.position,
    required this.memberName,
    required this.selected,
    required this.card,
    required this.border,
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _sky : border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(13),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
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
                    const SizedBox(height: 10),
                    Text(
                      position.position,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: t1,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      memberName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: t2, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionStrip extends StatelessWidget {
  final SchedulePosition position;
  final String memberName;
  final bool isMine;
  final Color t1;
  final Color t2;
  final Color card;
  final Color border;
  final VoidCallback onConfirm;
  final VoidCallback onUnavailable;

  const _ActionStrip({
    required this.position,
    required this.memberName,
    required this.isMine,
    required this.t1,
    required this.t2,
    required this.card,
    required this.border,
    required this.onConfirm,
    required this.onUnavailable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isMine ? 'Sua função' : 'Função selecionada',
            style: TextStyle(
              color: t2,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            position.position,
            style: TextStyle(
              color: t1,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            memberName,
            style: TextStyle(color: t2, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onConfirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: _sky,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Confirmar',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onUnavailable,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _errorColor,
                    side: const BorderSide(color: _errorColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Indisponível',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
