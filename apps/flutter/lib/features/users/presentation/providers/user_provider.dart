import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/user_api.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/async_state.dart';
import '../../../../shared/utils/error_helper.dart';

final userApiProvider = Provider<UserApi>((ref) {
  return UserApi(ref.read(apiClientProvider));
});

final userListProvider = StateNotifierProvider.autoDispose<UserListNotifier, AsyncState<List<UserModel>>>((ref) {
  return UserListNotifier(ref.read(userApiProvider));
});

class UserListNotifier extends StateNotifier<AsyncState<List<UserModel>>> {
  final UserApi _api;

  UserListNotifier(this._api) : super(const AsyncState(data: [])) {
    load();
  }

  Future<void> load() async {
    state = AsyncState(data: state.data, loading: true);
    try {
      final users = await _api.list();
      state = AsyncState(data: users, loading: false);
    } catch (e) {
      state = AsyncState(data: state.data, loading: false, error: formatError(e));
    }
  }
}

final userDetailProvider = StateNotifierProvider.autoDispose.family<UserDetailNotifier, AsyncState<UserModel?>, String>((ref, id) {
  return UserDetailNotifier(ref.read(userApiProvider), id);
});

class UserDetailNotifier extends StateNotifier<AsyncState<UserModel?>> {
  final UserApi _api;
  final String _id;

  UserDetailNotifier(this._api, this._id) : super(const AsyncState(data: null)) {
    load();
  }

  Future<void> load() async {
    state = AsyncState(data: state.data, loading: true);
    try {
      final user = await _api.getById(_id);
      state = AsyncState(data: user, loading: false);
    } catch (e) {
      state = AsyncState(data: null, loading: false, error: formatError(e));
    }
  }

  Future<void> update(Map<String, dynamic> data) async {
    try {
      await _api.update(_id, data);
      await load();
    } catch (e) {
      state = AsyncState(data: state.data, loading: false, error: formatError(e));
    }
  }
}
