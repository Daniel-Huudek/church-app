import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../core/config/theme/app_spacing.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/member_model.dart';
import '../providers/member_provider.dart';
import '../utils/member_links.dart';

class MemberDetailScreen extends ConsumerWidget {
  final String id;

  const MemberDetailScreen({super.key, required this.id});

  String _admissionLabel(String? type) {
    switch (type) {
      case 'BATISMO':
        return 'Batismo';
      case 'TRANSFERENCIA':
        return 'Transferência';
      case 'RECONCILIACAO':
        return 'Reconciliação';
      case 'OUTRO':
        return 'Outro';
      default:
        return type ?? '';
    }
  }

  String _formatAddress(MemberAddress address) {
    final line1 = [
      address.street,
      address.number,
    ].whereType<String>().where((e) => e.isNotEmpty).join(', ');
    final cityState = [
      address.city,
      address.state,
    ].whereType<String>().where((e) => e.isNotEmpty).join(' - ');
    final parts = <String>[
      if (line1.isNotEmpty) line1,
      if (address.complement != null && address.complement!.isNotEmpty) address.complement!,
      if (address.neighborhood != null && address.neighborhood!.isNotEmpty) address.neighborhood!,
      if (cityState.isNotEmpty) cityState,
      if (address.zipCode != null && address.zipCode!.isNotEmpty) 'CEP ${address.zipCode}',
    ];
    return parts.join('\n');
  }

  Future<void> _openWhatsApp(BuildContext context, String phone) async {
    final ok = await openExternalUri(whatsAppUri(phone));
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o WhatsApp')),
      );
    }
  }

  Future<void> _openMaps(BuildContext context, MemberAddress address) async {
    final ok = await openExternalUri(
      googleMapsUri(
        street: address.street,
        number: address.number,
        complement: address.complement,
        neighborhood: address.neighborhood,
        city: address.city,
        state: address.state,
        zipCode: address.zipCode,
      ),
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o Google Maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(memberDetailProvider(id));

    if (state.loading && state.member == null) {
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

    if (state.error != null && state.member == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(child: Text('Erro: ${state.error}')),
        ),
      );
    }

    final member = state.member!;
    final secondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      floatingActionButton: _MemberDetailActions(id: id, member: member),
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
                      imageUrl: member.avatar,
                      authenticated: true,
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: secondary),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      alignment: WrapAlignment.center,
                      children: [
                        AppBadge(label: member.role),
                        AppBadge(label: member.status, variant: AppBadgeVariant.info),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (member.phone != null || member.email != null) ...[
                _sectionTitle(context, 'Contato'),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: AppCard(
                    child: Column(
                      children: [
                        if (member.phone != null) ...[
                          _ContactRow(
                            icon: Icons.chat,
                            value: member.phone!,
                            onTap: () => _openWhatsApp(context, member.phone!),
                          ),
                          if (member.email != null) const Divider(),
                        ],
                        if (member.email != null)
                          _ContactRow(
                            icon: Icons.email,
                            value: member.email!,
                            onTap: () async {
                              final uri = Uri(
                                scheme: 'mailto',
                                path: member.email,
                              );
                              final ok = await openExternalUri(uri);
                              if (!ok && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Não foi possível abrir o e-mail')),
                                );
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              _sectionTitle(context, 'Informações pessoais'),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: AppCard(
                  child: Column(
                    children: [
                      if (member.birthDate != null)
                        _InfoItem(label: 'Nascimento', value: Formatters.formatDate(member.birthDate!)),
                      if (member.birthDate != null && member.age.isNotEmpty) const Divider(),
                      if (member.age.isNotEmpty) _InfoItem(label: 'Idade', value: member.age),
                      if (member.gender != null) ...[
                        if (member.birthDate != null || member.age.isNotEmpty) const Divider(),
                        _InfoItem(label: 'Gênero', value: member.gender!),
                      ],
                      if (member.maritalStatus != null) ...[
                        const Divider(),
                        _InfoItem(label: 'Estado civil', value: member.maritalStatus!),
                      ],
                      if (member.occupation != null) ...[
                        const Divider(),
                        _InfoItem(label: 'Profissão', value: member.occupation!),
                      ],
                      if (member.birthDate != null ||
                          member.age.isNotEmpty ||
                          member.gender != null ||
                          member.maritalStatus != null ||
                          member.occupation != null)
                        const Divider(),
                      _InfoItem(
                        label: 'Conta do app',
                        value: member.userId != null ? 'Vinculada (pode confirmar escalas)' : 'Não vinculada',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _sectionTitle(context, 'Vida espiritual'),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: AppCard(
                  child: Column(
                    children: [
                      _InfoItem(label: 'Batizado', value: member.isBaptized ? 'Sim' : 'Não'),
                      if (member.baptismDate != null) ...[
                        const Divider(),
                        _InfoItem(label: 'Data do batismo', value: Formatters.formatDate(member.baptismDate!)),
                      ],
                      if (member.baptismChurch != null) ...[
                        const Divider(),
                        _InfoItem(label: 'Igreja do batismo', value: member.baptismChurch!),
                      ],
                      if (member.conversionDate != null) ...[
                        const Divider(),
                        _InfoItem(label: 'Conversão', value: Formatters.formatDate(member.conversionDate!)),
                      ],
                      if (member.admissionDate != null) ...[
                        const Divider(),
                        _InfoItem(label: 'Admissão', value: Formatters.formatDate(member.admissionDate!)),
                      ],
                      if (member.admissionType != null) ...[
                        const Divider(),
                        _InfoItem(label: 'Tipo de admissão', value: _admissionLabel(member.admissionType)),
                      ],
                      if (member.notes != null && member.notes!.isNotEmpty) ...[
                        const Divider(),
                        _InfoItem(label: 'Observações', value: member.notes!),
                      ],
                    ],
                  ),
                ),
              ),
              if (member.ministries.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                _sectionTitle(context, 'Ministérios'),
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
              if (member.address?.hasAny == true) ...[
                const SizedBox(height: AppSpacing.xl),
                _sectionTitle(context, 'Endereço'),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    onTap: () => _openMaps(context, member.address!),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.map_outlined, size: 20, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              _formatAddress(member.address!),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 20),
                        ],
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

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _MemberDetailActions extends ConsumerWidget {
  final String id;
  final MemberModel member;

  const _MemberDetailActions({required this.id, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final canWrite = user?.hasPermission('members_write') == true;
    final canDelete = user?.hasPermission('members_delete') == true;
    if (!canWrite && !canDelete) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (canDelete)
          FloatingActionButton.small(
            heroTag: 'member-delete',
            backgroundColor: AppColors.error,
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Excluir membro'),
                  content: Text('Remover ${member.name} do cadastro?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
                  ],
                ),
              );
              if (ok != true || !context.mounted) return;
              try {
                await ref.read(memberListProvider.notifier).delete(id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Membro excluído')));
                context.go(AppRoutes.members);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
              }
            },
            child: const Icon(Icons.delete_outline),
          ),
        if (canDelete && canWrite) const SizedBox(height: 12),
        if (canWrite)
          FloatingActionButton(
            heroTag: 'member-edit',
            onPressed: () async {
              await context.push(AppRoutes.membersEdit(id));
              ref.read(memberDetailProvider(id).notifier).load();
            },
            child: const Icon(Icons.edit),
          ),
      ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
