import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../core/config/theme/app_spacing.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../providers/user_provider.dart';

class UserListScreen extends ConsumerWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userListProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(title: 'Usuários'),
            Expanded(
              child: state.loading
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null
                      ? Center(child: Text('Erro: ${state.error}'))
                      : state.data.isEmpty
                          ? const Center(child: Text('Nenhum usuário'))
                          : RefreshIndicator(
                              onRefresh: () => ref.read(userListProvider.notifier).load(),
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                                itemCount: state.data.length,
                                itemBuilder: (context, index) {
                                  final user = state.data[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                    child: AppCard(
                                      onTap: () => context.push('/users/${user.id}/edit'),
                                      child: Row(
                                        children: [
                                          AppAvatar(name: user.name, size: 44),
                                          const SizedBox(width: AppSpacing.md),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(user.name, style: Theme.of(context).textTheme.titleSmall),
                                                Text(user.email, style: Theme.of(context).textTheme.bodySmall),
                                              ],
                                            ),
                                          ),
                                          AppBadge(
                                            label: user.role,
                                            variant: user.role == 'ADMINISTRADOR'
                                                ? AppBadgeVariant.error
                                                : AppBadgeVariant.info,
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
      ),
    );
  }
}
