import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_cache.dart';
import 'network_error.dart';
import 'offline_mutation.dart';

const _queueKey = 'offline:mutation_queue';

final offlineMutationQueueProvider = Provider<OfflineMutationQueue>((ref) {
  return OfflineMutationQueue(ref.read(localCacheProvider));
});

class OfflineMutationQueue {
  final LocalCache _cache;

  OfflineMutationQueue(this._cache);

  List<OfflineMutation> peek() {
    final list = _cache.getList(_queueKey);
    if (list == null) return const [];
    return list.map(OfflineMutation.fromJson).toList();
  }

  int get pendingCount => peek().length;

  Future<void> enqueue(OfflineMutation mutation) async {
    final current = peek()
        .where((m) => m.dedupeKey != mutation.dedupeKey)
        .toList();
    current.add(mutation);
    await _cache.setJson(
      _queueKey,
      current.map((m) => m.toJson()).toList(),
    );
  }

  Future<void> remove(String id) async {
    final current = peek().where((m) => m.id != id).toList();
    await _cache.setJson(
      _queueKey,
      current.map((m) => m.toJson()).toList(),
    );
  }

  Future<int> flush({
    required Future<void> Function(
      String scheduleId,
      String positionId,
      bool confirmed,
    ) confirmSchedule,
    required Future<void> Function(
      String worshipEventId,
      String memberId,
      String status,
    ) confirmWorship,
  }) async {
    final pending = peek();
    var synced = 0;

    for (final mutation in pending) {
      try {
        switch (mutation.type) {
          case OfflineMutationType.scheduleConfirm:
            await confirmSchedule(
              mutation.payload['scheduleId'] as String,
              mutation.payload['positionId'] as String,
              mutation.payload['confirmed'] as bool? ?? true,
            );
          case OfflineMutationType.worshipConfirm:
            await confirmWorship(
              mutation.payload['worshipEventId'] as String,
              mutation.payload['memberId'] as String,
              mutation.payload['status'] as String? ?? 'confirmado',
            );
        }
        await remove(mutation.id);
        synced++;
      } catch (e) {
        if (isNetworkError(e)) break;
        // Drop permanent failures so the queue does not stall.
        await remove(mutation.id);
      }
    }

    return synced;
  }
}
