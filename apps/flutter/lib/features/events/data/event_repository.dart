import '../../../core/offline/cache_keys.dart';
import '../../../core/offline/cached_result.dart';
import '../../../core/offline/local_cache.dart';
import '../../../core/offline/network_error.dart';
import '../domain/event_model.dart';
import 'event_api.dart';

class EventRepository {
  final EventApi _api;
  final LocalCache _cache;

  EventRepository(this._api, this._cache);

  List<EventModel>? peekListCache() {
    final cached = _cache.getList(CacheKeys.eventsList);
    if (cached == null) return null;
    return cached.map(EventModel.fromJson).toList();
  }

  EventModel? peekDetailCache(String id) {
    final map = _cache.getMap(CacheKeys.eventDetail(id));
    if (map != null) return EventModel.fromJson(map);

    final list = peekListCache();
    if (list == null) return null;
    try {
      return list.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<CachedResult<List<EventModel>>> list({
    DateTime? startDate,
    DateTime? endDate,
    String? type,
  }) async {
    try {
      final items = await _api.list(
        startDate: startDate,
        endDate: endDate,
        type: type,
      );
      await _cache.setJson(
        CacheKeys.eventsList,
        items.map(_toCacheJson).toList(),
      );
      for (final item in items) {
        await _cache.setJson(CacheKeys.eventDetail(item.id), _toCacheJson(item));
      }
      return CachedResult(items);
    } catch (e) {
      if (!isNetworkError(e)) rethrow;
      final cached = peekListCache();
      if (cached != null) return CachedResult(cached, fromCache: true);
      rethrow;
    }
  }

  Future<CachedResult<EventModel>> getById(String id) async {
    try {
      final item = await _api.getById(id);
      await _cache.setJson(CacheKeys.eventDetail(id), _toCacheJson(item));
      return CachedResult(item);
    } catch (e) {
      if (!isNetworkError(e)) rethrow;
      final cached = peekDetailCache(id);
      if (cached != null) return CachedResult(cached, fromCache: true);
      rethrow;
    }
  }

  Future<EventModel> create(Map<String, dynamic> data) => _api.create(data);

  Future<EventModel> update(String id, Map<String, dynamic> data) =>
      _api.update(id, data);

  Future<void> delete(String id) => _api.delete(id);

  Future<List<String>> getTypes() => _api.getTypes();

  Map<String, dynamic> _toCacheJson(EventModel event) {
    return {
      'id': event.id,
      'title': event.title,
      'description': event.description,
      'type': event.type,
      'date': event.date.toIso8601String(),
      'startTime': event.startTime,
      'endTime': event.endTime,
      'location': event.location,
      'address': event.address,
      'ministryId': event.ministryId,
      'ministryName': event.ministryName,
      'organizerId': event.organizerId,
      'organizerName': event.organizerName,
      'bannerUrl': event.bannerUrl,
      'status': event.status,
      'participants': event.participants,
      'createdAt': event.createdAt.toIso8601String(),
    };
  }
}
