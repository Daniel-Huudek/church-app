import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/offline/offline_guard.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/utils/person_name.dart';
import '../../../../shared/widgets/scale_month_picker.dart';
import '../../../events/data/event_api.dart';
import '../../../members/data/member_api.dart';
import '../../../schedules/data/schedule_api.dart';
import '../../../schedules/domain/schedule_model.dart';
import '../../data/deacon_ministry_helper.dart';

class DeaconDashboardScreen extends ConsumerStatefulWidget {
  const DeaconDashboardScreen({super.key});

  @override
  ConsumerState<DeaconDashboardScreen> createState() =>
      _DeaconDashboardScreenState();
}

class _DeaconDashboardScreenState extends ConsumerState<DeaconDashboardScreen> {
  int _tab = 0;
  bool _loading = true;
  bool _copying = false;
  String? _error;
  String? _ministryId;
  List<_DeaconScaleItem> _items = [];
  Map<String, String> _memberNames = {};

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

      final memberNames = <String, String>{};
      final memberIds = schedules
          .expand((schedule) => schedule.positionDetails)
          .map((position) => position.memberId)
          .whereType<String>()
          .toSet();
      await Future.wait(memberIds.map((memberId) async {
        try {
          final member = await memberApi.getById(memberId);
          memberNames[memberId] = scaleCopyDisplayName(
            name: member.name,
            nickname: member.nickname,
          );
        } catch (_) {
          // O detalhe da posição continua sendo exibido com nome fallback.
        }
      }));

      if (!mounted) return;
      setState(() {
        _ministryId = ministry.id;
        _items = enriched;
        _memberNames = memberNames;
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

    final availableDates = _items.map((item) => item.schedule.date).toList();
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
      final date = item.schedule.date;
      return date.year == selectedMonth.year &&
          date.month == selectedMonth.month;
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
      final monthLabel = _capitalize(
        DateFormat('MMMM/yyyy', 'pt_BR').format(selectedMonth),
      );

      buffer.writeln('*Escala de Diáconos — $monthLabel*');
      buffer.writeln();

      for (final item in monthItems) {
        ScheduleModel schedule = item.schedule;
        try {
          schedule = await scheduleApi.getById(item.schedule.id);
        } catch (_) {}

        final dayLabel = _capitalize(
          DateFormat('EEEE, dd/MM', 'pt_BR').format(schedule.date),
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
            var label = memberId != null ? nameCache[memberId] : null;
            if (label == null && memberId != null) {
              try {
                final member = await memberApi.getById(memberId);
                label = scaleCopyDisplayName(
                  name: member.name,
                  nickname: member.nickname,
                );
                nameCache[memberId] = label;
              } catch (_) {
                final fallback = position.memberName?.trim();
                label = (fallback != null && fallback.isNotEmpty)
                    ? abbreviatePersonName(fallback)
                    : 'Membro';
                nameCache[memberId] = label;
              }
            }
            if (label == null) {
              final fallback = position.memberName?.trim();
              label = (fallback != null && fallback.isNotEmpty)
                  ? abbreviatePersonName(fallback)
                  : 'Membro';
            }
            buffer.writeln('• $label — ${position.position}');
          }
        }
        buffer.writeln();
      }

      await Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Escala de $monthLabel copiada! Cole no WhatsApp')),
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

    final bg = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF4F6F8);
    final t1 = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF17233B);
    final t2 = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF667085);

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
            _buildTopBar(isDark, canCreate, t1, t2),
            _buildTabs(isDark, t2),
            const SizedBox(height: 14),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Não foi possível carregar as escalas.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: t2),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: filtered.isEmpty
                              ? _buildEmptyState(t2)
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    4,
                                    20,
                                    110,
                                  ),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 14),
                                  itemBuilder: (context, index) {
                                    final item = filtered[index];
                                    return _buildScheduleCard(
                                      item,
                                      isDark: isDark,
                                      primaryText: t1,
                                      secondaryText: t2,
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
                foregroundColor: Colors.white,
                elevation: 3,
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Nova escala',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildTopBar(
    bool isDark,
    bool canCreate,
    Color primaryText,
    Color secondaryText,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          _headerAction(
            tooltip: 'Voltar',
            icon: Icons.arrow_back_rounded,
            isDark: isDark,
            onPressed: () => context.go(AppRoutes.home),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF008CFF).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.volunteer_activism_rounded,
              color: Color(0xFF008CFF),
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Escala de Diáconos',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: primaryText,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Equipe de serviço',
                  style: TextStyle(fontSize: 12, color: secondaryText),
                ),
              ],
            ),
          ),
          _headerAction(
            tooltip: 'Copiar escala do mês',
            icon: Icons.content_copy_rounded,
            isDark: isDark,
            loading: _copying,
            onPressed: _loading || _copying ? null : _copyMonthForWhatsApp,
          ),
          if (canCreate) ...[
            const SizedBox(width: 6),
            Opacity(
              opacity: watchIsOnline(ref) ? 1 : 0.45,
              child: _headerAction(
                tooltip: 'Nova escala',
                icon: Icons.add_rounded,
                isDark: isDark,
                emphasized: true,
                onPressed: guardOnlineAction(context, ref, () async {
                  await context.push(
                    AppRoutes.deaconsCreate,
                    extra: _ministryId,
                  );
                  _load();
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _headerAction({
    required String tooltip,
    required IconData icon,
    required bool isDark,
    required VoidCallback? onPressed,
    bool emphasized = false,
    bool loading = false,
  }) {
    final fill = emphasized
        ? const Color(0xFF008CFF)
        : isDark
            ? const Color(0xFF161622)
            : Colors.white;
    final foreground = emphasized ? Colors.white : const Color(0xFF008CFF);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(12),
              border: emphasized
                  ? null
                  : Border.all(
                      color: isDark
                          ? const Color(0xFF2D2D44)
                          : const Color(0xFFE4E7EC),
                    ),
            ),
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon, color: foreground, size: 21),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(bool isDark, Color secondaryText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161622) : const Color(0xFFE9EEF3),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            _tabButton(
              label: 'Próximas',
              value: 0,
              secondaryText: secondaryText,
            ),
            _tabButton(
              label: 'Passadas',
              value: 1,
              secondaryText: secondaryText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton({
    required String label,
    required int value,
    required Color secondaryText,
  }) {
    final selected = _tab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF008CFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : secondaryText,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color secondaryText) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.event_available_rounded,
          size: 52,
          color: const Color(0xFF008CFF).withValues(alpha: 0.35),
        ),
        const SizedBox(height: 14),
        Text(
          _tab == 0 ? 'Nenhuma escala futura' : 'Nenhuma escala passada',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: secondaryText,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleCard(
    _DeaconScaleItem item, {
    required bool isDark,
    required Color primaryText,
    required Color secondaryText,
  }) {
    final schedule = item.schedule;
    final total = schedule.positions;
    final confirmed = schedule.confirmed;
    final progress = total == 0 ? 0.0 : (confirmed / total).clamp(0.0, 1.0);
    final card = isDark ? const Color(0xFF161622) : Colors.white;
    final border = isDark ? const Color(0xFF2D2D44) : const Color(0xFFE4E7EC);
    final month = DateFormat('MMM', 'pt_BR')
        .format(schedule.date)
        .replaceAll('.', '')
        .toUpperCase();
    final weekday = _capitalize(
      DateFormat('EEEE', 'pt_BR').format(schedule.date),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await context.push(AppRoutes.deaconDetail(schedule.id));
          if (mounted) _load();
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 62,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF008CFF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          schedule.date.day.toString().padLeft(2, '0'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          month,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: primaryText,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 15,
                              color: secondaryText,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                '$weekday · ${schedule.startTime} — ${schedule.endTime}',
                                style: TextStyle(
                                  color: secondaryText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: secondaryText,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF008CFF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '$confirmed de $total confirmados',
                      style: const TextStyle(
                        color: Color(0xFF008CFF),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: isDark
                            ? const Color(0xFF2D2D44)
                            : const Color(0xFFE9EEF3),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF008CFF),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (schedule.positionDetails.isNotEmpty) ...[
                const SizedBox(height: 15),
                Divider(height: 1, color: border),
                const SizedBox(height: 12),
                _buildAssignmentsPreview(
                  schedule.positionDetails,
                  isDark: isDark,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentsPreview(
    List<SchedulePosition> positions, {
    required bool isDark,
    required Color primaryText,
    required Color secondaryText,
  }) {
    final visible = positions.take(4).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - 10) / 2;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final position in visible)
                  SizedBox(
                    width: tileWidth,
                    child: _assignmentTile(
                      position,
                      isDark: isDark,
                      primaryText: primaryText,
                      secondaryText: secondaryText,
                    ),
                  ),
              ],
            ),
            if (positions.length > visible.length) ...[
              const SizedBox(height: 10),
              Text(
                '+ ${positions.length - visible.length} funções',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xFF008CFF),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _assignmentTile(
    SchedulePosition position, {
    required bool isDark,
    required Color primaryText,
    required Color secondaryText,
  }) {
    final name = position.memberId != null
        ? _memberNames[position.memberId] ?? position.memberName ?? 'Membro'
        : position.memberName ?? 'Membro';
    final unavailable = position.isSubstituted ||
        position.status.toUpperCase() == 'INDISPONIVEL';
    final statusColor = position.isConfirmed
        ? const Color(0xFF16A34A)
        : unavailable
            ? const Color(0xFFEF4444)
            : const Color(0xFFF59E0B);
    final statusIcon = position.isConfirmed
        ? Icons.check_circle_rounded
        : unavailable
            ? Icons.cancel_rounded
            : Icons.schedule_rounded;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF10101A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF008CFF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF008CFF),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  position.position,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(statusIcon, size: 16, color: statusColor),
        ],
      ),
    );
  }
}

class _DeaconScaleItem {
  final ScheduleModel schedule;
  final String title;
  const _DeaconScaleItem({required this.schedule, required this.title});
}
