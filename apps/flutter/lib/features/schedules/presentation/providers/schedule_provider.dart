import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/schedule_api.dart';
import '../../domain/schedule_model.dart';
import '../../../../shared/providers/async_state.dart';

final scheduleApiProvider = Provider<ScheduleApi>((ref) {
  return ScheduleApi(ref.read(apiClientProvider));
});

final scheduleListProvider = StateNotifierProvider.autoDispose<ScheduleListNotifier, AsyncState<List<ScheduleModel>>>((ref) {
  return ScheduleListNotifier(ref.read(scheduleApiProvider));
});

class ScheduleListNotifier extends StateNotifier<AsyncState<List<ScheduleModel>>> {
  final ScheduleApi _api;

  ScheduleListNotifier(this._api) : super(const AsyncState(data: [])) {
    load();
  }

  Future<void> load() async {
    state = AsyncState(data: state.data, loading: true);
    try {
      final schedules = await _api.list();
      state = AsyncState(data: schedules, loading: false);
    } catch (e) {
      state = AsyncState(data: state.data, loading: false, error: e.toString());
    }
  }

  Future<void> create(Map<String, dynamic> data) async {
    try {
      await _api.create(data);
      await load();
    } catch (e) {
      state = AsyncState(data: state.data, loading: false, error: e.toString());
    }
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
