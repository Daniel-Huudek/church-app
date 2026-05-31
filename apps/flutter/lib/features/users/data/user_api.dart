import '../../../core/network/api_client.dart';
import '../../../core/config/api_config.dart';
import '../../../shared/models/user_model.dart';

class UserApi {
  final ApiClient _client;

  UserApi(this._client);

  Future<List<UserModel>> list({int page = 1, int limit = 20}) async {
    final response = await _client.get(
      ApiConfig.users,
      queryParameters: {'page': page, 'limit': limit},
    );
    return _client.unwrapList(response.data, UserModel.fromJson);
  }

  Future<UserModel> getById(String id) async {
    final response = await _client.get('${ApiConfig.users}/$id');
    return UserModel.fromJson(_client.unwrapData(response.data));
  }

  Future<UserModel> update(String id, Map<String, dynamic> data) async {
    final response = await _client.put('${ApiConfig.users}/$id', data: data);
    return UserModel.fromJson(_client.unwrapData(response.data));
  }
}
