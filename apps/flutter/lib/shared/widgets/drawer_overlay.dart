import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/theme/app_colors.dart';
import '../../core/router/app_routes.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class DrawerOverlay extends ConsumerStatefulWidget {
  final bool isDark;
  final VoidCallback onClose;

  const DrawerOverlay({required this.isDark, required this.onClose});

  @override
  ConsumerState<DrawerOverlay> createState() => _DrawerOverlayState();
}

class _DrawerOverlayState extends ConsumerState<DrawerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..forward();
    _slideAnim = Tween<double>(begin: -230, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(String route) {
    context.go(route);
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return GestureDetector(
      onTap: () {
        _controller.reverse().then((_) {
          widget.onClose();
        });
      },
      child: Container(
        color: widget.isDark
            ? Colors.black.withValues(alpha: 0.6)
            : Colors.black.withValues(alpha: 0.3),
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedBuilder(
            animation: _slideAnim,
            builder: (context, child) => Transform.translate(
              offset: Offset(_slideAnim.value, 0),
              child: child,
            ),
            child: Container(
              width: 230,
              color: widget.isDark
                  ? AppColors.darkSurface
                  : Colors.white,
              padding: const EdgeInsets.only(top: 60),
              child: ListView(
                children: [
                  _drawerItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    onTap: () => _go(AppRoutes.home),
                  ),
                  _drawerItem(
                    icon: Icons.calendar_month_rounded,
                    label: 'Eventos',
                    onTap: () => _go(AppRoutes.calendar),
                  ),
                  _drawerItem(
                    icon: Icons.menu_book_rounded,
                    label: 'Oração',
                    onTap: () => _go(AppRoutes.prayers),
                  ),
                  _drawerItem(
                    icon: Icons.menu_book_rounded,
                    label: 'Bíblia',
                    onTap: () => _go(AppRoutes.bible),
                  ),
                  _drawerItem(
                    icon: Icons.music_note_rounded,
                    label: 'Louvor',
                    onTap: () => _go(AppRoutes.worship),
                  ),
                  if (_canSeeDeacons(user))
                    _drawerItem(
                      icon: Icons.volunteer_activism_rounded,
                      label: 'Diáconos',
                      onTap: () => _go(AppRoutes.deacons),
                    ),
                  _drawerItem(
                    icon: Icons.assignment_rounded,
                    label: 'Escalas',
                    onTap: () => _go(AppRoutes.schedules),
                  ),
                  _drawerItem(
                    icon: Icons.cake_rounded,
                    label: 'Aniversariantes',
                    onTap: () => _go(AppRoutes.birthdays),
                  ),
                  if (user?.hasPermission('members_read') == true)
                    _drawerItem(
                      icon: Icons.people_rounded,
                      label: 'Membros',
                      onTap: () => _go(AppRoutes.members),
                    ),
                  if (user?.hasPermission('finance_read') == true)
                    _drawerItem(
                      icon: Icons.attach_money_rounded,
                      label: 'Finanças',
                      onTap: () => _go(AppRoutes.finance),
                    ),
                  _drawerItem(
                    icon: Icons.chat_rounded,
                    label: 'Chat',
                    onTap: () => _go(AppRoutes.chat),
                  ),
                  if (user?.hasPermission('users_read') == true)
                    _drawerItem(
                      icon: Icons.manage_accounts_rounded,
                      label: 'Usuários',
                      onTap: () => _go(AppRoutes.users),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _canSeeDeacons(UserModel? user) {
    if (user == null) return false;
    return user.hasAnyRole(['ADMINISTRADOR', 'PASTOR', 'DIACONO', 'LIDER_DIACONOS']);
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 22, color: widget.isDark ? AppColors.darkText : AppColors.lightText),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: widget.isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
