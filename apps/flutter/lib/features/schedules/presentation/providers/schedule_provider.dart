import '../../../../core/network/api_client.dart';
import '../../../../core/offline/local_cache.dart';
import '../../../../core/offline/offline_mutation_queue.dart';
import '../../data/schedule_api.dart';
import '../../data/schedule_repository.dart';
import '../../domain/schedule_model.dart';
import '../../../../shared/providers/async_state.dart';
import '../../../../shared/utils/error_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final scheduleApiProvider = Provider<ScheduleApi>((ref) {
  return ScheduleApi(ref.read(apiClientProvider));
});

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository(
    ref.read(scheduleApiProvider),
    ref.read(localCacheProvider),
    ref.read(offlineMutationQueueProvider),
  );
});

final scheduleListProvider = StateNotifierProvider.autoDispose<ScheduleListNotifier, AsyncState<List<ScheduleModel>>>((ref) {
  return ScheduleListNotifier(ref.read(scheduleRepositoryProvider));
});

class ScheduleListNotifier extends StateNotifier<AsyncState<List<ScheduleModel>>> {
  final ScheduleRepository _repository;

  ScheduleListNotifier(this._repository) : super(const AsyncState(data: [])) {
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
}

class ScheduleDetailState {
  final ScheduleModel? schedule;
  final bool loading;
  final String? error;
  final bool fromCache;

  const ScheduleDetailState({
    this.schedule,
    this.loading = true,
    this.error,
    this.fromCache = false,
  });
}

final scheduleDetailProvider = StateNotifierProvider.autoDispose.family<ScheduleDetailNotifier, ScheduleDetailState, String>((ref, id) {
  return ScheduleDetailNotifier(ref.read(scheduleRepositoryProvider), id);
});

class ScheduleDetailNotifier extends StateNotifier<ScheduleDetailState> {
  final ScheduleRepository _repository;
  final String _id;

  ScheduleDetailNotifier(this._repository, this._id) : super(const ScheduleDetailState()) {
    load();
  }

  Future<void> load() async {
    final cached = _repository.peekDetailCache(_id);
    if (cached != null) {
      state = ScheduleDetailState(schedule: cached, loading: true, fromCache: true);
    } else {
      state = ScheduleDetailState(schedule: state.schedule, loading: true, fromCache: state.fromCache);
    }

    try {
      final result = await _repository.getById(_id);
      state = ScheduleDetailState(
        schedule: result.data,
        loading: false,
        fromCache: result.fromCache,
      );
    } catch (e) {
      if (cached != null || state.schedule != null) {
        state = ScheduleDetailState(
          schedule: cached ?? state.schedule,
          loading: false,
          fromCache: true,
        );
      } else {
        state = ScheduleDetailState(loading: false, error: formatError(e));
      }
    }
  }
}
