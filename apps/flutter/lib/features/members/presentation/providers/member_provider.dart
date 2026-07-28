import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/offline/local_cache.dart';
import '../../data/member_api.dart';
import '../../data/member_repository.dart';
import '../../domain/member_model.dart';
import '../../domain/birthday_model.dart';
import '../../../../shared/providers/async_state.dart';
import '../../../../shared/utils/error_helper.dart';

final memberApiProvider = Provider<MemberApi>((ref) {
  return MemberApi(ref.read(apiClientProvider));
});

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MemberRepository(
    ref.read(memberApiProvider),
    ref.read(localCacheProvider),
  );
});

final memberListProvider = StateNotifierProvider.autoDispose<MemberListNotifier, AsyncState<List<MemberModel>>>((ref) {
  return MemberListNotifier(ref.read(memberRepositoryProvider));
});

final ministryListProvider = FutureProvider.autoDispose<List<MinistryModel>>((ref) {
  return ref.read(memberRepositoryProvider).listMinistries();
});

class MemberListNotifier extends StateNotifier<AsyncState<List<MemberModel>>> {
  final MemberRepository _repository;

  MemberListNotifier(this._repository) : super(const AsyncState(data: [])) {
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
      final result = await _repository.list(limit: 100);
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

  Future<MemberModel> create(Map<String, dynamic> data) async {
    final member = await _repository.create(data);
    await load();
    return member;
  }

  Future<MemberModel> update(String id, Map<String, dynamic> data) async {
    final member = await _repository.update(id, data);
    await load();
    return member;
  }
}

class MemberDetailState {
  final MemberModel? member;
  final bool loading;
  final String? error;
  final bool fromCache;

  const MemberDetailState({
    this.member,
    this.loading = true,
    this.error,
    this.fromCache = false,
  });
}

final memberDetailProvider = StateNotifierProvider.autoDispose.family<MemberDetailNotifier, MemberDetailState, String>((ref, id) {
  return MemberDetailNotifier(ref.read(memberRepositoryProvider), id);
});

class MemberDetailNotifier extends StateNotifier<MemberDetailState> {
  final MemberRepository _repository;
  final String _id;

  MemberDetailNotifier(this._repository, this._id) : super(const MemberDetailState()) {
    load();
  }

  Future<void> load() async {
    final cached = _repository.peekDetailCache(_id);
    if (cached != null) {
      state = MemberDetailState(member: cached, loading: true, fromCache: true);
    } else {
      state = MemberDetailState(member: state.member, loading: true, fromCache: state.fromCache);
    }

    try {
      final result = await _repository.getById(_id);
      state = MemberDetailState(
        member: result.data,
        loading: false,
        fromCache: result.fromCache,
      );
    } catch (e) {
      if (cached != null || state.member != null) {
        state = MemberDetailState(
          member: cached ?? state.member,
          loading: false,
          fromCache: true,
        );
      } else {
        state = MemberDetailState(loading: false, error: formatError(e));
      }
    }
  }
}

final birthdayListProvider =
    StateNotifierProvider.autoDispose<BirthdayListNotifier, AsyncState<BirthdayListResult>>((ref) {
  return BirthdayListNotifier(ref.read(memberRepositoryProvider));
});

final weeklyBirthdaysProvider = FutureProvider.autoDispose<BirthdayListResult>((ref) {
  return ref.read(memberRepositoryProvider).listBirthdays(period: 'week');
});

class BirthdayListNotifier extends StateNotifier<AsyncState<BirthdayListResult>> {
  final MemberRepository _repository;

  BirthdayListNotifier(this._repository)
      : super(AsyncState(data: BirthdayListResult.empty())) {
    load('week');
  }

  Future<void> load([String period = 'week']) async {
    state = AsyncState(data: state.data, loading: true, fromCache: state.fromCache);
    try {
      final result = await _repository.listBirthdays(period: period);
      state = AsyncState(data: result, loading: false);
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
