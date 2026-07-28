import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/api_config.dart';

class WebsiteApi {
  final ApiClient _client;

  WebsiteApi(this._client);

  Future<Map<String, dynamic>> getAdmin() async {
    final response = await _client.get('${ApiConfig.website}/admin');
    return _client.unwrapData(response.data);
  }

  Future<Map<String, dynamic>> save(Map<String, dynamic> content) async {
    final response = await _client.put(ApiConfig.website, data: content);
    return _client.unwrapData(response.data);
  }

  Future<Map<String, dynamic>> uploadImage({
    required String filePath,
    required String filename,
    required String kind,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: filename),
    });
    final response = await _client.upload(
      '${ApiConfig.website}/uploads',
      data: form,
      queryParameters: {'kind': kind},
    );
    return _client.unwrapData(response.data);
  }
}
