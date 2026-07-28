import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/theme_provider.dart';
import '../widgets/menu_section.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  _RoleData _roleConfig(String key) {
    switch (key) {
      case 'ADMINISTRADOR':
        return const _RoleData('Administrador', AppColors.error, Icons.shield_rounded);
      case 'PASTOR':
        return const _RoleData('Pastor', AppColors.primary, Icons.auto_stories_rounded);
      case 'FINANCEIRO':
        return const _RoleData('Financeiro', AppColors.primary600, Icons.account_balance_wallet_rounded);
      case 'LIDER':
        return const _RoleData('Líder', AppColors.warning, Icons.star_rounded);
      case 'VISITANTE':
        return const _RoleData('Visitante', AppColors.neutral500, Icons.person_outline_rounded);
      default:
        return const _RoleData('Membro', AppColors.success, Icons.person_rounded);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeState = ref.watch(themeProvider);
    final user = authState.user;
    final isDark = themeState.isDark;

    final bgColor = isDark ? AppColors.darkBg : AppColors.lightSurface;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final name = user?.name ?? 'Usuário';
    final initials = name
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0])
        .join()
        .toUpperCase();
    final roleKey = user?.role ?? 'MEMBRO';
    final roleData = _roleConfig(roleKey);

    const avatarSize = 80.0;

    Widget avatarCircle(String initials) {
      return Container(
        width: avatarSize,
        height: avatarSize,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }

    Widget avatar() {
      if (user?.avatar != null) {
        final cacheKey = user?.updatedAt.millisecondsSinceEpoch ?? 0;
        return Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: '${user!.avatar!}?v=$cacheKey',
              width: avatarSize,
              height: avatarSize,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => avatarCircle(initials),
              placeholder: (_, __) => avatarCircle(initials),
            ),
          ),
        );
      }
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: avatarCircle(initials),
      );
    }

    return Scaffold(
      body: Container(
        color: bgColor,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.bottomNavClearance),
            child: Column(
              children: [
                Container(
                  height: 112,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        bottom: -40,
                        left: 0,
                        right: 0,
                        child: Center(child: avatar()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 52),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Column(
                    children: [
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: textSecondary),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: roleData.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(roleData.icon, size: 14, color: roleData.color),
                            const SizedBox(width: 6),
                            Text(
                              roleData.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: roleData.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      if (user?.phone != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.phone_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Telefone',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textSecondary,
                                    ),
                                  ),
                                  Text(
                                    user!.phone!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      if (user?.ministries != null &&
                          (user!.ministries as List).isNotEmpty) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Ministérios',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (user.ministries as List)
                                .whereType<String>()
                                .map(
                                  (m) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cardBg,
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusFull,
                                      ),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: Text(
                                      m,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                      MenuSection(
                        title: 'Atalhos',
                        cardBg: cardBg,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        borderColor: borderColor,
                        items: const [
                          MenuItemData(
                            icon: Icons.settings_rounded,
                            label: 'Configurações',
                            color: AppColors.primary,
                          ),
                          MenuItemData(
                            icon: Icons.notifications_rounded,
                            label: 'Notificações',
                            color: AppColors.warning,
                          ),
                          MenuItemData(
                            icon: Icons.event_note_rounded,
                            label: 'Minhas Escalas',
                            color: AppColors.success,
                          ),
                          MenuItemData(
                            icon: Icons.calendar_month_rounded,
                            label: 'Meus Eventos',
                            color: AppColors.primary600,
                          ),
                          MenuItemData(
                            icon: Icons.favorite_rounded,
                            label: 'Minhas Orações',
                            color: AppColors.error,
                          ),
                        ],
                        onItemTap: (index) {
                          switch (index) {
                            case 0:
                              context.push(AppRoutes.settings);
                              break;
                            case 1:
                              context.push(AppRoutes.notifications);
                              break;
                            case 2:
                              context.push(AppRoutes.schedules);
                              break;
                            case 3:
                              context.go(AppRoutes.calendar);
                              break;
                            case 4:
                              context.go(AppRoutes.prayers);
                              break;
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      MenuSection(
                        title: 'Preferências',
                        cardBg: cardBg,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        borderColor: borderColor,
                        items: [
                          MenuItemData(
                            icon: isDark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            label: 'Tema',
                            color: AppColors.primary,
                            trailing: Text(
                              isDark ? 'Escuro' : 'Claro',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                        onItemTap: (_) {
                          ref.read(themeProvider.notifier).toggleTheme();
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            await ref.read(authProvider.notifier).logout();
                            if (context.mounted) {
                              context.go('/login');
                            }
                          },
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                          child: Ink(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusLg),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.logout_rounded,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Sair da Conta',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleData {
  final String label;
  final Color color;
  final IconData icon;
  const _RoleData(this.label, this.color, this.icon);
}
