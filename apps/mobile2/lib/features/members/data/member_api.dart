import '../../../core/network/api_client.dart';
import '../../../core/config/api_config.dart';
import '../domain/member_model.dart';

class MemberApi {
  final ApiClient _client;

  MemberApi(this._client);

  Future<List<MemberModel>> list({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) params['status'] = status;
    if (search != null) params['name'] = search;

    final response = await _client.get(
      ApiConfig.members,
      queryParameters: params,
    );
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => MemberModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MemberModel> getById(String id) async {
    final response = await _client.get('${ApiConfig.members}/$id');
    final data = response.data as Map<String, dynamic>;
    return MemberModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<MemberModel> create(Map<String, dynamic> data) async {
    final response = await _client.post(ApiConfig.members, data: data);
    final result = response.data as Map<String, dynamic>;
    return MemberModel.fromJson(result['data'] as Map<String, dynamic>);
  }

  Future<MemberModel> update(String id, Map<String, dynamic> data) async {
    final response = await _client.put(
      '${ApiConfig.members}/$id',
      data: data,
    );
    final result = response.data as Map<String, dynamic>;
    return MemberModel.fromJson(result['data'] as Map<String, dynamic>);
  }

  Future<List<MemberModel>> search(String query) async {
    final response = await _client.get(
      ApiConfig.membersSearch,
      queryParameters: {'q': query},
    );
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => MemberModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
