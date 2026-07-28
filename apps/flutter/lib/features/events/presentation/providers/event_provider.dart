import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/offline/local_cache.dart';
import '../../data/event_api.dart';
import '../../data/event_repository.dart';
import '../../domain/event_model.dart';
import '../../../../shared/providers/async_state.dart';
import '../../../../shared/utils/error_helper.dart';

final eventApiProvider = Provider<EventApi>((ref) {
  return EventApi(ref.read(apiClientProvider));
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(
    ref.read(eventApiProvider),
    ref.read(localCacheProvider),
  );
});

final eventListProvider = StateNotifierProvider.autoDispose<EventListNotifier, AsyncState<List<EventModel>>>((ref) {
  return EventListNotifier(ref.read(eventRepositoryProvider));
});

class EventListNotifier extends StateNotifier<AsyncState<List<EventModel>>> {
  final EventRepository _repository;

  EventListNotifier(this._repository) : super(const AsyncState(data: [])) {
    load();
  }

  Future<void> load() async {
    final cached = _repository.peekListCache();
    if (cached != null) {
      state = AsyncState(data: cached, loading: true, fromCache: true);
    } else {
      state = AsyncState(data: state.data, loading: true, fromCache: state.fromCache);
    }

    try {
      final result = await _repository.list();
      state = AsyncState(
        data: result.data,
        loading: false,
        fromCache: result.fromCache,
      );
    } catch (e) {
      final fallback = cached ?? state.data;
      if (fallback.isNotEmpty) {
        state = AsyncState(data: fallback, loading: false, fromCache: true);
      } else {
        state = AsyncState(
          data: state.data,
          loading: false,
          error: formatError(e),
          fromCache: state.fromCache,
        );
      }
    }
  }

  Future<void> create(Map<String, dynamic> data) async {
    try {
      await _repository.create(data);
      await load();
    } catch (e) {
      state = AsyncState(
        data: state.data,
        loading: false,
        error: formatError(e),
        fromCache: state.fromCache,
      );
    }
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    try {
      await _repository.update(id, data);
      await load();
    } catch (e) {
      state = AsyncState(
        data: state.data,
        loading: false,
        error: formatError(e),
        fromCache: state.fromCache,
      );
    }
  }

  Future<void> delete(String id) async {
    try {
      await _repository.delete(id);
      await load();
    } catch (e) {
      state = AsyncState(
        data: state.data,
        loading: false,
        error: formatError(e),
        fromCache: state.fromCache,
      );
    }
  }
}

class EventDetailState {
  final EventModel? event;
  final bool loading;
  final String? error;
  final bool fromCache;

  const EventDetailState({
    this.event,
    this.loading = true,
    this.error,
    this.fromCache = false,
  });
}

final eventDetailProvider = StateNotifierProvider.autoDispose.family<EventDetailNotifier, EventDetailState, String>((ref, id) {
  return EventDetailNotifier(ref.read(eventRepositoryProvider), id);
});

class EventDetailNotifier extends StateNotifier<EventDetailState> {
  final EventRepository _repository;
  final String _id;

  EventDetailNotifier(this._repository, this._id) : super(const EventDetailState()) {
    load();
  }

  Future<void> load() async {
    final cached = _repository.peekDetailCache(_id);
    if (cached != null) {
      state = EventDetailState(event: cached, loading: true, fromCache: true);
    } else {
      state = EventDetailState(event: state.event, loading: true, fromCache: state.fromCache);
    }

    try {
      final result = await _repository.getById(_id);
      state = EventDetailState(
        event: result.data,
        loading: false,
        fromCache: result.fromCache,
      );
    } catch (e) {
      if (cached != null || state.event != null) {
        state = EventDetailState(
          event: cached ?? state.event,
          loading: false,
          fromCache: true,
        );
      } else {
        state = EventDetailState(loading: false, error: formatError(e));
      }
    }
  }
}
