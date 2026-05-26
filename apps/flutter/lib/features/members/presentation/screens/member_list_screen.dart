import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../core/config/theme/app_spacing.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../providers/member_provider.dart';

class MemberListScreen extends ConsumerStatefulWidget {
  const MemberListScreen({super.key});

  @override
  ConsumerState<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends ConsumerState<MemberListScreen> {
  String _selectedFilter = 'Todos';
  final _filters = ['Todos', 'ATIVO', 'INATIVO', 'VISITANTE'];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memberListProvider);
    final members = _selectedFilter == 'Todos'
        ? state.data
        : state.data.where((m) => m.status == _selectedFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Membros'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Container(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: _filters
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: AppChip(
                          label: f == 'ATIVO' ? 'Ativo' : f == 'INATIVO' ? 'Inativo' : f == 'VISITANTE' ? 'Visitante' : 'Todos',
                          selected: _selectedFilter == f,
                          onTap: () => setState(() => _selectedFilter = f),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
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
                                    onTap: () => context.push('/members/${member.id}'),
                                    child: Row(
                                      children: [
                                        AppAvatar(
                                          name: member.name,
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
                                                member.email ?? '',
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
