import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/member_api.dart';
import '../../domain/member_model.dart';

final memberApiProvider = Provider<MemberApi>((ref) {
  return MemberApi(ref.read(apiClientProvider));
});

class MemberListState {
  final List<MemberModel> members;
  final bool loading;
  final String? error;

  const MemberListState({
    this.members = const [],
    this.loading = true,
    this.error,
  });
}

final memberListProvider = StateNotifierProvider.autoDispose<MemberListNotifier, MemberListState>((ref) {
  return MemberListNotifier(ref.read(memberApiProvider));
});

class MemberListNotifier extends StateNotifier<MemberListState> {
  final MemberApi _api;

  MemberListNotifier(this._api) : super(const MemberListState()) {
    load();
  }

  Future<void> load() async {
    state = MemberListState(members: state.members, loading: true);
    try {
      final members = await _api.list();
      state = MemberListState(members: members, loading: false);
    } catch (e) {
      state = MemberListState(members: state.members, loading: false, error: e.toString());
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
      state = MemberDetailState(loading: false, error: e.toString());
    }
  }
}
