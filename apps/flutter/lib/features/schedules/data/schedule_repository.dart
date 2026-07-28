import '../../../core/offline/cache_keys.dart';
import '../../../core/offline/cached_result.dart';
import '../../../core/offline/local_cache.dart';
import '../../../core/offline/network_error.dart';
import '../domain/schedule_model.dart';
import 'schedule_api.dart';

class ScheduleRepository {
  final ScheduleApi _api;
  final LocalCache _cache;

  ScheduleRepository(this._api, this._cache);

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

  Future<void> confirmPresence(
    String scheduleId,
    String positionId, {
    bool confirmed = true,
  }) {
    return _api.confirmPresence(scheduleId, positionId, confirmed: confirmed);
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
