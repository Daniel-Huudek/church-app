import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/event_api.dart';
import '../../domain/event_model.dart';

final eventApiProvider = Provider<EventApi>((ref) {
  return EventApi(ref.read(apiClientProvider));
});

class EventListState {
  final List<EventModel> events;
  final bool loading;
  final String? error;

  const EventListState({
    this.events = const [],
    this.loading = true,
    this.error,
  });
}

final eventListProvider = StateNotifierProvider.autoDispose<EventListNotifier, EventListState>((ref) {
  return EventListNotifier(ref.read(eventApiProvider));
});

class EventListNotifier extends StateNotifier<EventListState> {
  final EventApi _api;

  EventListNotifier(this._api) : super(const EventListState()) {
    load();
  }

  Future<void> load() async {
    state = EventListState(events: state.events, loading: true);
    try {
      final events = await _api.list();
      state = EventListState(events: events, loading: false);
    } catch (e) {
      state = EventListState(events: state.events, loading: false, error: e.toString());
    }
  }

  Future<void> create(Map<String, dynamic> data) async {
    try {
      await _api.create(data);
      await load();
    } catch (e) {
      state = EventListState(events: state.events, loading: false, error: 'Erro ao criar evento: $e');
    }
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    try {
      await _api.update(id, data);
      await load();
    } catch (e) {
      state = EventListState(events: state.events, loading: false, error: 'Erro ao atualizar evento: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _api.delete(id);
      await load();
    } catch (e) {
      state = EventListState(events: state.events, loading: false, error: 'Erro ao excluir evento: $e');
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
