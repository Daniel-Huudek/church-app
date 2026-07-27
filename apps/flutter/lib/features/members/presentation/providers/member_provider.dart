import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/member_api.dart';
import '../../domain/member_model.dart';
import '../../domain/birthday_model.dart';
import '../../../../shared/providers/async_state.dart';
import '../../../../shared/utils/error_helper.dart';

final memberApiProvider = Provider<MemberApi>((ref) {
  return MemberApi(ref.read(apiClientProvider));
});

final memberListProvider = StateNotifierProvider.autoDispose<MemberListNotifier, AsyncState<List<MemberModel>>>((ref) {
  return MemberListNotifier(ref.read(memberApiProvider));
});

final ministryListProvider = FutureProvider.autoDispose<List<MinistryModel>>((ref) {
  return ref.read(memberApiProvider).listMinistries();
});

class MemberListNotifier extends StateNotifier<AsyncState<List<MemberModel>>> {
  final MemberApi _api;

  MemberListNotifier(this._api) : super(const AsyncState(data: [])) {
    load();
  }

  Future<void> load() async {
    state = AsyncState(data: state.data, loading: true);
    try {
      final members = await _api.list();
      state = AsyncState(data: members, loading: false);
    } catch (e) {
      state = AsyncState(data: state.data, loading: false, error: formatError(e));
    }
  }
}

class MemberDetailState {
  final MemberModel? member;
  final bool loading;
  final String? error;

  const MemberDetailState({this.member, this.loading = true, this.error});
}

final memberDetailProvider = StateNotifierProvider.autoDispose.family<MemberDetailNotifier, MemberDetailState, String>((ref, id) {
  return MemberDetailNotifier(ref.read(memberApiProvider), id);
});

class MemberDetailNotifier extends StateNotifier<MemberDetailState> {
  final MemberApi _api;
  final String _id;

  MemberDetailNotifier(this._api, this._id) : super(const MemberDetailState()) {
    load();
  }

  Future<void> load() async {
    state = MemberDetailState(member: state.member, loading: true);
    try {
      final member = await _api.getById(_id);
      state = MemberDetailState(member: member, loading: false);
    } catch (e) {
      state = MemberDetailState(loading: false, error: formatError(e));
    }
  }
}

final birthdayListProvider =
    StateNotifierProvider.autoDispose<BirthdayListNotifier, AsyncState<BirthdayListResult>>((ref) {
  return BirthdayListNotifier(ref.read(memberApiProvider));
});

final weeklyBirthdaysProvider = FutureProvider.autoDispose<BirthdayListResult>((ref) {
  return ref.read(memberApiProvider).listBirthdays(period: 'week');
});

class BirthdayListNotifier extends StateNotifier<AsyncState<BirthdayListResult>> {
  final MemberApi _api;

  BirthdayListNotifier(this._api)
      : super(AsyncState(data: BirthdayListResult.empty())) {
    load('week');
  }

  Future<void> load([String period = 'week']) async {
    state = AsyncState(data: state.data, loading: true);
    try {
      final result = await _api.listBirthdays(period: period);
      state = AsyncState(data: result, loading: false);
    } catch (e) {
      state = AsyncState(data: state.data, loading: false, error: formatError(e));
    }
  }
}
