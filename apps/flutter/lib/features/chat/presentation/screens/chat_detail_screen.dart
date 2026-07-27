import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../core/config/theme/app_spacing.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../providers/chat_provider.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String id;

  const ChatDetailScreen({super.key, required this.id});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    ref.read(chatMessagesProvider(widget.id).notifier).send(text);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(chatMessagesProvider(widget.id));
    final currentUserId = ref.watch(authProvider).user?.id ?? '';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(title: 'Chat'),
            Expanded(
              child: state.loading
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null
                      ? Center(child: Text('Erro: ${state.error}'))
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          itemCount: state.messages.length,
                          itemBuilder: (context, index) {
                            final msg = state.messages[index];
                            final isMine = msg.isMineFor(currentUserId);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: Align(
                                alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: isMine
                                        ? AppColors.primary
                                        : isDark
                                            ? AppColors.darkCard
                                            : AppColors.lightSurface,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(AppSpacing.radiusMd),
                                      topRight: const Radius.circular(AppSpacing.radiusMd),
                                      bottomLeft: isMine
                                          ? const Radius.circular(AppSpacing.radiusMd)
                                          : Radius.zero,
                                      bottomRight: isMine
                                          ? Radius.zero
                                          : const Radius.circular(AppSpacing.radiusMd),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg.content,
                                        style: TextStyle(
                                          color: isMine
                                              ? Colors.white
                                              : isDark
                                                  ? Colors.white
                                                  : null,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        Formatters.relativeTime(msg.createdAt),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isMine
                                              ? Colors.white.withValues(alpha: 0.8)
                                              : isDark
                                                  ? AppColors.darkTextSecondary
                                                  : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: InputDecoration(
                        hintText: 'Digite uma mensagem...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: AppColors.primary,
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
