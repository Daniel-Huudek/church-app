import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/theme/app_colors.dart';
import '../../core/offline/connectivity_provider.dart';
import '../../core/offline/offline_guard.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlineAsync = ref.watch(isOnlineProvider);
    final isOnline = onlineAsync.maybeWhen(
      data: (value) => value,
      orElse: () => true,
    );
    final pending = ref.watch(pendingMutationsCountProvider);

    if (isOnline && pending == 0) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final message = !isOnline
        ? (pending > 0
            ? 'Sem conexão — $pending ação(ões) aguardando sync'
            : 'Sem conexão — mostrando dados salvos')
        : '$pending ação(ões) sincronizando…';

    return Material(
      color: isDark ? const Color(0xFF422006) : AppColors.warningLight,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                isOnline ? Icons.sync : Icons.cloud_off_outlined,
                size: 18,
                color: isDark ? const Color(0xFFFBBF24) : AppColors.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
