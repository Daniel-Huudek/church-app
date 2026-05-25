import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/schedule_api.dart';
import '../../domain/schedule_model.dart';

final scheduleApiProvider = Provider<ScheduleApi>((ref) {
  return ScheduleApi(ref.read(apiClientProvider));
});

class ScheduleListState {
  final List<ScheduleModel> schedules;
  final bool loading;
  final String? error;
  final bool created;

  const ScheduleListState({
    this.schedules = const [],
    this.loading = true,
    this.error,
    this.created = false,
  });
}

final scheduleListProvider = StateNotifierProvider.autoDispose<ScheduleListNotifier, ScheduleListState>((ref) {
  return ScheduleListNotifier(ref.read(scheduleApiProvider));
});

class ScheduleListNotifier extends StateNotifier<ScheduleListState> {
  final ScheduleApi _api;

  ScheduleListNotifier(this._api) : super(const ScheduleListState()) {
    load();
  }

  Future<void> load() async {
    state = ScheduleListState(schedules: state.schedules, loading: true);
    try {
      final schedules = await _api.list();
      state = ScheduleListState(schedules: schedules, loading: false);
    } catch (e) {
      state = ScheduleListState(schedules: state.schedules, loading: false, error: e.toString());
    }
  }

  Future<void> create(Map<String, dynamic> data) async {
    await _api.create(data);
    state = ScheduleListState(schedules: state.schedules, loading: false, created: true);
    await load();
  }
}

class ScheduleDetailState {
  final ScheduleModel? schedule;
  final bool loading;
  final String? error;

  const ScheduleDetailState({this.schedule, this.loading = true, this.error});
}

final scheduleDetailProvider = StateNotifierProvider.autoDispose.family<ScheduleDetailNotifier, ScheduleDetailState, String>((ref, id) {
  return ScheduleDetailNotifier(ref.read(scheduleApiProvider), id);
});

class ScheduleDetailNotifier extends StateNotifier<ScheduleDetailState> {
  final ScheduleApi _api;
  final String _id;

  ScheduleDetailNotifier(this._api, this._id) : super(const ScheduleDetailState()) {
    load();
  }

  Future<void> load() async {
    state = ScheduleDetailState(schedule: state.schedule, loading: true);
    try {
      final schedule = await _api.getById(_id);
      state = ScheduleDetailState(schedule: schedule, loading: false);
    } catch (e) {
      state = ScheduleDetailState(loading: false, error: e.toString());
    }
  }
}
