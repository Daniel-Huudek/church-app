import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/auth_provider.dart';
import '../../core/config/theme/app_colors.dart';

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

    return Scaffold(
      body: Stack(
        children: [
          widget.child,
          if (_drawerVisible)
            _DrawerOverlay(
              isDark: isDark,
              onClose: () => setState(() => _drawerVisible = false),
            ),
        ],
      ),
      bottomNavigationBar: widget.hideNav
          ? null
          : _CustomBottomBar(
              isDark: isDark,
              user: user,
              onAdminTap: () => setState(() => _drawerVisible = !_drawerVisible),
            ),
    );
  }
}

class _DrawerOverlay extends StatefulWidget {
  final bool isDark;
  final VoidCallback onClose;

  const _DrawerOverlay({required this.isDark, required this.onClose});

  @override
  State<_DrawerOverlay> createState() => _DrawerOverlayState();
}

class _DrawerOverlayState extends State<_DrawerOverlay>
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

class _CustomBottomBar extends ConsumerWidget {
  final bool isDark;
  final dynamic user;
  final VoidCallback onAdminTap;

  const _CustomBottomBar({
    required this.isDark,
    required this.user,
    required this.onAdminTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentTab = location.split('/')[1];

    final tabs = [
      _TabData(key: '', label: 'Início', icon: Icons.home_outlined, activeIcon: Icons.home),
      _TabData(key: 'prayers', label: 'Oração', icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book),
      _TabData(key: 'calendar', label: 'Eventos', icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xEF161622)
                : const Color(0xEFFFFFFF),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              for (final tab in tabs) ...[
                Expanded(
                  child: _TabItem(
                    tab: tab,
                    isFocused: tab.key == currentTab,
                    isDark: isDark,
                    onTap: () {
                      if (tab.key == 'prayers') {
                        context.go('/prayers');
                      } else if (!(tab.key == currentTab)) {
                        context.go('/${tab.key}');
                      }
                    },
                  ),
                ),
              ],
              const SizedBox(width: 4),
              _ProfileAvatar(
                user: user,
                isDark: isDark,
                onTap: () => context.go('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabData {
  final String key;
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _TabData({
    required this.key,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class _TabItem extends StatelessWidget {
  final _TabData tab;
  final bool isFocused;
  final bool isDark;
  final VoidCallback onTap;

  const _TabItem({
    required this.tab,
    required this.isFocused,
    required this.isDark,
    required this.onTap,
  });

  Color get _activeColor => tab.key == '' ? const Color(0xFF9CA3AF) : const Color(0xFF008CFF);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isFocused
              ? (isDark
                  ? const Color(0x266B7280)
                  : const Color(0x269CA3AF))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            tab.key == ''
                ? Image.asset(
                    'assets/images/home.png',
                    width: 25,
                    height: 25,
                    color: isFocused ? _activeColor : const Color(0xFF9CA3AF),
                  )
                : tab.key == 'prayers'
                    ? SvgPicture.asset(
                        'assets/icons/oracao.svg',
                        width: 25,
                        height: 25,
                        colorFilter: ColorFilter.mode(
                          isFocused ? _activeColor : const Color(0xFF9CA3AF),
                          BlendMode.srcIn,
                        ),
                      )
                    : Icon(
                        isFocused ? tab.activeIcon : tab.icon,
                        size: 25,
                        color: isFocused ? _activeColor : const Color(0xFF9CA3AF),
                      ),
            if (isFocused) ...[
              const SizedBox(width: 8),
              Text(
                tab.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _activeColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final dynamic user;
  final bool isDark;
  final VoidCallback onTap;

  const _ProfileAvatar({
    required this.user,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = user?.name as String? ?? '';
    final avatarUrl = user?.avatar as String?;
    final size = 36.0;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.only(left: 4),
        child: avatarUrl != null
            ? ClipOval(
                child: Image.network(
                  avatarUrl,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _initialsCircle(size, initial),
                ),
              )
            : _initialsCircle(size, initial),
      ),
    );
  }

  Widget _initialsCircle(double size, String initial) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF008CFF),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
