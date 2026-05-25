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
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<UserModel> getById(String id) async {
    final response = await _client.get('${ApiConfig.users}/$id');
    final data = response.data as Map<String, dynamic>;
    return UserModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<UserModel> update(String id, Map<String, dynamic> data) async {
    final response = await _client.put('${ApiConfig.users}/$id', data: data);
    final result = response.data as Map<String, dynamic>;
    return UserModel.fromJson(result['data'] as Map<String, dynamic>);
  }
}
