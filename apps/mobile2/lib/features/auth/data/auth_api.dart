import '../../../core/network/api_client.dart';
import '../../../core/config/api_config.dart';

class AuthApi {
  final ApiClient _client;

  AuthApi(this._client);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _client.post(
      ApiConfig.login,
      data: {'email': email, 'password': password},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final response = await _client.post(
      ApiConfig.register,
      data: {'name': name, 'email': email, 'password': password},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> googleLogin(String idToken) async {
    final response = await _client.post(
      ApiConfig.googleLogin,
      data: {'idToken': idToken},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await _client.post(ApiConfig.logout);
  }

  Future<Map<String, dynamic>> refreshToken(String token) async {
    final response = await _client.post(
      ApiConfig.refresh,
      data: {'refreshToken': token},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _client.get(ApiConfig.me);
    return (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> data) async {
    final response = await _client.put(ApiConfig.me, data: data);
    return (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
  }
}
