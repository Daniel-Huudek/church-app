import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../members/domain/birthday_model.dart';
import '../../../members/presentation/providers/member_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static final _dayMonth = DateFormat('dd/MM');
  static const _weekdays = ['', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  String _dayLabel(BirthdayMember item) {
    if (item.isToday) return 'Hoje';
    final weekday = _weekdays[item.birthdayThisYear.weekday];
    return '$weekday · ${_dayMonth.format(item.birthdayThisYear)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0A0F) : Colors.white;
    final t1 = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final t2 = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final birthdays = ref.watch(weeklyBirthdaysProvider);

    return Container(
      color: bg,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(weeklyBirthdaysProvider);
          await ref.read(weeklyBirthdaysProvider.future);
        },
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 72, 20, 120),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Aniversariantes da semana',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: t1,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(AppRoutes.birthdays),
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            birthdays.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('Não foi possível carregar: $e', style: TextStyle(color: t2)),
              ),
              data: (result) {
                if (result.items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(Icons.cake_outlined, size: 40, color: t2),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhum aniversariante esta semana',
                          style: TextStyle(color: t2),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: result.items.map((item) {
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
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: t1),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.turningAge > 0
                                        ? 'Completa ${item.turningAge} anos'
                                        : 'Aniversário',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t2),
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
                                  color: item.isToday ? AppColors.primary : t2,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _dayLabel(item),
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: item.isToday ? AppColors.primary : t2,
                                        fontWeight: item.isToday ? FontWeight.w600 : FontWeight.w400,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
