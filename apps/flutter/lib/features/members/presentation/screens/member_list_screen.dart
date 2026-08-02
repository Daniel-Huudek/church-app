import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/offline/offline_guard.dart';
import '../../../../core/router/app_routes.dart';
import '../../domain/member_model.dart';
import '../providers/member_provider.dart';

class MemberListScreen extends ConsumerStatefulWidget {
  const MemberListScreen({super.key});

  @override
  ConsumerState<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends ConsumerState<MemberListScreen> {
  String _selectedFilter = 'Todos';
  final _filters = ['Todos', 'ATIVO', 'INATIVO', 'AFASTADO', 'TRANSFERIDO'];
  final _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  bool _searching = false;
  List<MemberModel>? _searchResults;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  String _filterLabel(String f) {
    switch (f) {
      case 'ATIVO':
        return 'Ativo';
      case 'INATIVO':
        return 'Inativo';
      case 'AFASTADO':
        return 'Afastado';
      case 'TRANSFERIDO':
        return 'Transferido';
      default:
        return 'Todos';
    }
  }

  Future<void> _runSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _searchResults = null;
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await ref.read(memberRepositoryProvider).search(q);
      if (!mounted) return;
      if (_searchCtrl.text.trim() != q) return;
      setState(() {
        _searchResults = results;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _searching = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Busca falhou: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(memberListProvider);
    final user = ref.watch(authProvider).user;
    final canWrite = user?.hasPermission('members_write') == true;
    final base = _searchResults ?? state.data;
    final members = (_selectedFilter == 'Todos'
            ? base
            : base.where((member) => member.status == _selectedFilter))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final allMembers = state.data;
    final activeCount =
        allMembers.where((member) => member.status == 'ATIVO').length;
    final ministryCount = allMembers
        .expand((member) => member.ministries)
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .length;

    final background = isDark ? AppColors.darkBg : const Color(0xFFF5F6F8);
    final card = isDark ? AppColors.darkCard : Colors.white;
    final primary = isDark ? AppColors.darkText : const Color(0xFF17233B);
    final secondary =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF667085);
    final border = isDark ? AppColors.darkBorder : const Color(0xFFE1E5EA);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
          icon: Icon(Icons.arrow_back_rounded, color: primary),
        ),
        title: Text(
          'Membros',
          style: TextStyle(color: primary, fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${allMembers.length} membros cadastrados',
                        style: TextStyle(
                          color: secondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canWrite)
                  Opacity(
                    opacity: watchIsOnline(ref) ? 1 : 0.45,
                    child: ElevatedButton.icon(
                      onPressed: guardOnlineAction(context, ref, () async {
                        await context.push(AppRoutes.membersCreate);
                        if (mounted) {
                          ref.read(memberListProvider.notifier).load();
                        }
                      }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF008CFF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 19),
                      label: const Text(
                        'Novo membro',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _metricCard(
                    label: 'Total',
                    value: '${allMembers.length}',
                    icon: Icons.people_alt_rounded,
                    color: const Color(0xFF008CFF),
                    card: card,
                    border: border,
                    primary: primary,
                    secondary: secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _metricCard(
                    label: 'Ativos',
                    value: '$activeCount',
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                    card: card,
                    border: border,
                    primary: primary,
                    secondary: secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _metricCard(
                    label: 'Ministérios',
                    value: '$ministryCount',
                    icon: Icons.groups_rounded,
                    color: const Color(0xFF0F766E),
                    card: card,
                    border: border,
                    primary: primary,
                    secondary: secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              onSubmitted: _runSearch,
              onChanged: _onSearchChanged,
              style: TextStyle(color: primary),
              decoration: InputDecoration(
                hintText: 'Buscar nome, telefone ou e-mail',
                hintStyle: TextStyle(color: secondary),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF008CFF),
                ),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpar busca',
                        onPressed: _clearSearch,
                        icon: Icon(Icons.close_rounded, color: secondary),
                      ),
                filled: true,
                fillColor: card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF008CFF),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          if (_searching)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final selected = _selectedFilter == filter;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = filter),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF008CFF) : card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? const Color(0xFF008CFF) : border,
                      ),
                    ),
                    child: Text(
                      _filterLabel(filter),
                      style: TextStyle(
                        color: selected ? Colors.white : secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: state.loading && members.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.error != null && members.isEmpty
                    ? Center(child: Text('Erro: ${state.error}'))
                    : members.isEmpty
                        ? const AppEmptyState(
                            title: 'Nenhum membro',
                            subtitle: 'Nenhum resultado para os filtros atuais',
                            icon: Icons.people,
                          )
                        : RefreshIndicator(
                            onRefresh: () =>
                                ref.read(memberListProvider.notifier).load(),
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                0,
                                20,
                                100,
                              ),
                              itemCount: members.length,
                              itemBuilder: (context, index) {
                                final member = members[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _memberCard(
                                    context,
                                    member,
                                    card: card,
                                    border: border,
                                    primary: primary,
                                    secondary: secondary,
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _searchResults = null;
        _searching = false;
      });
      return;
    }
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _runSearch(value),
    );
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchCtrl.clear();
    setState(() {
      _searchResults = null;
      _searching = false;
    });
  }

  Widget _metricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color card,
    required Color border,
    required Color primary,
    required Color secondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: primary,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: secondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _memberCard(
    BuildContext context,
    MemberModel member, {
    required Color card,
    required Color border,
    required Color primary,
    required Color secondary,
  }) {
    final statusColor = member.status == 'ATIVO'
        ? AppColors.success
        : member.status == 'AFASTADO'
            ? AppColors.warning
            : const Color(0xFF64748B);
    final contact = member.email?.trim().isNotEmpty == true
        ? member.email!.trim()
        : member.phone ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await context.push(AppRoutes.memberDetail(member.id));
          if (mounted) ref.read(memberListProvider.notifier).load();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              AppAvatar(
                name: member.name,
                imageUrl: member.avatar,
                authenticated: true,
                size: 52,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            member.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: primary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _filterLabel(member.status),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (contact.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        contact,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: secondary, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        _smallBadge(member.role, const Color(0xFF008CFF)),
                        if (member.ministries.isNotEmpty)
                          _smallBadge(
                            member.ministries.first,
                            const Color(0xFF0F766E),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, color: secondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
