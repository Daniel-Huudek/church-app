import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_tabs.dart';
import '../../core/utils/formatters.dart';
import '../../core/config/theme/app_spacing.dart';
import '../../core/config/theme/app_colors.dart';

class PrayerFeedScreen extends ConsumerStatefulWidget {
  const PrayerFeedScreen({super.key});

  @override
  ConsumerState<PrayerFeedScreen> createState() => _PrayerFeedScreenState();
}

class _PrayerFeedScreenState extends ConsumerState<PrayerFeedScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Orações')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          AppTabs(
            tabs: ['Feed', 'Minhas'],
            selectedIndex: _selectedTab,
            onTabChanged: (i) => setState(() => _selectedTab = i),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: _selectedTab == 0
                ? _buildFeed()
                : _buildMyPrayers(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeed() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: AppCard(
            onTap: () {},
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppAvatar(
                      name: 'João Silva',
                      size: 36,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'João Silva',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            'há 2h',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const AppBadge(label: 'Urgente', variant: AppBadgeVariant.error),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Senhor, clamamos pela cura do nosso irmão...',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _ActionButton(Icons.favorite_border, '3'),
                    const SizedBox(width: AppSpacing.lg),
                    _ActionButton(Icons.comment_outlined, '5'),
                    const SizedBox(width: AppSpacing.lg),
                    _ActionButton(Icons.share_outlined, ''),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMyPrayers() {
    return const AppEmptyState(
      title: 'Nenhuma oração',
      subtitle: 'Você ainda não criou nenhuma oração',
      icon: Icons.menu_book,
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String count;

  const _ActionButton(this.icon, this.count);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        if (count.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(count, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}
