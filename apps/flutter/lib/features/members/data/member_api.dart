import '../../../core/network/api_client.dart';
import '../../../core/config/api_config.dart';
import '../domain/member_model.dart';
import '../domain/birthday_model.dart';

class MemberApi {
  final ApiClient _client;

  MemberApi(this._client);

  Future<List<MemberModel>> list({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
    String? role,
    String? ministryId,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) params['status'] = status;
    if (search != null) params['name'] = search;
    if (role != null) params['role'] = role;
    if (ministryId != null) params['ministryId'] = ministryId;

    final response = await _client.get(
      ApiConfig.members,
      queryParameters: params,
    );
    return _client.unwrapList(response.data, MemberModel.fromJson);
  }

  Future<MemberModel> getById(String id) async {
    final response = await _client.get('${ApiConfig.members}/$id');
    return MemberModel.fromJson(_client.unwrapData(response.data));
  }

  Future<MemberModel> create(Map<String, dynamic> data) async {
    final response = await _client.post(ApiConfig.members, data: data);
    return MemberModel.fromJson(_client.unwrapData(response.data));
  }

  Future<MemberModel> update(String id, Map<String, dynamic> data) async {
    final response = await _client.put(
      '${ApiConfig.members}/$id',
      data: data,
    );
    return MemberModel.fromJson(_client.unwrapData(response.data));
  }

  Future<List<MemberModel>> search(String query) async {
    final response = await _client.get(
      ApiConfig.membersSearch,
      queryParameters: {'q': query},
    );
    return _client.unwrapList(response.data, MemberModel.fromJson);
  }

  Future<List<MinistryModel>> listMinistries() async {
    final response = await _client.get(ApiConfig.ministries);
    return _client.unwrapList(response.data, MinistryModel.fromJson);
  }

  Future<MinistryModel> createMinistry({required String name, String? description}) async {
    final response = await _client.post(
      ApiConfig.ministries,
      data: {
        'name': name,
        if (description != null) 'description': description,
      },
    );
    return MinistryModel.fromJson(_client.unwrapData(response.data));
  }

  Future<BirthdayListResult> listBirthdays({String period = 'week'}) async {
    final response = await _client.get(
      ApiConfig.membersBirthdays,
      queryParameters: {'period': period},
    );
    final data = _client.unwrapData(response.data);
    return BirthdayListResult.fromJson(data);
  }
}
