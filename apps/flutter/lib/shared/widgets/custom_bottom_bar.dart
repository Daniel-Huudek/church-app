import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TabData {
  final String key;
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const TabData({
    required this.key,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class TabItem extends StatelessWidget {
  final TabData tab;
  final bool isFocused;
  final bool isDark;
  final VoidCallback onTap;

  const TabItem({
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

class ProfileAvatar extends StatelessWidget {
  final dynamic user;
  final bool isDark;
  final VoidCallback onTap;

  const ProfileAvatar({
    required this.user,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = user?.name as String? ?? '';
    final avatarUrl = user?.avatar as String?;
    final updatedAt = user?.updatedAt as DateTime?;
    final cacheKey = updatedAt?.millisecondsSinceEpoch ?? 0;
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
                child: CachedNetworkImage(
                  imageUrl: '${avatarUrl}?v=$cacheKey',
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _initialsCircle(size, initial),
                  placeholder: (_, __) => _initialsCircle(size, initial),
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

class CustomBottomBar extends ConsumerWidget {
  final bool isDark;
  final dynamic user;
  final VoidCallback onAdminTap;

  const CustomBottomBar({
    required this.isDark,
    required this.user,
    required this.onAdminTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentTab = location.split('/')[1];

    final tabs = [
      TabData(key: '', label: 'Início', icon: Icons.home_outlined, activeIcon: Icons.home),
      TabData(key: 'prayers', label: 'Oração', icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book),
      TabData(key: 'calendar', label: 'Eventos', icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month),
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
                  child: TabItem(
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
              ProfileAvatar(
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
