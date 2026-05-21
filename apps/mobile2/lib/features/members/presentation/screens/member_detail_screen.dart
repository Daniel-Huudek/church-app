import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../core/config/theme/app_spacing.dart';
import '../../../core/config/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';

class MemberDetailScreen extends ConsumerWidget {
  final String id;

  const MemberDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppHeader(title: 'Membro'),
              // Profile header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    const AppAvatar(
                      name: 'Maria Santos',
                      size: 80,
                      showBorder: true,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Maria Santos',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'maria@igreja.com',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const AppBadge(label: 'Membro'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Contact info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  'Contato',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: AppCard(
                  child: Column(
                    children: [
                      _ContactRow(
                        icon: Icons.phone,
                        value: '(14) 99999-8888',
                        onTap: () {},
                      ),
                      const Divider(),
                      _ContactRow(
                        icon: Icons.email,
                        value: 'maria@igreja.com',
                        onTap: () {},
                      ),
                      const Divider(),
                      _ContactRow(
                        icon: Icons.location_on,
                        value: 'Av. Brasil, 123 - Centro',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Personal info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  'Informações Pessoais',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: AppCard(
                  child: Column(
                    children: [
                      _InfoItem(label: 'Data de Nascimento', value: '15/03/1990'),
                      const Divider(),
                      _InfoItem(label: 'Estado Civil', value: 'Casado(a)'),
                      const Divider(),
                      _InfoItem(label: 'Batismo', value: '12/06/2005'),
                      const Divider(),
                      _InfoItem(label: 'Conversão', value: '10/01/2005'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Ministries
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  'Ministérios',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: Text(
                        'Nenhum ministério',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing._2xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final VoidCallback onTap;

  const _ContactRow({
    required this.icon,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(value)),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
