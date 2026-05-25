import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../core/config/theme/app_spacing.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/chat_provider.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatRoomListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Conversas')),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Erro: ${state.error}'))
              : state.rooms.isEmpty
                  ? const Center(child: Text('Nenhuma conversa'))
                  : RefreshIndicator(
                      onRefresh: () => ref.read(chatRoomListProvider.notifier).load(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: state.rooms.length,
                        itemBuilder: (context, index) {
                          final room = state.rooms[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: AppCard(
                              onTap: () => context.push('/chat/${room.id}'),
                              child: Row(
                                children: [
                                  AppAvatar(name: room.name ?? 'Grupo', size: 48),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          room.name ?? 'Conversa',
                                          style: Theme.of(context).textTheme.titleSmall,
                                        ),
                                        const SizedBox(height: AppSpacing.xxs),
                                        Text(
                                          room.lastMessage ?? 'Sem mensagens',
                                          style: Theme.of(context).textTheme.bodySmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        Formatters.relativeTime(room.updatedAt),
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      if (room.unreadCount > 0) ...[
                                        const SizedBox(height: AppSpacing.xs),
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.primary,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${room.unreadCount}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
