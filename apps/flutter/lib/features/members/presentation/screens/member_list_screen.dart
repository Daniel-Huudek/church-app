import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../core/config/theme/app_spacing.dart';
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
  bool _searching = false;
  bool _showSearch = false;
  List<MemberModel>? _searchResults;

  @override
  void dispose() {
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
      setState(() {
        _searchResults = results;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _searching = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Busca falhou: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memberListProvider);
    final user = ref.watch(authProvider).user;
    final canWrite = user?.hasPermission('members_write') == true;
    final base = _searchResults ?? state.data;
    final members = _selectedFilter == 'Todos'
        ? base
        : base.where((m) => m.status == _selectedFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Buscar nome, e-mail, telefone…',
                  border: InputBorder.none,
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: _runSearch,
                onChanged: (v) {
                  if (v.trim().isEmpty) {
                    setState(() => _searchResults = null);
                  }
                },
              )
            : const Text('Membros'),
        actions: [
          if (_showSearch)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _searchCtrl.clear();
                setState(() {
                  _showSearch = false;
                  _searchResults = null;
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _showSearch = true),
            ),
        ],
      ),
      floatingActionButton: canWrite
          ? Opacity(
              opacity: watchIsOnline(ref) ? 1 : 0.45,
              child: FloatingActionButton(
                onPressed: guardOnlineAction(context, ref, () => context.push(AppRoutes.membersCreate)),
                child: const Icon(Icons.add),
              ),
            )
          : null,
      body: Column(
        children: [
          if (_searching) const LinearProgressIndicator(minHeight: 2),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: _filters
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: AppChip(
                          label: _filterLabel(f),
                          selected: _selectedFilter == f,
                          onTap: () => setState(() => _selectedFilter = f),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: state.loading && members.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.error != null && members.isEmpty
                    ? Center(child: Text('Erro: ${state.error}'))
                    : members.isEmpty
                        ? const AppEmptyState(
                            title: 'Nenhum membro',
                            subtitle: 'Não há membros cadastrados',
                            icon: Icons.people,
                          )
                        : RefreshIndicator(
                            onRefresh: () => ref.read(memberListProvider.notifier).load(),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                              itemCount: members.length,
                              itemBuilder: (context, index) {
                                final member = members[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                  child: AppCard(
                                    onTap: () => context.push(AppRoutes.memberDetail(member.id)),
                                    child: Row(
                                      children: [
                                        AppAvatar(
                                          name: member.name,
                                          imageUrl: member.avatar,
                                          authenticated: true,
                                          size: 44,
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                member.name,
                                                style: Theme.of(context).textTheme.titleSmall,
                                              ),
                                              Text(
                                                member.email ?? member.phone ?? '',
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: member.status == 'ATIVO'
                                                ? AppColors.success
                                                : AppColors.warning,
                                          ),
                                        ),
                                      ],
                                    ),
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
}
