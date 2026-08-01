import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  _RoleData _roleConfig(String key) {
    switch (key) {
      case 'ADMINISTRADOR':
        return const _RoleData('Administrador', AppColors.error);
      case 'PASTOR':
        return const _RoleData('Pastor', AppColors.primary);
      case 'FINANCEIRO':
        return const _RoleData('Financeiro', AppColors.primary600);
      case 'LIDER':
        return const _RoleData('Líder', AppColors.warning);
      case 'VISITANTE':
        return const _RoleData('Visitante', AppColors.neutral500);
      default:
        return const _RoleData('Membro', AppColors.success);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeState = ref.watch(themeProvider);
    final user = authState.user;
    final isDark = themeState.isDark;

    final bgColor = isDark ? AppColors.darkBg : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final softSurface = isDark ? AppColors.darkCard : Colors.white;

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

    final ministries = (user?.ministries as List?)
            ?.whereType<String>()
            .where((m) => m.trim().isNotEmpty)
            .toList() ??
        const <String>[];
    final hasPhone = user?.phone != null && user!.phone!.trim().isNotEmpty;
    final hasConta = hasPhone || ministries.isNotEmpty;

    const avatarSize = 96.0;

    return Scaffold(
      body: Container(
        color: bgColor,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.bottomNavClearance),
            child: Column(
              children: [
                _IdentityHeader(
                  avatarSize: avatarSize,
                  avatarUrl: user?.avatar,
                  cacheKey: user?.updatedAt.millisecondsSinceEpoch ?? 0,
                  initials: initials,
                  name: name,
                  email: user?.email ?? '',
                  roleLabel: roleData.label,
                  roleColor: roleData.color,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.xl3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _QuickActionsRow(
                        textPrimary: textPrimary,
                        isDark: isDark,
                        onSettings: () => context.push(AppRoutes.settings),
                        onNotifications: () =>
                            context.push(AppRoutes.notifications),
                        onSchedules: () => context.push(AppRoutes.schedules),
                        onPrayers: () => context.go(AppRoutes.prayers),
                      ),
                      if (hasConta) ...[
                        const SizedBox(height: AppSpacing.xl3),
                        Text(
                          'Conta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (hasPhone)
                          _PlainInfoRow(
                            icon: Icons.phone_rounded,
                            label: 'Telefone',
                            value: user!.phone!,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        if (hasPhone && ministries.isNotEmpty)
                          const SizedBox(height: AppSpacing.xl),
                        if (ministries.isNotEmpty) ...[
                          Text(
                            'Ministérios',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ministries
                                .map(
                                  (m) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: softSurface,
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
                        ],
                      ],
                      const SizedBox(height: AppSpacing.xl3),
                      _ThemeRow(
                        isDark: isDark,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        onToggle: () {
                          ref.read(themeProvider.notifier).toggleTheme();
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl4),
                      Center(
                        child: TextButton(
                          onPressed: () async {
                            await ref.read(authProvider.notifier).logout();
                            if (context.mounted) {
                              context.go('/login');
                            }
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                              vertical: AppSpacing.md,
                            ),
                          ),
                          child: const Text(
                            'Sair da Conta',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
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

class _IdentityHeader extends StatelessWidget {
  final double avatarSize;
  final String? avatarUrl;
  final int cacheKey;
  final String initials;
  final String name;
  final String email;
  final String roleLabel;
  final Color roleColor;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  const _IdentityHeader({
    required this.avatarSize,
    required this.avatarUrl,
    required this.cacheKey,
    required this.initials,
    required this.name,
    required this.email,
    required this.roleLabel,
    required this.roleColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    const bandHeight = 168.0;

    return Column(
      children: [
        SizedBox(
          height: topPad + bandHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDark
                          ? const [
                              Color(0xFF0B2A4A),
                              Color(0xFF12121A),
                            ]
                          : const [
                              Color(0xFF66B5FF),
                              Color(0xFF008CFF),
                              Color(0xFFE8F4FF),
                            ],
                      stops: isDark
                          ? const [0.0, 1.0]
                          : const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: -(avatarSize / 2),
                child: Center(
                  child: _ProfileAvatar(
                    size: avatarSize,
                    avatarUrl: avatarUrl,
                    cacheKey: cacheKey,
                    initials: initials,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: avatarSize / 2 + AppSpacing.xl),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            children: [
              Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: textSecondary),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                roleLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: roleColor,
                  decoration: TextDecoration.underline,
                  decorationColor: roleColor.withValues(alpha: 0.45),
                  decorationThickness: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final double size;
  final String? avatarUrl;
  final int cacheKey;
  final String initials;

  const _ProfileAvatar({
    required this.size,
    required this.avatarUrl,
    required this.cacheKey,
    required this.initials,
  });

  Widget _initialsCircle() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.32,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ring = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: avatarUrl != null
            ? CachedNetworkImage(
                imageUrl: '$avatarUrl?v=$cacheKey',
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _initialsCircle(),
                placeholder: (_, __) => _initialsCircle(),
              )
            : _initialsCircle(),
      ),
    );

    return ring;
  }
}

class _QuickActionsRow extends StatelessWidget {
  final Color textPrimary;
  final bool isDark;
  final VoidCallback onSettings;
  final VoidCallback onNotifications;
  final VoidCallback onSchedules;
  final VoidCallback onPrayers;

  const _QuickActionsRow({
    required this.textPrimary,
    required this.isDark,
    required this.onSettings,
    required this.onNotifications,
    required this.onSchedules,
    required this.onPrayers,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.settings_rounded,
        label: 'Configurações',
        color: AppColors.primary,
        onTap: onSettings,
      ),
      _QuickAction(
        icon: Icons.notifications_rounded,
        label: 'Notificações',
        color: AppColors.warning,
        onTap: onNotifications,
      ),
      _QuickAction(
        icon: Icons.event_note_rounded,
        label: 'Escalas',
        color: AppColors.success,
        onTap: onSchedules,
      ),
      _QuickAction(
        icon: Icons.favorite_rounded,
        label: 'Orações',
        color: AppColors.error,
        onTap: onPrayers,
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _QuickActionButton(
              action: actions[i],
              textPrimary: textPrimary,
              isDark: isDark,
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionButton extends StatelessWidget {
  final _QuickAction action;
  final Color textPrimary;
  final bool isDark;

  const _QuickActionButton({
    required this.action,
    required this.textPrimary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: action.color.withValues(alpha: isDark ? 0.18 : 0.12),
                  border: Border.all(
                    color: action.color.withValues(alpha: isDark ? 0.28 : 0.16),
                  ),
                ),
                child: Icon(action.icon, color: action.color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                action.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlainInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color textPrimary;
  final Color textSecondary;

  const _PlainInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeRow extends StatelessWidget {
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onToggle;

  const _ThemeRow({
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tema',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              Text(
                isDark ? 'Escuro' : 'Claro',
                style: TextStyle(fontSize: 13, color: textSecondary),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: isDark,
          activeTrackColor: AppColors.primary.withValues(alpha: 0.45),
          activeColor: AppColors.primary,
          onChanged: (_) => onToggle(),
        ),
      ],
    );
  }
}

class _RoleData {
  final String label;
  final Color color;
  const _RoleData(this.label, this.color);
}
