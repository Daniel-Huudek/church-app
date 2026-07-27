import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../bible/presentation/providers/verse_of_the_day_provider.dart';
import '../../../members/domain/birthday_model.dart';
import '../../../members/presentation/providers/member_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static final _dayMonth = DateFormat('dd/MM');
  static const _weekdays = ['', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  String _firstName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return '';
    return fullName.trim().split(' ').first;
  }

  String _dayLabel(BirthdayMember item) {
    if (item.isToday) return 'Hoje';
    final weekday = _weekdays[item.birthdayThisYear.weekday];
    return '$weekday · ${_dayMonth.format(item.birthdayThisYear)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authProvider).user;
    final verseAsync = ref.watch(verseOfTheDayProvider);
    final birthdays = ref.watch(weeklyBirthdaysProvider);

    final bgTop = isDark ? const Color(0xFF0B1220) : const Color(0xFFE8F3FF);
    final bgBottom = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF7FAFC);
    final t1 = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF0F172A);
    final t2 = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final card = isDark ? AppColors.darkCard : Colors.white;
    final border = isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgTop, bgBottom],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(verseOfTheDayProvider);
          ref.invalidate(weeklyBirthdaysProvider);
          await Future.wait([
            ref.read(verseOfTheDayProvider.future),
            ref.read(weeklyBirthdaysProvider.future),
          ]);
        },
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 64, 20, 120),
          children: [
            Text(
              _firstName(user?.name).isEmpty
                  ? _greeting()
                  : '${_greeting()}, ${_firstName(user?.name)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: t2,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Palavra do dia',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: t1,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 20),
            verseAsync.when(
              loading: () => Container(
                height: 160,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: card.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const CircularProgressIndicator(),
              ),
              error: (_, __) => _verseFallback(context, t1, t2, card, border),
              data: (verse) => _VerseCard(
                text: verse.text,
                reference: '${verse.reference} · NAA',
                t1: t1,
                t2: t2,
                card: card,
                border: border,
                isDark: isDark,
                onTap: () => context.push(
                  AppRoutes.bibleVerseReader(verse.bookId, verse.chapter, verse.verse),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _FeatureTile(
                    icon: Icons.menu_book_rounded,
                    label: 'Bíblia',
                    subtitle: 'Ler a Palavra',
                    color: AppColors.primary,
                    card: card,
                    border: border,
                    t1: t1,
                    t2: t2,
                    onTap: () => context.go(AppRoutes.bible),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FeatureTile(
                    icon: Icons.favorite_rounded,
                    label: 'Oração',
                    subtitle: 'Pedidos e intercessão',
                    color: const Color(0xFFE11D48),
                    card: card,
                    border: border,
                    t1: t1,
                    t2: t2,
                    onTap: () => context.go(AppRoutes.prayers),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Aniversariantes da semana',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: t1,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            birthdays.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('Não foi possível carregar: $e', style: TextStyle(color: t2)),
              ),
              data: (result) {
                if (result.items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Nenhum aniversariante esta semana',
                      style: TextStyle(color: t2),
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

  Widget _verseFallback(
    BuildContext context,
    Color t1,
    Color t2,
    Color card,
    Color border,
  ) {
    return _VerseCard(
      text: 'O Senhor é o meu pastor; nada me faltará.',
      reference: 'Salmos 23:1 · NAA',
      t1: t1,
      t2: t2,
      card: card,
      border: border,
      isDark: Theme.of(context).brightness == Brightness.dark,
      onTap: () => context.go(AppRoutes.bible),
    );
  }
}

class _VerseCard extends StatelessWidget {
  final String text;
  final String reference;
  final Color t1;
  final Color t2;
  final Color card;
  final Color border;
  final bool isDark;
  final VoidCallback onTap;

  const _VerseCard({
    required this.text,
    required this.reference,
    required this.t1,
    required this.t2,
    required this.card,
    required this.border,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF152238), const Color(0xFF1A1A2E)]
                  : [Colors.white, const Color(0xFFF0F7FF)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.format_quote_rounded, color: AppColors.primary.withValues(alpha: 0.7), size: 28),
                const SizedBox(height: 12),
                Text(
                  text,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: t1,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  reference,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final Color card;
  final Color border;
  final Color t1;
  final Color t2;
  final VoidCallback onTap;

  const _FeatureTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.card,
    required this.border,
    required this.t1,
    required this.t2,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 14),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: t1,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
