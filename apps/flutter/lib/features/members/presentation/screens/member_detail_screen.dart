import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      if (address.complement != null && address.complement!.isNotEmpty)
        address.complement!,
      if (address.neighborhood != null && address.neighborhood!.isNotEmpty)
        address.neighborhood!,
      if (cityState.isNotEmpty) cityState,
      if (address.zipCode != null && address.zipCode!.isNotEmpty)
        'CEP ${address.zipCode}',
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
    final ok = await openInBrowser(
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

  Future<void> _callPhone(BuildContext context, String phone) async {
    final ok = await openExternalUri(Uri(scheme: 'tel', path: phone));
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível iniciar a ligação')),
      );
    }
  }

  Future<void> _openEmail(BuildContext context, String email) async {
    final ok = await openExternalUri(Uri(scheme: 'mailto', path: email));
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o e-mail')),
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
                Text('Carregando...',
                    style: Theme.of(context).textTheme.bodyMedium),
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
    final primary = isDark ? AppColors.darkText : const Color(0xFF17233B);
    final secondary =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF667085);
    final background = isDark ? AppColors.darkBg : const Color(0xFFF5F6F8);
    final card = isDark ? AppColors.darkCard : Colors.white;
    final border = isDark ? AppColors.darkBorder : const Color(0xFFE1E5EA);

    return Scaffold(
      backgroundColor: background,
      floatingActionButton: _MemberDetailActions(id: id, member: member),
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_rounded, color: primary),
        ),
        title: Text(
          'Perfil do membro',
          style: TextStyle(color: primary, fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(memberDetailProvider(id).notifier).load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
          children: [
            _profileDashboardHeader(
              context,
              member,
              primary,
              secondary,
              card,
              border,
            ),
            const SizedBox(height: 16),
            _quickActions(context, member, card, border, secondary),
            const SizedBox(height: 22),
            _sectionTitle(context, 'Visão geral'),
            const SizedBox(height: 10),
            _overviewGrid(member, primary, secondary, card, border),
            if (member.phone != null || member.email != null) ...[
              const SizedBox(height: 22),
              _sectionTitle(context, 'Contato'),
              const SizedBox(height: 10),
              _professionalCard(
                card: card,
                border: border,
                child: Column(
                  children: [
                    if (member.phone != null)
                      _InfoItem(label: 'Telefone', value: member.phone!),
                    if (member.phone != null && member.email != null)
                      Divider(color: border),
                    if (member.email != null)
                      _InfoItem(label: 'E-mail', value: member.email!),
                    if (member.phone != null || member.email != null)
                      Divider(color: border),
                    _InfoItem(
                      label: 'Conta do app',
                      value:
                          member.userId != null ? 'Vinculada' : 'Não vinculada',
                    ),
                  ],
                ),
              ),
            ],
            if (member.ministries.isNotEmpty) ...[
              const SizedBox(height: 22),
              _sectionTitle(context, 'Ministérios'),
              const SizedBox(height: 10),
              _professionalCard(
                card: card,
                border: border,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: member.ministries
                      .map(
                        (ministry) => AppBadge(
                          label: ministry,
                          variant: AppBadgeVariant.info,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 22),
            _sectionTitle(context, 'Vida na igreja'),
            const SizedBox(height: 10),
            _churchTimeline(member, primary, secondary, card, border),
            if (member.address?.hasAny == true) ...[
              const SizedBox(height: 22),
              _sectionTitle(context, 'Endereço'),
              const SizedBox(height: 10),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openMaps(context, member.address!),
                  borderRadius: BorderRadius.circular(16),
                  child: _professionalCard(
                    card: card,
                    border: border,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _formatAddress(member.address!),
                            style: TextStyle(
                              color: primary,
                              height: 1.45,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.open_in_new_rounded,
                          size: 18,
                          color: secondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            if (member.notes?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 22),
              _sectionTitle(context, 'Observações'),
              const SizedBox(height: 10),
              _professionalCard(
                card: card,
                border: border,
                child: Text(
                  member.notes!.trim(),
                  style: TextStyle(color: secondary, height: 1.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkText
                : const Color(0xFF17233B),
          ),
    );
  }

  Widget _profileDashboardHeader(
    BuildContext context,
    MemberModel member,
    Color primary,
    Color secondary,
    Color card,
    Color border,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppAvatar(
            name: member.name,
            imageUrl: member.avatar,
            authenticated: true,
            size: 76,
            showBorder: true,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: primary,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                ),
                if (member.nickname?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    member.nickname!.trim(),
                    style: TextStyle(color: secondary, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  children: [
                    AppBadge(label: member.role),
                    AppBadge(
                      label: member.status,
                      variant: AppBadgeVariant.info,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActions(
    BuildContext context,
    MemberModel member,
    Color card,
    Color border,
    Color secondary,
  ) {
    final actions = <({IconData icon, String label, VoidCallback? onTap})>[
      (
        icon: Icons.chat_rounded,
        label: 'WhatsApp',
        onTap: member.phone == null
            ? null
            : () => _openWhatsApp(context, member.phone!),
      ),
      (
        icon: Icons.phone_rounded,
        label: 'Ligar',
        onTap: member.phone == null
            ? null
            : () => _callPhone(context, member.phone!),
      ),
      (
        icon: Icons.email_rounded,
        label: 'E-mail',
        onTap: member.email == null
            ? null
            : () => _openEmail(context, member.email!),
      ),
      (
        icon: Icons.map_rounded,
        label: 'Mapa',
        onTap: member.address?.hasAny == true
            ? () => _openMaps(context, member.address!)
            : null,
      ),
    ];
    return Row(
      children: actions.map((action) {
        final enabled = action.onTap != null;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: action != actions.last ? 8 : 0,
            ),
            child: InkWell(
              onTap: action.onTap,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: Column(
                  children: [
                    Icon(
                      action.icon,
                      color: enabled
                          ? AppColors.primary
                          : secondary.withValues(alpha: 0.45),
                      size: 21,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      action.label,
                      style: TextStyle(
                        color: enabled
                            ? secondary
                            : secondary.withValues(alpha: 0.45),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _overviewGrid(
    MemberModel member,
    Color primary,
    Color secondary,
    Color card,
    Color border,
  ) {
    final items = <(String, String, IconData)>[
      ('Idade', member.age.isEmpty ? '—' : member.age, Icons.cake_outlined),
      (
        'Profissão',
        member.occupation?.trim().isNotEmpty == true
            ? member.occupation!.trim()
            : '—',
        Icons.work_outline_rounded,
      ),
      (
        'Estado civil',
        member.maritalStatus ?? '—',
        Icons.favorite_border_rounded,
      ),
      (
        'Cidade',
        member.address?.city ?? '—',
        Icons.location_city_rounded,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map(
                (item) => Container(
                  width: width,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.$3, size: 19, color: AppColors.primary),
                      const SizedBox(height: 9),
                      Text(
                        item.$1,
                        style: TextStyle(color: secondary, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _churchTimeline(
    MemberModel member,
    Color primary,
    Color secondary,
    Color card,
    Color border,
  ) {
    final events = <(String, String)>[
      if (member.conversionDate != null)
        ('Conversão', Formatters.formatDate(member.conversionDate!)),
      if (member.baptismDate != null)
        ('Batismo', Formatters.formatDate(member.baptismDate!)),
      if (member.admissionDate != null)
        (
          'Admissão${member.admissionType != null ? ' · ${_admissionLabel(member.admissionType)}' : ''}',
          Formatters.formatDate(member.admissionDate!),
        ),
    ];
    return _professionalCard(
      card: card,
      border: border,
      child: events.isEmpty
          ? Row(
              children: [
                Icon(Icons.church_outlined, color: secondary),
                const SizedBox(width: 10),
                Text(
                  member.isBaptized
                      ? 'Membro batizado'
                      : 'Nenhuma data registrada',
                  style: TextStyle(color: secondary),
                ),
              ],
            )
          : Column(
              children: List.generate(events.length, (index) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 13,
                          height: 13,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (index < events.length - 1)
                          Container(
                            width: 2,
                            height: 42,
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: index < events.length - 1 ? 18 : 0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              events[index].$1,
                              style: TextStyle(
                                color: primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              events[index].$2,
                              style: TextStyle(
                                color: secondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
    );
  }

  Widget _professionalCard({
    required Color card,
    required Color border,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: child,
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
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Excluir')),
                  ],
                ),
              );
              if (ok != true || !context.mounted) return;
              try {
                await ref.read(memberListProvider.notifier).delete(id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Membro excluído')));
                context.go(AppRoutes.members);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Erro: $e')));
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
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
