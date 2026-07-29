import '../../../core/offline/cache_keys.dart';
import '../../../core/offline/cached_result.dart';
import '../../../core/offline/local_cache.dart';
import '../../../core/offline/network_error.dart';
import '../../../core/offline/offline_mutation.dart';
import '../../../core/offline/offline_mutation_queue.dart';
import '../domain/worship_models.dart';
import 'worship_api.dart';

class WorshipRepository {
  final WorshipApi _api;
  final LocalCache _cache;
  final OfflineMutationQueue _queue;

  WorshipRepository(this._api, this._cache, this._queue);

  List<Song>? peekSongsCache() {
    final cached = _cache.getList(CacheKeys.worshipSongsList);
    if (cached == null) return null;
    return cached.map(Song.fromJson).toList();
  }

  List<Playlist>? peekPlaylistsCache() {
    final cached = _cache.getList(CacheKeys.worshipPlaylistsList);
    if (cached == null) return null;
    return cached.map(Playlist.fromJson).toList();
  }

  List<Song>? peekFavoritesCache() {
    final cached = _cache.getList(CacheKeys.worshipFavoritesList);
    if (cached == null) return null;
    return cached.map(Song.fromJson).toList();
  }

  List<WorshipEvent>? peekWorshipEventsCache() {
    final cached = _cache.getList(CacheKeys.worshipEventsList);
    if (cached == null) return null;
    return cached.map(WorshipEvent.fromJson).toList();
  }

  WorshipEvent? peekWorshipEventCache(String id) {
    final map = _cache.getMap(CacheKeys.worshipEventDetail(id));
    if (map != null) {
      final data = map.containsKey('data') && map['data'] is Map
          ? Map<String, dynamic>.from(map['data'] as Map)
          : map;
      return WorshipEvent.fromJson(data);
    }
    final list = peekWorshipEventsCache();
    if (list == null) return null;
    try {
      return list.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Clears list/detail caches so the next load fetches fresh data from the API.
  Future<void> invalidateWorshipEventCaches({String? id}) async {
    await _cache.remove(CacheKeys.worshipEventsList);
    if (id != null) {
      await _cache.remove(CacheKeys.worshipEventDetail(id));
    }
  }

  Future<CachedResult<List<Song>>> listSongs({String? search}) async {
    try {
      final response = await _api.listSongs(search: search, limit: 100);
      final raw = (response['data'] as List?) ?? [];
      final maps = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (search == null || search.isEmpty) {
        await _cache.setJson(CacheKeys.worshipSongsList, maps);
        for (final map in maps) {
          final id = map['id'] as String?;
          if (id != null) {
            await _cache.setJson(CacheKeys.worshipSongDetail(id), map);
          }
        }
      }
      return CachedResult(maps.map(Song.fromJson).toList());
    } catch (e) {
      if (!isNetworkError(e)) rethrow;
      if (search != null && search.isNotEmpty) rethrow;
      final cached = peekSongsCache();
      if (cached != null) return CachedResult(cached, fromCache: true);
      rethrow;
    }
  }

  Future<CachedResult<List<Playlist>>> listPlaylists() async {
    try {
      final response = await _api.listPlaylists();
      final raw = (response['data'] as List?) ?? [];
      final maps = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      await _cache.setJson(CacheKeys.worshipPlaylistsList, maps);
      return CachedResult(maps.map(Playlist.fromJson).toList());
    } catch (e) {
      if (!isNetworkError(e)) rethrow;
      final cached = peekPlaylistsCache();
      if (cached != null) return CachedResult(cached, fromCache: true);
      rethrow;
    }
  }

  Future<CachedResult<List<Song>>> getFavorites() async {
    try {
      final raw = await _api.getFavorites();
      final maps = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      await _cache.setJson(CacheKeys.worshipFavoritesList, maps);
      return CachedResult(maps.map(Song.fromJson).toList());
    } catch (e) {
      if (!isNetworkError(e)) rethrow;
      final cached = peekFavoritesCache();
      if (cached != null) return CachedResult(cached, fromCache: true);
      rethrow;
    }
  }

  Future<CachedResult<List<WorshipEvent>>> listWorshipEvents({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _api.listWorshipEvents(page: page, limit: limit);
      final raw = (response['data'] as List?) ?? [];
      final maps = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      await _cache.setJson(CacheKeys.worshipEventsList, maps);
      for (final map in maps) {
        final id = map['id'] as String?;
        if (id != null) {
          await _cache.setJson(CacheKeys.worshipEventDetail(id), map);
        }
      }
      return CachedResult(maps.map(WorshipEvent.fromJson).toList());
    } catch (e) {
      if (!isNetworkError(e)) rethrow;
      final cached = peekWorshipEventsCache();
      if (cached != null) return CachedResult(cached, fromCache: true);
      rethrow;
    }
  }

  Future<CachedResult<WorshipEvent>> getWorshipEvent(String id) async {
    try {
      final response = await _api.getWorshipEvent(id);
      final map = Map<String, dynamic>.from(response);
      final data = map.containsKey('data') && map['data'] is Map
          ? Map<String, dynamic>.from(map['data'] as Map)
          : map;
      await _cache.setJson(CacheKeys.worshipEventDetail(id), data);
      return CachedResult(WorshipEvent.fromJson(data));
    } catch (e) {
      if (!isNetworkError(e)) rethrow;
      final cached = peekWorshipEventCache(id);
      if (cached != null) return CachedResult(cached, fromCache: true);
      rethrow;
    }
  }

  Future<void> deleteWorshipEvent(String id) async {
    await _api.deleteWorshipEvent(id);
    final list = peekWorshipEventsCache();
    if (list != null) {
      final next = list.where((e) => e.id != id).toList();
      await _cache.setJson(
        CacheKeys.worshipEventsList,
        next.map(_worshipEventToCache).toList(),
      );
    } else {
      await _cache.remove(CacheKeys.worshipEventsList);
    }
    await _cache.remove(CacheKeys.worshipEventDetail(id));
  }

  Future<MutationOutcome> confirmMusician(
    String worshipEventId,
    String memberId, {
    String status = 'confirmado',
  }) async {
    try {
      await _api.confirmMusician(worshipEventId, memberId, status: status);
      await _applyOptimisticMusician(worshipEventId, memberId, status);
      return const MutationOutcome();
    } catch (e) {
      if (!isNetworkError(e)) rethrow;
      await _queue.enqueue(
        OfflineMutation(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          type: OfflineMutationType.worshipConfirm,
          payload: {
            'worshipEventId': worshipEventId,
            'memberId': memberId,
            'status': status,
          },
          createdAt: DateTime.now(),
        ),
      );
      await _applyOptimisticMusician(worshipEventId, memberId, status);
      return const MutationOutcome(queued: true);
    }
  }

  Future<void> _applyOptimisticMusician(
    String worshipEventId,
    String memberId,
    String status,
  ) async {
    final current = peekWorshipEventCache(worshipEventId);
    if (current == null) return;

    final musicians = current.musicians?.map((m) {
      if (m.memberId != memberId) return m;
      return WorshipEventMusician(
        id: m.id,
        memberId: m.memberId,
        instrument: m.instrument,
        role: m.role,
        isConfirmed: status == 'confirmado',
        isSubstituted: status == 'indisponivel',
      );
    }).toList();

    final updated = WorshipEvent(
      id: current.id,
      eventId: current.eventId,
      playlistId: current.playlistId,
      notes: current.notes,
      estimatedTime: current.estimatedTime,
      createdAt: current.createdAt,
      updatedAt: current.updatedAt,
      songs: current.songs,
      musicians: musicians,
      playlist: current.playlist,
    );

    await _cache.setJson(
      CacheKeys.worshipEventDetail(worshipEventId),
      _worshipEventToCache(updated),
    );

    final list = peekWorshipEventsCache();
    if (list != null) {
      final next = list.map((e) => e.id == worshipEventId ? updated : e).toList();
      await _cache.setJson(
        CacheKeys.worshipEventsList,
        next.map(_worshipEventToCache).toList(),
      );
    }
  }

  Map<String, dynamic> _worshipEventToCache(WorshipEvent event) {
    return {
      'id': event.id,
      'eventId': event.eventId,
      'playlistId': event.playlistId,
      'notes': event.notes,
      'estimatedTime': event.estimatedTime,
      'createdAt': event.createdAt.toIso8601String(),
      'updatedAt': event.updatedAt.toIso8601String(),
      'songs': event.songs
          ?.map(
            (s) => {
              'id': s.id,
              'order': s.order,
              'transpose': s.transpose,
              'notes': s.notes,
              'song': _songToCache(s.song),
            },
          )
          .toList(),
      'musicians': event.musicians
          ?.map(
            (m) => {
              'id': m.id,
              'memberId': m.memberId,
              'instrument': m.instrument,
              'role': m.role,
              'isConfirmed': m.isConfirmed,
              'isSubstituted': m.isSubstituted,
            },
          )
          .toList(),
      if (event.playlist != null)
        'playlist': {
          'id': event.playlist!.id,
          'name': event.playlist!.name,
          'description': event.playlist!.description,
          'createdBy': event.playlist!.createdBy,
          'isPublic': event.playlist!.isPublic,
          'createdAt': event.playlist!.createdAt.toIso8601String(),
          'updatedAt': event.playlist!.updatedAt.toIso8601String(),
        },
    };
  }

  Map<String, dynamic> _songToCache(Song song) {
    return {
      'id': song.id,
      'title': song.title,
      'artist': song.artist,
      'key': song.key,
      'bpm': song.bpm,
      'duration': song.duration,
      'lyrics': song.lyrics,
      'chords': song.chords,
      'capo': song.capo,
      'youtubeUrl': song.youtubeUrl,
      'thumbnail': song.thumbnail,
      'notes': song.notes,
      'isActive': song.isActive,
      'createdAt': song.createdAt.toIso8601String(),
      'updatedAt': song.updatedAt.toIso8601String(),
      if (song.tags != null)
        'tags': song.tags!
            .map((t) => {
                  'tag': {'id': t.id, 'name': t.name, 'color': t.color},
                })
            .toList(),
      if (song.favoritesCount != null) '_count': {'favorites': song.favoritesCount},
    };
  }
}
