import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../data/activity_log_model.dart';
import '../providers/activity_log_provider.dart';

class ActivityLogsScreen extends ConsumerWidget {
  const ActivityLogsScreen({super.key});

  static const _filters = <(String?, String)>[
    (null, 'Todos'),
    ('MEMBERS', 'Membros'),
    ('FINANCE', 'Financeiro'),
    ('EVENTS', 'Eventos'),
    ('SCHEDULES', 'Escalas'),
    ('PRAYERS', 'Orações'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activityLogListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightSurface;
    final t1 = isDark ? AppColors.darkText : AppColors.lightText;
    final t2 = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Logs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.dashboard);
            }
          },
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final (value, label) = _filters[index];
                final selected = state.domain == value;
                return ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => ref.read(activityLogListProvider.notifier).setDomain(value),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref.read(activityLogListProvider.notifier).load(),
              child: state.loading && state.items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null && state.items.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.xl),
                                child: Text(state.error!, textAlign: TextAlign.center, style: TextStyle(color: t2)),
                              ),
                            ),
                          ],
                        )
                      : state.items.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                const SizedBox(height: 80),
                                Center(
                                  child: Text(
                                    'Nenhum log encontrado',
                                    style: TextStyle(color: t2),
                                  ),
                                ),
                              ],
                            )
                          : NotificationListener<ScrollNotification>(
                              onNotification: (notification) {
                                if (notification.metrics.pixels >=
                                    notification.metrics.maxScrollExtent - 200) {
                                  ref.read(activityLogListProvider.notifier).loadMore();
                                }
                                return false;
                              },
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.xl,
                                  AppSpacing.sm,
                                  AppSpacing.xl,
                                  AppSpacing.bottomNavClearance,
                                ),
                                itemCount: state.items.length + (state.loadingMore ? 1 : 0),
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  if (index >= state.items.length) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      child: Center(child: CircularProgressIndicator()),
                                    );
                                  }
                                  final item = state.items[index];
                                  return _LogTile(
                                    item: item,
                                    card: card,
                                    border: border,
                                    t1: t1,
                                    t2: t2,
                                    dateLabel: dateFmt.format(item.createdAt.toLocal()),
                                  );
                                },
                              ),
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final ActivityLogModel item;
  final Color card;
  final Color border;
  final Color t1;
  final Color t2;
  final String dateLabel;

  const _LogTile({
    required this.item,
    required this.card,
    required this.border,
    required this.t1,
    required this.t2,
    required this.dateLabel,
  });

  Color get _accent {
    switch (item.domain) {
      case 'MEMBERS':
        return AppColors.warning;
      case 'FINANCE':
        return AppColors.success;
      case 'EVENTS':
        return AppColors.primary;
      case 'SCHEDULES':
        return const Color(0xFF0F766E);
      case 'PRAYERS':
        return const Color(0xFF008CFF);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final actor = item.changedBy?.displayName ?? item.changedByRole ?? 'Sistema';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconForDomain(item.domain), color: _accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.domainLabel} · ${item.actionLabel}',
                  style: TextStyle(fontWeight: FontWeight.w700, color: t1),
                ),
                const SizedBox(height: 4),
                Text(
                  item.entityLabel?.trim().isNotEmpty == true
                      ? item.entityLabel!
                      : item.entityId,
                  style: TextStyle(color: t1),
                ),
                const SizedBox(height: 6),
                Text(
                  '$actor · $dateLabel',
                  style: TextStyle(fontSize: 12, color: t2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForDomain(String domain) {
    switch (domain) {
      case 'MEMBERS':
        return Icons.people_rounded;
      case 'FINANCE':
        return Icons.account_balance_rounded;
      case 'EVENTS':
        return Icons.event_rounded;
      case 'SCHEDULES':
        return Icons.calendar_month_rounded;
      case 'PRAYERS':
        return Icons.volunteer_activism_rounded;
      default:
        return Icons.history_rounded;
    }
  }
}
