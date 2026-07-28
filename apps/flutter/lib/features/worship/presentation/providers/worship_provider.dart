import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/offline/local_cache.dart';
import '../../../../core/offline/offline_mutation_queue.dart';
import '../../data/worship_api.dart';
import '../../data/worship_repository.dart';
import '../../domain/worship_models.dart';

final worshipApiProvider = Provider<WorshipApi>((ref) => WorshipApi(ref.watch(apiClientProvider)));

final worshipRepositoryProvider = Provider<WorshipRepository>((ref) {
  return WorshipRepository(
    ref.watch(worshipApiProvider),
    ref.watch(localCacheProvider),
    ref.watch(offlineMutationQueueProvider),
  );
});

final songsProvider = StateNotifierProvider<SongsNotifier, AsyncValue<List<Song>>>(
  (ref) => SongsNotifier(ref.watch(worshipRepositoryProvider)),
);
final playlistsProvider = StateNotifierProvider<PlaylistsNotifier, AsyncValue<List<Playlist>>>(
  (ref) => PlaylistsNotifier(ref.watch(worshipRepositoryProvider)),
);
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, AsyncValue<List<Song>>>(
  (ref) => FavoritesNotifier(ref.watch(worshipRepositoryProvider), ref.watch(worshipApiProvider)),
);

class SongsNotifier extends StateNotifier<AsyncValue<List<Song>>> {
  final WorshipRepository _repository;

  SongsNotifier(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load({String? search}) async {
    final cached = (search == null || search.isEmpty) ? _repository.peekSongsCache() : null;
    if (cached != null) {
      state = AsyncValue.data(cached);
    } else {
      state = const AsyncValue.loading();
    }

    try {
      final result = await _repository.listSongs(search: search);
      state = AsyncValue.data(result.data);
    } catch (e, st) {
      if (state.asData?.value.isNotEmpty == true) return;
      state = AsyncValue.error(e, st);
    }
  }
}

class PlaylistsNotifier extends StateNotifier<AsyncValue<List<Playlist>>> {
  final WorshipRepository _repository;

  PlaylistsNotifier(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    final cached = _repository.peekPlaylistsCache();
    if (cached != null) {
      state = AsyncValue.data(cached);
    } else {
      state = const AsyncValue.loading();
    }

    try {
      final result = await _repository.listPlaylists();
      state = AsyncValue.data(result.data);
    } catch (e, st) {
      if (state.asData?.value.isNotEmpty == true) return;
      state = AsyncValue.error(e, st);
    }
  }
}

class FavoritesNotifier extends StateNotifier<AsyncValue<List<Song>>> {
  final WorshipRepository _repository;
  final WorshipApi _api;

  FavoritesNotifier(this._repository, this._api) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    final cached = _repository.peekFavoritesCache();
    if (cached != null) {
      state = AsyncValue.data(cached);
    } else {
      state = const AsyncValue.loading();
    }

    try {
      final result = await _repository.getFavorites();
      state = AsyncValue.data(result.data);
    } catch (e, st) {
      if (state.asData?.value.isNotEmpty == true) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggle(String songId) async {
    try {
      final current = state.value ?? [];
      final isFav = current.any((s) => s.id == songId);
      if (isFav) {
        await _api.removeFavorite(songId);
      } else {
        await _api.addFavorite(songId);
      }
      await load();
    } catch (_) {}
  }
}
