import '../../../core/network/api_client.dart';
import '../../../core/config/api_config.dart';
import '../domain/prayer_model.dart';

class PrayerApi {
  final ApiClient _client;

  PrayerApi(this._client);

  Future<List<PrayerModel>> list({String? categoryId, bool? isUrgent}) async {
    final params = <String, dynamic>{};
    if (categoryId != null) params['categoryId'] = categoryId;
    if (isUrgent != null) params['isUrgent'] = isUrgent;

    final response = await _client.get(
      ApiConfig.prayers,
      queryParameters: params,
    );
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? data as List<dynamic>;
    return list.map((e) => PrayerModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<PrayerModel>> getMy() async {
    final response = await _client.get(ApiConfig.prayersMy);
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? data as List<dynamic>;
    return list.map((e) => PrayerModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<PrayerModel>> getUrgent() async {
    final response = await _client.get(ApiConfig.prayersUrgent);
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? data as List<dynamic>;
    return list.map((e) => PrayerModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PrayerModel> getById(String id) async {
    final response = await _client.get('${ApiConfig.prayers}/$id');
    final data = response.data as Map<String, dynamic>;
    final prayer = data['data'] as Map<String, dynamic>;
    return PrayerModel.fromJson(prayer);
  }

  Future<PrayerModel> create(Map<String, dynamic> data) async {
    final response = await _client.post(ApiConfig.prayers, data: data);
    final result = response.data as Map<String, dynamic>;
    return PrayerModel.fromJson(result['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _client.delete('${ApiConfig.prayers}/$id');
  }

  Future<List<PrayerCategory>> getCategories() async {
    final response = await _client.get(ApiConfig.prayersCategories);
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => PrayerCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PrayerComment> addComment(String prayerId, String content) async {
    final response = await _client.post(
      '${ApiConfig.prayers}/$prayerId/comments',
      data: {'content': content},
    );
    return PrayerComment.fromJson(
        (response.data as Map<String, dynamic>)['data']
            as Map<String, dynamic>);
  }

  Future<void> toggleReaction(String prayerId, String type) async {
    await _client.post(
      '${ApiConfig.prayers}/$prayerId/react',
      data: {'type': type},
    );
  }

  Future<void> toggleFavorite(String prayerId) async {
    await _client.post('${ApiConfig.prayers}/$prayerId/favorite');
  }

  Future<void> markAnswered(String prayerId) async {
    await _client.post('${ApiConfig.prayers}/$prayerId/answer');
  }
}
