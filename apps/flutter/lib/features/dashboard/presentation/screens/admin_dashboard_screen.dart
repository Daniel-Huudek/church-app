import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../members/presentation/providers/member_provider.dart';
import '../../../schedules/presentation/providers/schedule_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await Future.wait([
        ref.read(memberListProvider.notifier).load(),
        ref.read(eventListProvider.notifier).load(),
        ref.read(scheduleListProvider.notifier).load(),
      ]);
    });
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      ref.read(memberListProvider.notifier).load(),
      ref.read(eventListProvider.notifier).load(),
      ref.read(scheduleListProvider.notifier).load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authProvider).user;
    final members = ref.watch(memberListProvider);
    final events = ref.watch(eventListProvider);
    final schedules = ref.watch(scheduleListProvider);
    final loading = members.loading || events.loading || schedules.loading;

    final bg = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC);
    final card = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final t1 = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final t2 = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final border = isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);

    return Container(
      color: bg,
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        color: const Color(0xFF008CFF),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 64, 20, 100),
          children: [
            Text('Painel administrativo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: t1)),
            const SizedBox(height: 6),
            Text('Visão geral da igreja', style: TextStyle(color: t2)),
            const SizedBox(height: 20),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Row(
                children: [
                  Expanded(child: _metric('Membros', '${members.data?.length ?? 0}', card, border, t1, t2)),
                  const SizedBox(width: 12),
                  Expanded(child: _metric('Eventos', '${events.data?.length ?? 0}', card, border, t1, t2)),
                  const SizedBox(width: 12),
                  Expanded(child: _metric('Escalas', '${schedules.data?.length ?? 0}', card, border, t1, t2)),
                ],
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (user != null && user.hasAnyRole(['ADMINISTRADOR', 'PASTOR', 'FINANCEIRO']))
                  Expanded(child: _iconButton(
                    icon: Icons.account_balance_rounded,
                    color: const Color(0xFF10B981),
                    label: 'Financeiro',
                    onTap: () => context.go(AppRoutes.finance),
                  )),
                if (user != null && user.hasAnyRole(['ADMINISTRADOR', 'PASTOR', 'LIDER'])) ...[
                  const SizedBox(width: 14),
                  Expanded(child: _iconButton(
                    icon: Icons.people_rounded,
                    color: const Color(0xFFF59E0B),
                    label: 'Membros',
                    onTap: () => context.go(AppRoutes.members),
                  )),
                ],
                if (user != null && user.hasAnyRole(['ADMINISTRADOR', 'PASTOR'])) ...[
                  const SizedBox(width: 14),
                  Expanded(child: _iconButton(
                    icon: Icons.supervised_user_circle_rounded,
                    color: const Color(0xFF8B5CF6),
                    label: 'Usuários',
                    onTap: () => context.go(AppRoutes.users),
                  )),
                ],
              ],
            ),
            if (user != null && user.hasAnyRole(['ADMINISTRADOR', 'PASTOR'])) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _iconButton(
                    icon: Icons.admin_panel_settings_rounded,
                    color: const Color(0xFFEC4899),
                    label: 'Cargos',
                    onTap: () => context.go(AppRoutes.usersRoles),
                  )),
                  const SizedBox(width: 14),
                  Expanded(child: _iconButton(
                    icon: Icons.language_rounded,
                    color: const Color(0xFF008CFF),
                    label: 'Site',
                    onTap: () => context.go(AppRoutes.website),
                  )),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, Color card, Color border, Color t1, Color t2) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: t1)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: t2)),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}
