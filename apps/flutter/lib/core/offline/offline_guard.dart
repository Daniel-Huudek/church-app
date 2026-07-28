import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connectivity_provider.dart';
import 'offline_mutation_queue.dart';
import '../../features/schedules/data/schedule_api.dart';
import '../../features/worship/data/worship_api.dart';
import '../network/api_client.dart';

final pendingMutationsCountProvider = Provider<int>((ref) {
  // Re-read when sync runs by depending on a tick provider.
  ref.watch(mutationQueueTickProvider);
  return ref.read(offlineMutationQueueProvider).pendingCount;
});

final mutationQueueTickProvider = StateProvider<int>((ref) => 0);

/// Boots connectivity → flush listeners once at app start.
final mutationSyncBootstrapProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<bool>>(isOnlineProvider, (previous, next) {
    final online = next.asData?.value ?? false;
    final wasOnline = previous?.asData?.value ?? false;
    if (online && !wasOnline) {
      ref.read(mutationSyncProvider).flush();
    }
  });
});

final mutationSyncProvider = Provider<MutationSyncService>((ref) {
  return MutationSyncService(ref);
});

class MutationSyncService {
  final Ref _ref;

  MutationSyncService(this._ref);

  Future<int> flush() async {
    final queue = _ref.read(offlineMutationQueueProvider);
    final apiClient = _ref.read(apiClientProvider);
    final scheduleApi = ScheduleApi(apiClient);
    final worshipApi = WorshipApi(apiClient);

    final synced = await queue.flush(
      confirmSchedule: (scheduleId, positionId, confirmed) {
        return scheduleApi.confirmPresence(
          scheduleId,
          positionId,
          confirmed: confirmed,
        );
      },
      confirmWorship: (worshipEventId, memberId, status) {
        return worshipApi.confirmMusician(
          worshipEventId,
          memberId,
          status: status,
        );
      },
    );

    _ref.read(mutationQueueTickProvider.notifier).state++;
    return synced;
  }
}

bool watchIsOnline(WidgetRef ref) {
  return ref.watch(isOnlineProvider).maybeWhen(
        data: (value) => value,
        orElse: () => true,
      );
}

void showRequiresInternetSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Esta ação precisa de internet'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void showQueuedSyncSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Salvo offline — sincroniza quando voltar a internet'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void notifyMutationQueueChanged(WidgetRef ref) {
  ref.read(mutationQueueTickProvider.notifier).state++;
}

/// Returns [action] when online; otherwise shows snackbar and returns null-safe no-op handler.
VoidCallback guardOnlineAction(
  BuildContext context,
  WidgetRef ref,
  VoidCallback action,
) {
  return () {
    if (!watchIsOnline(ref)) {
      showRequiresInternetSnackBar(context);
      return;
    }
    action();
  };
}
