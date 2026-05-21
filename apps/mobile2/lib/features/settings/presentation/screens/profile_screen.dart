import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/theme_provider.dart';
import '../../../../core/config/theme/app_spacing.dart';
import '../../../../core/config/theme/app_colors.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeState = ref.watch(themeProvider);
    final user = authState.user;
    final isDark = themeState.isDark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              // User info
              const SizedBox(height: AppSpacing.xl),
              AppAvatar(
                name: user?.name ?? 'Usuário',
                imageUrl: user?.avatar,
                size: 80,
                showBorder: true,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                user?.name ?? 'Usuário',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                user?.email ?? '',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.xl2),

              // Menu items
              _MenuItem(
                icon: Icons.person_outline,
                label: 'Editar Perfil',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.settings_outlined,
                label: 'Configurações',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.notifications_outlined,
                label: 'Notificações',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.calendar_today,
                label: 'Minhas Escalas',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.event,
                label: 'Meus Eventos',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.menu_book,
                label: 'Minhas Orações',
                onTap: () {},
              ),

              const Divider(height: AppSpacing.xl2),

              // Theme toggle
              _MenuItem(
                icon: isDark ? Icons.light_mode : Icons.dark_mode,
                label: isDark ? 'Modo Claro' : 'Modo Escuro',
                trailing: Switch(
                  value: isDark,
                  onChanged: (_) =>
                      ref.read(themeProvider.notifier).toggleTheme(),
                ),
                onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
              ),

              const Divider(height: AppSpacing.xl2),

              // Logout
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  icon: const Icon(Icons.logout, color: AppColors.error),
                  label: const Text(
                    'Sair',
                    style: TextStyle(color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl2),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ),
            trailing ??
                const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}
