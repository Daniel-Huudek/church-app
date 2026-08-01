import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_spacing.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/widgets/animated/fade_in.dart';
import '../../../../shared/widgets/animated/slide_up.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../bible/presentation/providers/verse_of_the_day_provider.dart';
import '../../../events/domain/event_model.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../members/domain/birthday_model.dart';
import '../../../members/data/member_api.dart';
import '../../../members/presentation/providers/member_provider.dart';
import '../../../schedules/data/schedule_api.dart';
import '../../../worship/presentation/providers/worship_provider.dart';

class _PersonalScale {
  final String kind;
  final String title;
  final String role;
  final String status;
  final DateTime date;
  final String startTime;
  final String route;

  const _PersonalScale({
    required this.kind,
    required this.title,
    required this.role,
    required this.status,
    required this.date,
    required this.startTime,
    required this.route,
  });
}

DateTime _scaleMoment(DateTime date, String startTime) {
  final parts = startTime.split(':');
  final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return DateTime(date.year, date.month, date.day, hour, minute);
}

final _personalScaleProvider =
    FutureProvider.autoDispose<_PersonalScale?>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return null;

  final apiClient = ref.read(apiClientProvider);
  final memberApi = MemberApi(apiClient);
  final member = await memberApi.getMe();
  if (member == null) return null;

  final candidates = <_PersonalScale>[];
  final startOfToday = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  final eventRepo = ref.read(eventRepositoryProvider);

  try {
    final worshipResult =
        await ref.read(worshipRepositoryProvider).listWorshipEvents(limit: 50);
    for (final worshipEvent in worshipResult.data) {
      final musician = (worshipEvent.musicians ?? [])
          .where((item) => item.memberId == member.id)
          .firstOrNull;
      final isMinister = worshipEvent.ministerMemberId == member.id;
      if (musician == null && !isMinister) continue;

      try {
        final event = (await eventRepo.getById(worshipEvent.eventId)).data;
        if (event.date.isBefore(startOfToday)) continue;
        final role = isMinister
            ? 'Ministro'
            : (musician?.instrument?.trim().isNotEmpty == true
                ? musician!.instrument!.trim()
                : musician?.role?.trim().isNotEmpty == true
                    ? musician!.role!.trim()
                    : 'Louvor');
        final status = isMinister
            ? 'Escalado'
            : musician!.isSubstituted
                ? 'Indisponível'
                : musician.isConfirmed
                    ? 'Confirmado'
                    : 'Pendente';
        candidates.add(
          _PersonalScale(
            kind: 'Louvor',
            title: event.title,
            role: role,
            status: status,
            date: event.date,
            startTime: event.startTime,
            route: AppRoutes.worshipScaleDetail(worshipEvent.id),
          ),
        );
      } catch (_) {
        // Ignora somente o evento que não pôde ser enriquecido.
      }
    }
  } catch (_) {
    // A home continua funcionando se o módulo Louvor estiver indisponível.
  }

  try {
    final ministries = await memberApi.listMinistries();
    final deaconMinistries = ministries.where((ministry) {
      final name = ministry.name.toLowerCase();
      return name.contains('diácono') || name.contains('diacon');
    });
    if (deaconMinistries.isNotEmpty) {
      final schedules = await ScheduleApi(apiClient).list(
        ministryId: deaconMinistries.first.id,
      );
      for (final schedule in schedules) {
        if (schedule.date.isBefore(startOfToday)) continue;
        final position = schedule.positionDetails
            .where((item) => item.memberId == member.id)
            .firstOrNull;
        if (position == null) continue;

        var title = schedule.eventName ?? 'Escala de Diáconos';
        if (schedule.eventId != null) {
          try {
            title = (await eventRepo.getById(schedule.eventId!)).data.title;
          } catch (_) {}
        }
        candidates.add(
          _PersonalScale(
            kind: 'Diáconos',
            title: title,
            role: position.position,
            status: position.isSubstituted
                ? 'Indisponível'
                : position.isConfirmed
                    ? 'Confirmado'
                    : 'Pendente',
            date: schedule.date,
            startTime: schedule.startTime,
            route: AppRoutes.deaconDetail(schedule.id),
          ),
        );
      }
    }
  } catch (_) {
    // A home continua funcionando se o módulo Diáconos estiver indisponível.
  }

  candidates.sort(
    (a, b) => _scaleMoment(a.date, a.startTime)
        .compareTo(_scaleMoment(b.date, b.startTime)),
  );
  return candidates.firstOrNull;
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static final _dayMonth = DateFormat('dd/MM');
  static final _eventDay = DateFormat('dd');
  static final _eventMonth = DateFormat('MMM', 'pt_BR');
  static final _fullDate = DateFormat("EEEE, d 'de' MMMM", 'pt_BR');
  static const _weekdays = [
    '',
    'Seg',
    'Ter',
    'Qua',
    'Qui',
    'Sex',
    'Sáb',
    'Dom'
  ];

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

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
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
    final canOpenMemberDetail = user?.hasPermission('members_read') == true;
    final verseAsync = ref.watch(verseOfTheDayProvider);
    final birthdays = ref.watch(weeklyBirthdaysProvider);
    final eventsState = ref.watch(eventListProvider);
    final personalScale = ref.watch(_personalScaleProvider);
    final upcoming = _upcoming(eventsState.data);

    final bgTop = isDark ? AppColors.darkSurface : const Color(0xFFF4F7FB);
    final bgBottom = isDark ? AppColors.darkBg : AppColors.lightSurface;
    final t1 = isDark ? AppColors.darkText : AppColors.lightText;
    final t2 =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
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
            ref.invalidate(_personalScaleProvider);
            await Future.wait([
              ref.read(verseOfTheDayProvider.future),
              ref.read(weeklyBirthdaysProvider.future),
              ref.read(eventListProvider.notifier).load(),
              ref.read(_personalScaleProvider.future),
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConstants.appName.toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            firstName.isEmpty
                                ? _greeting()
                                : '${_greeting()}, $firstName',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: t1,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _capitalize(_fullDate.format(DateTime.now())),
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: t2),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.profile),
                      child: AppAvatar(
                        name: user?.name ?? 'Usuário',
                        imageUrl: user?.avatar,
                        size: 46,
                      ),
                    ),
                  ],
                ),
              ),
              personalScale.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.xl2),
                  child: AppSkeleton(
                    height: 156,
                    borderRadius: AppSpacing.radiusXl,
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (scale) {
                  if (scale == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl2),
                    child: SlideUp(
                      child: _PersonalScaleCard(
                        scale: scale,
                        onTap: () => context.push(scale.route),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl2),
              _SectionHeader(
                title: 'Palavra do dia',
                actionLabel: 'Abrir Bíblia',
                t1: t1,
                onAction: () => context.go(AppRoutes.bible),
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
                title: 'Agenda',
                actionLabel: 'Ver tudo',
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
                      bottom:
                          entry.key == upcoming.length - 1 ? 0 : AppSpacing.md,
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
                title: 'Celebramos juntos',
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
                  return _BirthdayOverviewCard(
                    items: items,
                    isDark: isDark,
                    t1: t1,
                    t2: t2,
                    dayLabel: _dayLabel,
                    onMemberTap: canOpenMemberDetail
                        ? (memberId) =>
                            context.push(AppRoutes.memberDetail(memberId))
                        : null,
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

class _PersonalScaleCard extends StatelessWidget {
  final _PersonalScale scale;
  final VoidCallback onTap;

  const _PersonalScaleCard({
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final day = DashboardScreen._eventDay.format(scale.date);
    final month = DashboardScreen._eventMonth
        .format(scale.date)
        .replaceAll('.', '')
        .toUpperCase();
    final statusColor = scale.status == 'Confirmado'
        ? const Color(0xFF16A34A)
        : scale.status == 'Indisponível'
            ? const Color(0xFFEF4444)
            : const Color(0xFFF59E0B);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF008CFF), Color(0xFF0066CC)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.24),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            scale.kind == 'Louvor'
                                ? Icons.music_note_rounded
                                : Icons.volunteer_activism_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'MINHA ESCALA · ${scale.kind.toUpperCase()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 52,
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            day,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            month,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  scale.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      scale.startTime,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.white54,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        scale.role,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            scale.status == 'Confirmado'
                                ? Icons.check_circle_rounded
                                : scale.status == 'Indisponível'
                                    ? Icons.cancel_rounded
                                    : Icons.schedule_rounded,
                            color: statusColor,
                            size: 15,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            scale.status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Ver escala',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 17,
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

class _BirthdayOverviewCard extends StatelessWidget {
  final List<BirthdayMember> items;
  final bool isDark;
  final Color t1;
  final Color t2;
  final String Function(BirthdayMember) dayLabel;
  final ValueChanged<String>? onMemberTap;

  const _BirthdayOverviewCard({
    required this.items,
    required this.isDark,
    required this.t1,
    required this.t2,
    required this.dayLabel,
    this.onMemberTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            InkWell(
              onTap: onMemberTap == null
                  ? null
                  : () => onMemberTap!(items[index].member.id),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    AppAvatar(
                      name: items[index].member.name,
                      imageUrl: items[index].member.avatar,
                      size: 40,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        items[index].member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: t1,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: items[index].isToday
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : (isDark
                                ? AppColors.darkSurface
                                : const Color(0xFFF4F7FB)),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusFull,
                        ),
                      ),
                      child: Text(
                        dayLabel(items[index]),
                        style: TextStyle(
                          color: items[index].isToday ? AppColors.primary : t2,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (index < items.length - 1)
              Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
          ],
        ],
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
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
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
