import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/user_api.dart';
import '../../../../shared/models/user_model.dart';

final userApiProvider = Provider<UserApi>((ref) {
  return UserApi(ref.read(apiClientProvider));
});

class UserListState {
  final List<UserModel> users;
  final bool loading;
  final String? error;

  const UserListState({
    this.users = const [],
    this.loading = true,
    this.error,
  });
}

final userListProvider = StateNotifierProvider.autoDispose<UserListNotifier, UserListState>((ref) {
  return UserListNotifier(ref.read(userApiProvider));
});

class UserListNotifier extends StateNotifier<UserListState> {
  final UserApi _api;

  UserListNotifier(this._api) : super(const UserListState()) {
    load();
  }

  Future<void> load() async {
    state = UserListState(users: state.users, loading: true);
    try {
      final users = await _api.list();
      state = UserListState(users: users, loading: false);
    } catch (e) {
      state = UserListState(users: state.users, loading: false, error: e.toString());
    }
  }
}

class UserDetailState {
  final UserModel? user;
  final bool loading;
  final String? error;

  const UserDetailState({this.user, this.loading = true, this.error});
}

final userDetailProvider = StateNotifierProvider.autoDispose.family<UserDetailNotifier, UserDetailState, String>((ref, id) {
  return UserDetailNotifier(ref.read(userApiProvider), id);
});

class UserDetailNotifier extends StateNotifier<UserDetailState> {
  final UserApi _api;
  final String _id;

  UserDetailNotifier(this._api, this._id) : super(const UserDetailState()) {
    load();
  }

  Future<void> load() async {
    state = UserDetailState(user: state.user, loading: true);
    try {
      final user = await _api.getById(_id);
      state = UserDetailState(user: user, loading: false);
    } catch (e) {
      state = UserDetailState(loading: false, error: e.toString());
    }
  }

  Future<void> update(Map<String, dynamic> data) async {
    try {
      await _api.update(_id, data);
      await load();
    } catch (e) {
      state = UserDetailState(user: state.user, loading: false, error: 'Erro ao atualizar: $e');
    }
  }
}
