import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
                  ? const Color(0xFF12121A)
                  : Colors.white,
              padding: const EdgeInsets.only(top: 60),
              child: ListView(
                children: [
                  _drawerItem(
                    icon: '📊',
                    label: 'Dashboard',
                    onTap: () {
                      context.go('/');
                      widget.onClose();
                    },
                  ),
                  _drawerItem(
                    icon: '📅',
                    label: 'Eventos',
                    onTap: () {
                      context.go('/calendar');
                      widget.onClose();
                    },
                  ),
                  _drawerItem(
                    icon: '🙏',
                    label: 'Oração',
                    onTap: () {
                      context.go('/prayers');
                      widget.onClose();
                    },
                  ),
                  _drawerItem(
                    icon: '🎵',
                    label: 'Louvor',
                    onTap: () {
                      context.go('/worship');
                      widget.onClose();
                    },
                  ),
                  _drawerItem(
                    icon: '📋',
                    label: 'Escalas',
                    onTap: () {
                      context.go('/schedules');
                      widget.onClose();
                    },
                  ),
                  _drawerItem(
                    icon: '👥',
                    label: 'Membros',
                    onTap: () {
                      context.go('/members');
                      widget.onClose();
                    },
                  ),
                  _drawerItem(
                    icon: '💰',
                    label: 'Finanças',
                    onTap: () {
                      context.go('/finance');
                      widget.onClose();
                    },
                  ),
                  _drawerItem(
                    icon: '💬',
                    label: 'Chat',
                    onTap: () {
                      context.go('/chat');
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
    required String icon,
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
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: widget.isDark
                      ? const Color(0xFFF9FAFB)
                      : const Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
