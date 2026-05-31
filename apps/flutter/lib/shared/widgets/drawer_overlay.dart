import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/theme/app_colors.dart';
import '../../core/router/app_routes.dart';

class DrawerOverlay extends StatefulWidget {
  final bool isDark;
  final VoidCallback onClose;

  const DrawerOverlay({required this.isDark, required this.onClose});

  @override
  State<DrawerOverlay> createState() => _DrawerOverlayState();
}

class _DrawerOverlayState extends State<DrawerOverlay>
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

  @override
  Widget build(BuildContext context) {
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
                    onTap: () {
                      context.go(AppRoutes.home);
                      widget.onClose();
                    },
                  ),
                  _drawerItem(
                    icon: Icons.calendar_month_rounded,
                    label: 'Eventos',
                    onTap: () {
                      context.go(AppRoutes.calendar);
                      widget.onClose();
                    },
                  ),
                  _drawerItem(
                    icon: Icons.menu_book_rounded,
                    label: 'Oração',
                    onTap: () {
                      context.go(AppRoutes.prayers);
                      widget.onClose();
                    },
                  ),
                  _drawerItem(
                    icon: Icons.menu_book_rounded,
                    label: 'Bíblia',
                    onTap: () {
                      context.go(AppRoutes.bible);
                      widget.onClose();
                    },
                  ),
                  _drawerItem(
                    icon: Icons.music_note_rounded,
                    label: 'Louvor',
                    onTap: () {
                      context.go(AppRoutes.worship);
                      widget.onClose();
                    },
                  ),
                  _drawerItem(
                    icon: Icons.assignment_rounded,
                    label: 'Escalas',
                    onTap: () {
                      context.go(AppRoutes.schedules);
                      widget.onClose();
                    },
                  ),
                  _drawerItem(
                    icon: Icons.people_rounded,
                    label: 'Membros',
                    onTap: () {
                      context.go(AppRoutes.members);
                      widget.onClose();
                    },
                  ),
                  _drawerItem(
                    icon: Icons.attach_money_rounded,
                    label: 'Finanças',
                    onTap: () {
                      context.go(AppRoutes.finance);
                      widget.onClose();
                    },
                  ),
                  _drawerItem(
                    icon: Icons.chat_rounded,
                    label: 'Chat',
                    onTap: () {
                      context.go(AppRoutes.chat);
                      widget.onClose();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
                  fontSize: 14,
                  color: widget.isDark
                      ? AppColors.darkText
                      : AppColors.lightText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
