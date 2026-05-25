import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../core/config/theme/app_spacing.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/member_provider.dart';

class MemberDetailScreen extends ConsumerWidget {
  final String id;

  const MemberDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(memberDetailProvider(id));

    if (state.loading) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Carregando...', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      );
    }

    if (state.error != null) {
      return Scaffold(
        body: SafeArea(
          child: Center(child: Text('Erro: ${state.error}')),
        ),
      );
    }

    final member = state.member!;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text('← Voltar', style: TextStyle(fontSize: 16, color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    AppAvatar(
                      name: member.name,
                      size: 80,
                      showBorder: true,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      member.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (member.email != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        member.email!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    AppBadge(label: member.role),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (member.phone != null || member.email != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Text('Contato', style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: AppCard(
                    child: Column(
                      children: [
                        if (member.phone != null) ...[
                          _ContactRow(icon: Icons.phone, value: member.phone!, onTap: () {}),
                          const Divider(),
                        ],
                        if (member.email != null)
                          _ContactRow(icon: Icons.email, value: member.email!, onTap: () {}),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text('Informações Pessoais', style: Theme.of(context).textTheme.titleMedium),
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: AppCard(
                  child: Column(
                    children: [
                      if (member.birthDate != null)
                        _InfoItem(label: 'Data de Nascimento', value: Formatters.formatDate(member.birthDate!)),
                      if (member.birthDate != null) const Divider(),
                      if (member.maritalStatus != null)
                        _InfoItem(label: 'Estado Civil', value: member.maritalStatus!),
                      if (member.maritalStatus != null) const Divider(),
                      if (member.baptismDate != null)
                        _InfoItem(label: 'Batismo', value: Formatters.formatDate(member.baptismDate!)),
                      if (member.baptismDate != null) const Divider(),
                      if (member.conversionDate != null)
                        _InfoItem(label: 'Conversão', value: Formatters.formatDate(member.conversionDate!)),
                    ],
                  ),
                ),
              ),
              if (member.ministries.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Text('Ministérios', style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: member.ministries
                            .map((m) => AppBadge(label: m, variant: AppBadgeVariant.info))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl2),
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

  const _ContactRow({required this.icon, required this.value, required this.onTap});

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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
