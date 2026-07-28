import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/config/theme/app_colors.dart';

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

  Color get _activeColor => tab.key == '' ? AppColors.neutral400 : AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isFocused
              ? (isDark
                  ? AppColors.primary.withValues(alpha: 0.16)
                  : AppColors.primary.withValues(alpha: 0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            tab.key == ''
                ? Image.asset(
                    'assets/images/home.png',
                    width: 22,
                    height: 22,
                    color: isFocused ? _activeColor : AppColors.neutral400,
                  )
                : tab.key == 'prayers'
                    ? SvgPicture.asset(
                        'assets/icons/oracao.svg',
                        width: 22,
                        height: 22,
                        colorFilter: ColorFilter.mode(
                          isFocused ? _activeColor : AppColors.neutral400,
                          BlendMode.srcIn,
                        ),
                      )
                    : Icon(
                        isFocused ? tab.activeIcon : tab.icon,
                        size: 22,
                        color: isFocused ? _activeColor : AppColors.neutral400,
                      ),
            const SizedBox(height: 4),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isFocused ? _activeColor : AppColors.neutral400,
              ),
            ),
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
        color: AppColors.primary,
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
      TabData(key: 'bible', label: 'Bíblia', icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book),
      TabData(key: 'prayers', label: 'Oração', icon: Icons.whatshot_outlined, activeIcon: Icons.whatshot),
      TabData(key: 'calendar', label: 'Eventos', icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
          decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurface.withValues(alpha: 0.94)
              : Colors.white.withValues(alpha: 0.94),
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
                      } else if (tab.key == 'bible') {
                        context.go('/bible');
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
