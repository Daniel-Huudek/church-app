import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/auth_provider.dart';
import '../../core/config/theme/app_colors.dart';
import 'drawer_overlay.dart';
import 'custom_bottom_bar.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  final bool hideNav;

  const MainShell({super.key, required this.child, this.hideNav = false});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  bool _drawerVisible = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : Colors.white;
    final currentRoute = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: Stack(
        children: [
          widget.child,
          if (_drawerVisible)
            DrawerOverlay(
              isDark: isDark,
              onClose: () => setState(() => _drawerVisible = false),
            ),
          if (user != null && !currentRoute.startsWith('/worship') && !currentRoute.startsWith('/finance') && currentRoute != '/dashboard' && user.hasAnyRole(['ADMINISTRADOR', 'PASTOR', 'LIDER', 'LIDER_LOUVOR', 'LOUVOR', 'FINANCEIRO']))
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (user.hasAnyRole(['ADMINISTRADOR', 'PASTOR', 'LIDER', 'LIDER_LOUVOR', 'LOUVOR']))
                      _sideButton(
                        icon: Icons.music_note_rounded,
                        label: 'Louvor',
                        grad: const [Color(0xFF008CFF), Color(0xFF0066CC)],
                        onTap: () => context.go('/worship'),
                      ),
                    if (user.hasAnyRole(['ADMINISTRADOR', 'PASTOR', 'FINANCEIRO'])) ...[
                      const SizedBox(height: 10),
                      _sideButton(
                        icon: Icons.dashboard_rounded,
                        label: '',
                        grad: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                        onTap: () => context.go('/dashboard'),
                        height: 56,
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: widget.hideNav
          ? null
          : CustomBottomBar(
              isDark: isDark,
              user: user,
              onAdminTap: () => setState(() => _drawerVisible = !_drawerVisible),
            ),
    );
  }

  Widget _sideButton({
    required IconData icon,
    required String label,
    required List<Color> grad,
    required VoidCallback onTap,
    double height = 100,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: grad,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: grad.first.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(4, 0),
            ),
          ],
        ),
        child: label.isEmpty
            ? Icon(icon, color: Colors.white, size: 26)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 26),
                  const SizedBox(height: 6),
                  Text(label, style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  )),
                ],
              ),
      ),
    );
  }
}
