import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/event_api.dart';
import '../../domain/event_model.dart';
import '../../../../shared/providers/async_state.dart';

final eventApiProvider = Provider<EventApi>((ref) {
  return EventApi(ref.read(apiClientProvider));
});

final eventListProvider = StateNotifierProvider.autoDispose<EventListNotifier, AsyncState<List<EventModel>>>((ref) {
  return EventListNotifier(ref.read(eventApiProvider));
});

class EventListNotifier extends StateNotifier<AsyncState<List<EventModel>>> {
  final EventApi _api;

  EventListNotifier(this._api) : super(const AsyncState(data: [])) {
    load();
  }

  Future<void> load() async {
    state = AsyncState(data: state.data, loading: true);
    try {
      final events = await _api.list();
      state = AsyncState(data: events, loading: false);
    } catch (e) {
      state = AsyncState(data: state.data, loading: false, error: e.toString());
    }
  }

  Future<void> create(Map<String, dynamic> data) async {
    try {
      await _api.create(data);
      await load();
    } catch (e) {
      state = AsyncState(data: state.data, loading: false, error: 'Erro ao criar evento: $e');
    }
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    try {
      await _api.update(id, data);
      await load();
    } catch (e) {
      state = AsyncState(data: state.data, loading: false, error: 'Erro ao atualizar evento: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _api.delete(id);
      await load();
    } catch (e) {
      state = AsyncState(data: state.data, loading: false, error: 'Erro ao excluir evento: $e');
    }
  }
}

class EventDetailState {
  final EventModel? event;
  final bool loading;
  final String? error;

  const EventDetailState({this.event, this.loading = true, this.error});
}

final eventDetailProvider = StateNotifierProvider.autoDispose.family<EventDetailNotifier, EventDetailState, String>((ref, id) {
  return EventDetailNotifier(ref.read(eventApiProvider), id);
});

class EventDetailNotifier extends StateNotifier<EventDetailState> {
  final EventApi _api;
  final String _id;

  EventDetailNotifier(this._api, this._id) : super(const EventDetailState()) {
    load();
  }

  Future<void> load() async {
    state = EventDetailState(event: state.event, loading: true);
    try {
      final event = await _api.getById(_id);
      state = EventDetailState(event: event, loading: false);
    } catch (e) {
      state = EventDetailState(loading: false, error: e.toString());
    }
  }
}
