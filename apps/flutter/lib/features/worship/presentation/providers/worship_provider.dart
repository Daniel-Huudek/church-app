import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/worship_api.dart';
import '../../domain/worship_models.dart';

final worshipApiProvider = Provider<WorshipApi>((ref) => WorshipApi(ref.watch(apiClientProvider)));

final songsProvider = StateNotifierProvider<SongsNotifier, AsyncValue<List<Song>>>((ref) => SongsNotifier(ref.watch(worshipApiProvider)));
final playlistsProvider = StateNotifierProvider<PlaylistsNotifier, AsyncValue<List<Playlist>>>((ref) => PlaylistsNotifier(ref.watch(worshipApiProvider)));
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, AsyncValue<List<Song>>>((ref) => FavoritesNotifier(ref.watch(worshipApiProvider)));

class SongsNotifier extends StateNotifier<AsyncValue<List<Song>>> {
  final WorshipApi _api;
  SongsNotifier(this._api) : super(const AsyncValue.loading()) { load(); }
  Future<void> load({String? search}) async {
    state = const AsyncValue.loading();
    try { final r = await _api.listSongs(search: search); state = AsyncValue.data((r['data'] as List).map((s) => Song.fromJson(s)).toList()); }
    catch (e, st) { state = AsyncValue.error(e, st); }
  }
}
class PlaylistsNotifier extends StateNotifier<AsyncValue<List<Playlist>>> {
  final WorshipApi _api;
  PlaylistsNotifier(this._api) : super(const AsyncValue.loading()) { load(); }
  Future<void> load() async {
    state = const AsyncValue.loading();
    try { final r = await _api.listPlaylists(); state = AsyncValue.data((r['data'] as List).map((p) => Playlist.fromJson(p)).toList()); }
    catch (e, st) { state = AsyncValue.error(e, st); }
  }
}
class FavoritesNotifier extends StateNotifier<AsyncValue<List<Song>>> {
  final WorshipApi _api;
  FavoritesNotifier(this._api) : super(const AsyncValue.loading()) { load(); }
  Future<void> load() async {
    state = const AsyncValue.loading();
    try { final r = await _api.getFavorites(); state = AsyncValue.data(r.map((s) => Song.fromJson(s)).toList()); }
    catch (e, st) { state = AsyncValue.error(e, st); }
  }
  Future<void> toggle(String songId) async {
    try { final current = state.value ?? []; final isFav = current.any((s) => s.id == songId); if (isFav) await _api.removeFavorite(songId); else await _api.addFavorite(songId); await load(); } catch (_) {}
  }
}
