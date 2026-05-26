import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/formatters.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../members/presentation/providers/member_provider.dart';
import '../../../finance/presentation/providers/finance_provider.dart';
import '../../../prayers/presentation/providers/prayer_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final events = ref.watch(eventListProvider);
    final members = ref.watch(memberListProvider);
    final finance = ref.watch(financeDashboardProvider);
    final prayers = ref.watch(prayerFeedProvider);

    final loading = events.loading || members.loading || finance.loading || prayers.loading;

    if (loading) return _buildSkeleton(isDark);

    return Container(
      color: isDark ? const Color(0xFF0A0A0F) : Colors.white,
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(eventListProvider.notifier).load(),
            ref.read(memberListProvider.notifier).load(),
            ref.read(financeDashboardProvider.notifier).load(),
            ref.read(prayerFeedProvider.notifier).loadFeed(),
          ]);
        },
        color: const Color(0xFF0066CC),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 64, 16, 24),
          children: [
            Text(
              'Igreja Batista',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _StatCard(
                  icon: '📅',
                  value: '${events.events.length}',
                  label: 'Eventos',
                  color: const Color(0xFF008CFF),
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: '👥',
                  value: '${members.members.length}',
                  label: 'Membros',
                  color: const Color(0xFF3B82F6),
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatCard(
                  icon: '🙏',
                  value: '${prayers.prayers.length}',
                  label: 'Orações',
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: '💰',
                  value: finance.dashboard != null
                      ? Formatters.formatCurrency(finance.dashboard!.balance)
                      : 'R\$ 0',
                  label: 'Saldo',
                  color: const Color(0xFFF59E0B),
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF0A0A0F) : Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 64, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 200,
                height: 28,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _skeletonCard(isDark, 100)),
                  const SizedBox(width: 12),
                  Expanded(child: _skeletonCard(isDark, 100)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _skeletonCard(isDark, 100)),
                  const SizedBox(width: 12),
                  Expanded(child: _skeletonCard(isDark, 100)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _skeletonCard(bool isDark, double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
