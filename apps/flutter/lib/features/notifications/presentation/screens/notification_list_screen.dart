import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../core/config/theme/app_spacing.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/notification_provider.dart';

class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(notificationListProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Notificações',
              action: TextButton(
                onPressed: state.notifications.any((n) => n.isUnread)
                    ? () => ref.read(notificationListProvider.notifier).markAllAsRead()
                    : null,
                child: const Text('Marcar todas como lidas'),
              ),
            ),
            Expanded(
              child: state.loading
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null
                      ? Center(child: Text('Erro: ${state.error}'))
                      : state.notifications.isEmpty
                          ? Center(child: Text('Nenhuma notificação', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)))
                          : RefreshIndicator(
                              onRefresh: () => ref.read(notificationListProvider.notifier).load(),
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                                itemCount: state.notifications.length,
                                itemBuilder: (context, index) {
                                  final n = state.notifications[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                    child: AppCard(
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary100,
                                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                            ),
                                            child: const Icon(
                                              Icons.notifications_outlined,
                                              color: AppColors.primary,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.md),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    if (n.isUnread)
                                                      Container(
                                                        width: 8,
                                                        height: 8,
                                                        decoration: const BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          color: AppColors.primary,
                                                        ),
                                                      ),
                                                    if (n.isUnread) const SizedBox(width: AppSpacing.xs),
                                                    Expanded(
                                                      child: Text(
                                                        n.type,
                                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                              fontWeight: n.isUnread ? FontWeight.w600 : null,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: AppSpacing.xxs),
                                                Text(
                                                  n.message,
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                ),
                                                const SizedBox(height: AppSpacing.xs),
                                                Text(
                                                  Formatters.relativeTime(n.createdAt),
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
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
      ),
    );
  }
}
