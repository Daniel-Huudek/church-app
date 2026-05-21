import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../core/config/theme/app_spacing.dart';
import '../../../../core/config/theme/app_colors.dart';

class ChatDetailScreen extends ConsumerWidget {
  final String id;

  const ChatDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(title: 'Grupo de Louvor'),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: 5,
                itemBuilder: (context, index) {
                  final isMe = index.isEven;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Row(
                      mainAxisAlignment:
                          isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isMe) ...[
                          const AppAvatar(name: 'João', size: 28),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.darkCard
                                      : AppColors.lightSurface),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(
                                    AppSpacing.radiusMd),
                                topRight: const Radius.circular(
                                    AppSpacing.radiusMd),
                                bottomLeft: Radius.circular(
                                    isMe ? AppSpacing.radiusMd : 0),
                                bottomRight: Radius.circular(
                                    isMe ? 0 : AppSpacing.radiusMd),
                              ),
                            ),
                            child: Text(
                              'Mensagem de exemplo $index',
                              style: TextStyle(
                                color: isMe ? Colors.white : null,
                              ),
                            ),
                          ),
                        ),
                      ],
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
                      decoration: InputDecoration(
                        hintText: 'Digite uma mensagem...',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: AppColors.primary,
                    onPressed: () {},
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
