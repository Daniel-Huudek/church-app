import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_spacing.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/widgets/animated/fade_in.dart';
import '../../../../shared/widgets/animated/slide_up.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../bible/presentation/providers/verse_of_the_day_provider.dart';
import '../../../events/domain/event_model.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../members/domain/birthday_model.dart';
import '../../../members/presentation/providers/member_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static final _dayMonth = DateFormat('dd/MM');
  static final _eventDay = DateFormat('dd');
  static final _eventMonth = DateFormat('MMM', 'pt_BR');
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

  List<EventModel> _upcoming(List<EventModel> events) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final upcoming = events
        .where((e) => !e.date.isBefore(startOfToday) && e.status != 'CANCELADO')
        .toList()
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        if (byDate != 0) return byDate;
        return a.startTime.compareTo(b.startTime);
      });
    return upcoming.take(3).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authProvider).user;
    final verseAsync = ref.watch(verseOfTheDayProvider);
    final birthdays = ref.watch(weeklyBirthdaysProvider);
    final eventsState = ref.watch(eventListProvider);
    final upcoming = _upcoming(eventsState.data);

    final bgTop = isDark ? AppColors.darkSurface : AppColors.primary50;
    final bgBottom = isDark ? AppColors.darkBg : AppColors.lightSurface;
    final t1 = isDark ? AppColors.darkText : AppColors.lightText;
    final t2 = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final firstName = _firstName(user?.name);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgTop, bgBottom],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(verseOfTheDayProvider);
            ref.invalidate(weeklyBirthdaysProvider);
            await Future.wait([
              ref.read(verseOfTheDayProvider.future),
              ref.read(weeklyBirthdaysProvider.future),
              ref.read(eventListProvider.notifier).load(),
            ]);
          },
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.bottomNavClearance,
            ),
            children: [
              FadeIn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: t1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      firstName.isEmpty
                          ? _greeting()
                          : '${_greeting()}, $firstName',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: t2,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl2),
              Text(
                'Palavra do dia',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: t1,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              verseAsync.when(
                loading: () => const _VerseSkeleton(),
                error: (_, __) => SlideUp(
                  child: _VerseCard(
                    text: 'O Senhor é o meu pastor; nada me faltará.',
                    reference: 'Salmos 23:1',
                    translation: 'NAA',
                    t1: t1,
                    t2: t2,
                    isDark: isDark,
                    onTap: () => context.go(AppRoutes.bible),
                  ),
                ),
                data: (verse) => SlideUp(
                  child: _VerseCard(
                    text: verse.text,
                    reference: verse.reference,
                    translation: 'NAA',
                    t1: t1,
                    t2: t2,
                    isDark: isDark,
                    onTap: () => context.push(
                      AppRoutes.bibleVerseReader(
                        verse.bookId,
                        verse.chapter,
                        verse.verse,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl3),
              _SectionHeader(
                title: 'Próximos eventos',
                actionLabel: 'Ver agenda',
                t1: t1,
                onAction: () => context.go(AppRoutes.calendar),
              ),
              const SizedBox(height: AppSpacing.md),
              if (eventsState.loading && upcoming.isEmpty)
                const _EventsSkeleton()
              else if (upcoming.isEmpty)
                _QuietEmpty(
                  icon: Icons.event_available_rounded,
                  message: 'Nenhum evento próximo',
                  t2: t2,
                  card: card,
                  border: border,
                )
              else
                ...upcoming.asMap().entries.map((entry) {
                  final event = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: entry.key == upcoming.length - 1
                          ? 0
                          : AppSpacing.md,
                    ),
                    child: SlideUp(
                      child: _EventRow(
                        event: event,
                        t1: t1,
                        t2: t2,
                        card: card,
                        border: border,
                        onTap: () =>
                            context.push(AppRoutes.calendarDetail(event.id)),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: AppSpacing.xl3),
              _SectionHeader(
                title: 'Aniversariantes',
                actionLabel: 'Ver todos',
                t1: t1,
                onAction: () => context.push(AppRoutes.birthdays),
              ),
              const SizedBox(height: AppSpacing.md),
              birthdays.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl2),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => _QuietEmpty(
                  icon: Icons.cake_outlined,
                  message: 'Não foi possível carregar aniversariantes',
                  t2: t2,
                  card: card,
                  border: border,
                ),
                data: (result) {
                  if (result.items.isEmpty) {
                    return _QuietEmpty(
                      icon: Icons.cake_outlined,
                      message: 'Nenhum aniversariante esta semana',
                      t2: t2,
                      card: card,
                      border: border,
                    );
                  }
                  final items = result.items.take(4).toList();
                  return Column(
                    children: items.map((item) {
                      final member = item.member;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: AppCard(
                          onTap: () =>
                              context.push(AppRoutes.memberDetail(member.id)),
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(color: t1),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.turningAge > 0
                                          ? 'Completa ${item.turningAge} anos'
                                          : 'Aniversário',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: t2),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: item.isToday
                                      ? AppColors.primary.withValues(alpha: 0.12)
                                      : (isDark
                                          ? AppColors.darkSurface
                                          : AppColors.lightSurface),
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusFull,
                                  ),
                                ),
                                child: Text(
                                  _dayLabel(item),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: item.isToday
                                            ? AppColors.primary
                                            : t2,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
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
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final Color t1;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.t1,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: t1,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            actionLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _QuietEmpty extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color t2;
  final Color card;
  final Color border;

  const _QuietEmpty({
    required this.icon,
    required this.message,
    required this.t2,
    required this.card,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl2,
      ),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: t2.withValues(alpha: 0.7)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: t2),
          ),
        ],
      ),
    );
  }
}

class _VerseSkeleton extends StatelessWidget {
  const _VerseSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkCard
            : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkBorder
              : AppColors.lightBorder,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton(width: 28, height: 28, borderRadius: 8),
          SizedBox(height: AppSpacing.md),
          AppSkeleton(height: 18),
          SizedBox(height: AppSpacing.sm),
          AppSkeleton(height: 18),
          SizedBox(height: AppSpacing.sm),
          AppSkeleton(width: 180, height: 18),
          SizedBox(height: AppSpacing.lg),
          AppSkeleton(width: 120, height: 14),
        ],
      ),
    );
  }
}

class _EventsSkeleton extends StatelessWidget {
  const _EventsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AppSkeletonCard(lines: 2),
        SizedBox(height: AppSpacing.md),
        AppSkeletonCard(lines: 2),
      ],
    );
  }
}

class _VerseCard extends StatelessWidget {
  final String text;
  final String reference;
  final String translation;
  final Color t1;
  final Color t2;
  final bool isDark;
  final VoidCallback onTap;

  const _VerseCard({
    required this.text,
    required this.reference,
    required this.translation,
    required this.t1,
    required this.t2,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.primary100,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [AppColors.darkCard, AppColors.darkSurface]
                  : [Colors.white, AppColors.primary50],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: const Icon(
                        Icons.format_quote_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      translation,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: t2,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.1,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  text,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: t1,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        reference,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: AppColors.primary.withValues(alpha: 0.8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final EventModel event;
  final Color t1;
  final Color t2;
  final Color card;
  final Color border;
  final VoidCallback onTap;

  const _EventRow({
    required this.event,
    required this.t1,
    required this.t2,
    required this.card,
    required this.border,
    required this.onTap,
  });

  static const _typeLabels = {
    'WORSHIP': 'Culto',
    'EVENT': 'Evento',
    'REHEARSAL': 'Ensaio',
  };

  String _timeLabel(String time) {
    final parts = time.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return time;
  }

  @override
  Widget build(BuildContext context) {
    final day = DashboardScreen._eventDay.format(event.date);
    final month = DashboardScreen._eventMonth.format(event.date).toUpperCase();
    final typeLabel = _typeLabels[event.type] ?? 'Evento';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Ink(
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        day,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                      ),
                      Text(
                        month,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        typeLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: t1,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          _timeLabel(event.startTime),
                          if (event.location != null &&
                              event.location!.trim().isNotEmpty)
                            event.location!.trim(),
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: t2),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: t2, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
