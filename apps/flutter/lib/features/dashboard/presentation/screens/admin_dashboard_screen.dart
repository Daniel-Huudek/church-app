import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/providers/auth_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authProvider).user;

    if (_loading) {
      return _buildSkeleton(isDark);
    }

    return Container(
      color: isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC),
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        color: const Color(0xFF008CFF),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 64, 20, 100),
          children: [
            const SizedBox(height: 24),
            Row(
              children: [
                if (user != null && user.hasAnyRole(['ADMINISTRADOR', 'PASTOR', 'FINANCEIRO']))
                  Expanded(child: _iconButton(
                    icon: Icons.account_balance_rounded,
                    color: const Color(0xFF10B981),
                    label: 'Financeiro',
                    onTap: () => context.go('/finance'),
                  )),
                if (user != null && user.hasAnyRole(['ADMINISTRADOR', 'PASTOR', 'LIDER'])) ...[
                  const SizedBox(width: 14),
                  Expanded(child: _iconButton(
                    icon: Icons.people_rounded,
                    color: const Color(0xFFF59E0B),
                    label: 'Membros',
                    onTap: () => context.go('/members'),
                  )),
                ],
                if (user != null && user.hasAnyRole(['ADMINISTRADOR', 'PASTOR'])) ...[
                  const SizedBox(width: 14),
                  Expanded(child: _iconButton(
                    icon: Icons.supervised_user_circle_rounded,
                    color: const Color(0xFF8B5CF6),
                    label: 'Usuários',
                    onTap: () => context.go('/users'),
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
                    onTap: () => context.go('/users/roles'),
                  )),
                ],
              ),
            ],
          ],
        ),
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
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
          padding: const EdgeInsets.fromLTRB(20, 64, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              _skeletonCard(isDark, 80),
              const SizedBox(height: 14),
              _skeletonCard(isDark, 80),
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
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
