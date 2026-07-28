import '../../../core/offline/cache_keys.dart';
import '../../../core/offline/cached_result.dart';
import '../../../core/offline/local_cache.dart';
import '../../../core/offline/network_error.dart';
import '../../../core/offline/offline_mutation.dart';
import '../../../core/offline/offline_mutation_queue.dart';
import '../domain/schedule_model.dart';
import 'schedule_api.dart';

class ScheduleRepository {
  final ScheduleApi _api;
  final LocalCache _cache;
  final OfflineMutationQueue _queue;

  ScheduleRepository(this._api, this._cache, this._queue);

  List<ScheduleModel>? peekListCache() {
    final cached = _cache.getList(CacheKeys.schedulesList);
    if (cached == null) return null;
    return cached.map(ScheduleModel.fromJson).toList();
  }

  ScheduleModel? peekDetailCache(String id) {
    final map = _cache.getMap(CacheKeys.scheduleDetail(id));
    if (map != null) return ScheduleModel.fromJson(map);

    final list = peekListCache();
    if (list == null) return null;
    try {
      return list.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<CachedResult<List<ScheduleModel>>> list({int page = 1, String? ministryId}) async {
    try {
      final items = await _api.list(page: page, ministryId: ministryId);
      await _cache.setJson(
        CacheKeys.schedulesList,
        items.map(_toCacheJson).toList(),
      );
      for (final item in items) {
        await _cache.setJson(CacheKeys.scheduleDetail(item.id), _toCacheJson(item));
      }
      return CachedResult(items);
    } catch (e) {
      if (!isNetworkError(e)) rethrow;
      final cached = peekListCache();
      if (cached != null) return CachedResult(cached, fromCache: true);
      rethrow;
    }
  }

  Future<CachedResult<ScheduleModel>> getById(String id) async {
    try {
      final item = await _api.getById(id);
      await _cache.setJson(CacheKeys.scheduleDetail(id), _toCacheJson(item));
      return CachedResult(item);
    } catch (e) {
      if (!isNetworkError(e)) rethrow;
      final cached = peekDetailCache(id);
      if (cached != null) return CachedResult(cached, fromCache: true);
      rethrow;
    }
  }

  Future<ScheduleModel> create(Map<String, dynamic> data) => _api.create(data);

  Future<MutationOutcome> confirmPresence(
    String scheduleId,
    String positionId, {
    bool confirmed = true,
  }) async {
    try {
      await _api.confirmPresence(scheduleId, positionId, confirmed: confirmed);
      await _applyOptimisticConfirm(scheduleId, positionId, confirmed);
      return const MutationOutcome();
    } catch (e) {
      if (!isNetworkError(e)) rethrow;
      await _queue.enqueue(
        OfflineMutation(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          type: OfflineMutationType.scheduleConfirm,
          payload: {
            'scheduleId': scheduleId,
            'positionId': positionId,
            'confirmed': confirmed,
          },
          createdAt: DateTime.now(),
        ),
      );
      await _applyOptimisticConfirm(scheduleId, positionId, confirmed);
      return const MutationOutcome(queued: true);
    }
  }

  Future<void> _applyOptimisticConfirm(
    String scheduleId,
    String positionId,
    bool confirmed,
  ) async {
    final current = peekDetailCache(scheduleId);
    if (current == null) return;

    final positions = current.positionDetails.map((p) {
      if (p.id != positionId) return p;
      return SchedulePosition(
        id: p.id,
        scheduleId: p.scheduleId,
        memberId: p.memberId,
        memberName: p.memberName,
        memberAvatar: p.memberAvatar,
        position: p.position,
        status: confirmed ? 'CONFIRMADO' : 'INDISPONIVEL',
        isConfirmed: confirmed,
        isSubstituted: !confirmed,
      );
    }).toList();

    final updated = ScheduleModel(
      id: current.id,
      eventId: current.eventId,
      eventName: current.eventName,
      ministryId: current.ministryId,
      ministryName: current.ministryName,
      date: current.date,
      startTime: current.startTime,
      endTime: current.endTime,
      status: current.status,
      positions: positions.length,
      confirmed: positions.where((p) => p.isConfirmed).length,
      positionDetails: positions,
    );

    await _cache.setJson(CacheKeys.scheduleDetail(scheduleId), _toCacheJson(updated));

    final list = peekListCache();
    if (list != null) {
      final next = list.map((s) => s.id == scheduleId ? updated : s).toList();
      await _cache.setJson(
        CacheKeys.schedulesList,
        next.map(_toCacheJson).toList(),
      );
    }
  }

  Map<String, dynamic> _toCacheJson(ScheduleModel schedule) {
    return {
      'id': schedule.id,
      'eventId': schedule.eventId,
      'eventName': schedule.eventName,
      'ministryId': schedule.ministryId,
      'ministryName': schedule.ministryName,
      'date': schedule.date.toIso8601String(),
      'startTime': schedule.startTime,
      'endTime': schedule.endTime,
      'status': schedule.status,
      'confirmed': schedule.confirmed,
      'positions': schedule.positionDetails.isNotEmpty
          ? schedule.positionDetails.map((p) => p.toJson()).toList()
          : schedule.positions,
    };
  }
}
