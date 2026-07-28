import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_tabs.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../core/config/theme/app_spacing.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/offline/offline_guard.dart';
import '../../domain/schedule_model.dart';
import '../providers/schedule_provider.dart';

class ScheduleListScreen extends ConsumerStatefulWidget {
  const ScheduleListScreen({super.key});

  @override
  ConsumerState<ScheduleListScreen> createState() => _ScheduleListScreenState();
}

class _ScheduleListScreenState extends ConsumerState<ScheduleListScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scheduleListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Escalas')),
      floatingActionButton: Opacity(
        opacity: watchIsOnline(ref) ? 1 : 0.45,
        child: FloatingActionButton(
          onPressed: guardOnlineAction(context, ref, () => context.push('/schedules/create')),
          child: const Icon(Icons.add),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          AppTabs(
            tabs: ['Minhas', 'Todas'],
            selectedIndex: _selectedTab,
            onTabChanged: (i) => setState(() => _selectedTab = i),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: state.loading && state.data.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.error != null && state.data.isEmpty
                    ? Center(child: Text('Erro: ${state.error}'))
                    : _selectedTab == 0 ? _buildMine(state.data) : _buildAll(state.data),
          ),
        ],
      ),
    );
  }

  Widget _buildMine(List<ScheduleModel> all) {
    final mine = all.where((s) => s.confirmed > 0).toList();
    if (mine.isEmpty) {
      return const AppEmptyState(
        title: 'Nenhuma escala',
        subtitle: 'Você não possui escalas confirmadas',
        icon: Icons.schedule,
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(scheduleListProvider.notifier).load(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: mine.length,
        itemBuilder: (context, index) {
          final s = mine[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppCard(
              onTap: () => context.push('/schedules/${s.id}'),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary100,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Center(
                      child: Text(
                        s.date.day.toString().padLeft(2, '0'),
                        style: TextStyle(
                          color: AppColors.primary700,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.eventName ?? 'Escala',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${s.startTime} - ${s.endTime}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  AppBadge(
                    label: s.status,
                    variant: s.status == 'CONFIRMADO'
                        ? AppBadgeVariant.success
                        : AppBadgeVariant.warning,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAll(List<ScheduleModel> all) {
    if (all.isEmpty) {
      return const AppEmptyState(
        title: 'Nenhuma escala',
        subtitle: 'Não há escalas cadastradas',
        icon: Icons.schedule,
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(scheduleListProvider.notifier).load(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: all.length,
        itemBuilder: (context, index) {
          final s = all[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppCard(
              onTap: () => context.push('/schedules/${s.id}'),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary100,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Center(
                      child: Text(
                        s.date.day.toString().padLeft(2, '0'),
                        style: TextStyle(
                          color: AppColors.primary700,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.eventName ?? 'Escala',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${s.startTime} - ${s.endTime}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  AppBadge(
                    label: s.status,
                    variant: s.status == 'CONFIRMADO'
                        ? AppBadgeVariant.success
                        : AppBadgeVariant.warning,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
