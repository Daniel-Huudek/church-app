import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';

class WorshipApi {
  final ApiClient _client;
  WorshipApi(this._client);

  Future<Map<String, dynamic>> listSongs({String? search, String? tag, String? key, int page = 1, int limit = 20}) async {
    final p = <String, dynamic>{'page': page, 'limit': limit};
    if (search != null) p['search'] = search; if (tag != null) p['tag'] = tag; if (key != null) p['key'] = key;
    final r = await _client.get(ApiConfig.worshipSongs, queryParameters: p); return r.data;
  }
  Future<Map<String, dynamic>> getSong(String id) async { final r = await _client.get('${ApiConfig.worshipSongs}/$id'); return r.data; }
  Future<Map<String, dynamic>> createSong(Map<String, dynamic> data) async { final r = await _client.post(ApiConfig.worshipSongs, data: data); return r.data; }
  Future<Map<String, dynamic>> updateSong(String id, Map<String, dynamic> data) async { final r = await _client.put('${ApiConfig.worshipSongs}/$id', data: data); return r.data; }
  Future<void> deleteSong(String id) async { await _client.delete('${ApiConfig.worshipSongs}/$id'); }
  Future<Map<String, dynamic>> transposeSong(String id, int semitons) async { final r = await _client.post('${ApiConfig.worshipSongs}/$id/transpose', data: {'semitons': semitons}); return r.data; }
  Future<List<dynamic>> getSongHistory(String id) async { final r = await _client.get('${ApiConfig.worshipSongs}/$id/history'); return r.data as List? ?? []; }
  Future<Map<String, dynamic>> listPlaylists({int page = 1, int limit = 20}) async { final r = await _client.get(ApiConfig.worshipPlaylists, queryParameters: {'page': page, 'limit': limit}); return r.data; }
  Future<Map<String, dynamic>> getPlaylist(String id) async { final r = await _client.get('${ApiConfig.worshipPlaylists}/$id'); return r.data; }
  Future<Map<String, dynamic>> createPlaylist(Map<String, dynamic> data) async { final r = await _client.post(ApiConfig.worshipPlaylists, data: data); return r.data; }
  Future<Map<String, dynamic>> updatePlaylist(String id, Map<String, dynamic> data) async { final r = await _client.put('${ApiConfig.worshipPlaylists}/$id', data: data); return r.data; }
  Future<void> deletePlaylist(String id) async { await _client.delete('${ApiConfig.worshipPlaylists}/$id'); }
  Future<Map<String, dynamic>> duplicatePlaylist(String id) async { final r = await _client.post('${ApiConfig.worshipPlaylists}/$id/duplicate'); return r.data; }
  Future<void> reorderPlaylistSongs(String id, List<String> songIds) async { await _client.put('${ApiConfig.worshipPlaylists}/$id/songs/reorder', data: {'songIds': songIds}); }
  Future<Map<String, dynamic>?> getWorshipEventByEvent(String eventId) async { try { final r = await _client.get('${ApiConfig.worshipEvents}/event/$eventId'); return r.data; } catch (_) { return null; } }
  Future<Map<String, dynamic>> getWorshipEvent(String id) async { final r = await _client.get('${ApiConfig.worshipEvents}/$id'); return r.data; }
  Future<Map<String, dynamic>> listWorshipEvents({int page = 1, int limit = 50}) async { final r = await _client.get(ApiConfig.worshipEvents, queryParameters: {'page': page, 'limit': limit}); return r.data; }
  Future<Map<String, dynamic>> createWorshipEvent(Map<String, dynamic> data) async { final r = await _client.post(ApiConfig.worshipEvents, data: data); return r.data; }
  Future<void> updateWorshipEvent(String id, Map<String, dynamic> data) async { await _client.put('${ApiConfig.worshipEvents}/$id', data: data); }
  Future<void> deleteWorshipEvent(String id) async { await _client.delete('${ApiConfig.worshipEvents}/$id'); }
  Future<void> reorderWorshipEventSongs(String id, List<String> songIds) async { await _client.put('${ApiConfig.worshipEvents}/$id/songs', data: {'songIds': songIds}); }
  Future<void> setWorshipEventMusicians(String id, List<Map<String, dynamic>> musicians) async { await _client.put('${ApiConfig.worshipEvents}/$id/musicians', data: {'musicians': musicians}); }
  Future<void> confirmMusician(String weId, String memberId, {String status = 'confirmado'}) async { await _client.post('${ApiConfig.worshipEvents}/$weId/musicians/$memberId/confirm', data: {'status': status}); }
  Future<List<dynamic>> getFavorites() async { final r = await _client.get(ApiConfig.worshipFavorites); return (r.data as Map?)?['data'] as List? ?? []; }

  Future<List<Map<String, dynamic>>> searchSongs(String query) async {
    final r = await _client.post(ApiConfig.worshipSongsSearch, data: {'query': query});
    final data = _client.unwrapData(r.data);
    final list = data['list'] as List<dynamic>? ?? data as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }
  Future<void> addFavorite(String songId) async { await _client.post('${ApiConfig.worshipFavorites}/$songId'); }
  Future<void> removeFavorite(String songId) async { await _client.delete('${ApiConfig.worshipFavorites}/$songId'); }
}
