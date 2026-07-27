import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../core/config/theme/app_spacing.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/router/app_routes.dart';
import '../../domain/birthday_model.dart';
import '../providers/member_provider.dart';

class BirthdaysScreen extends ConsumerStatefulWidget {
  const BirthdaysScreen({super.key});

  @override
  ConsumerState<BirthdaysScreen> createState() => _BirthdaysScreenState();
}

class _BirthdaysScreenState extends ConsumerState<BirthdaysScreen> {
  String _period = 'week';

  static const _periods = [
    ('today', 'Hoje'),
    ('week', 'Esta semana'),
    ('month', 'Este mês'),
  ];

  static final _dayMonth = DateFormat('dd/MM');
  static final _rangeFmt = DateFormat('dd/MM');
  static const _weekdays = ['', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  String _rangeLabel(BirthdayListResult result) {
    if (result.period == 'today') {
      return _rangeFmt.format(result.startDate);
    }
    return '${_rangeFmt.format(result.startDate)} – ${_rangeFmt.format(result.endDate)}';
  }

  String _dayLabel(BirthdayMember item) {
    if (item.isToday) return 'Hoje';
    final weekday = _weekdays[item.birthdayThisYear.weekday];
    return '$weekday · ${_dayMonth.format(item.birthdayThisYear)}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(birthdayListProvider);
    final result = state.data;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aniversariantes'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: _periods
                  .map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: AppChip(
                        label: p.$2,
                        selected: _period == p.$1,
                        onTap: () {
                          setState(() => _period = p.$1);
                          ref.read(birthdayListProvider.notifier).load(p.$1);
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 4, AppSpacing.lg, AppSpacing.sm),
            child: Text(
              state.loading
                  ? 'Carregando...'
                  : '${result.total} aniversariante${result.total == 1 ? '' : 's'} · ${_rangeLabel(result)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: secondary),
            ),
          ),
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(child: Text('Erro: ${state.error}'))
                    : result.items.isEmpty
                        ? const AppEmptyState(
                            title: 'Nenhum aniversariante',
                            subtitle: 'Não há aniversários neste período',
                            icon: Icons.cake_outlined,
                          )
                        : RefreshIndicator(
                            onRefresh: () => ref.read(birthdayListProvider.notifier).load(_period),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                              itemCount: result.items.length,
                              itemBuilder: (context, index) {
                                final item = result.items[index];
                                final member = item.member;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                  child: AppCard(
                                    onTap: () => context.push(AppRoutes.memberDetail(member.id)),
                                    child: Row(
                                      children: [
                                        AppAvatar(name: member.name, size: 44),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                member.name,
                                                style: Theme.of(context).textTheme.titleSmall,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                item.turningAge > 0
                                                    ? 'Completa ${item.turningAge} anos'
                                                    : 'Aniversário',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: secondary,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Icon(
                                              Icons.cake_rounded,
                                              size: 18,
                                              color: item.isToday ? AppColors.primary : secondary,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _dayLabel(item),
                                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                    color: item.isToday ? AppColors.primary : secondary,
                                                    fontWeight: item.isToday ? FontWeight.w600 : FontWeight.w400,
                                                  ),
                                            ),
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
    );
  }
}
