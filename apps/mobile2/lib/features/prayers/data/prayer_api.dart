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
    final list = _parseList(response.data);
    return list.map((e) => PrayerModel.fromJson(e)).toList();
  }

  List<Map<String, dynamic>> _parseList(dynamic data) {
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    if (data is Map<String, dynamic>) {
      var inner = data['data'];
      if (inner is Map) {
        inner = inner['data'];
      }
      if (inner is List) return inner.cast<Map<String, dynamic>>();
      if (inner == null) return [];
    }
    throw FormatException('Tipo inesperado: ${data.runtimeType}, valor: $data');
  }

  Map<String, dynamic> _parseItem(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data.containsKey('success') && data.containsKey('data')) {
        final inner = data['data'];
        if (inner is Map<String, dynamic>) {
          if (inner.containsKey('data') && inner['data'] is Map) {
            return inner['data'] as Map<String, dynamic>;
          }
          return inner;
        }
      }
      return data;
    }
    throw FormatException('Unexpected response format: $data');
  }

  Future<List<PrayerModel>> getMy() async {
    final response = await _client.get(ApiConfig.prayersMy);
    final list = _parseList(response.data);
    return list.map((e) => PrayerModel.fromJson(e)).toList();
  }

  Future<List<PrayerModel>> getUrgent() async {
    final response = await _client.get(ApiConfig.prayersUrgent);
    final list = _parseList(response.data);
    return list.map((e) => PrayerModel.fromJson(e)).toList();
  }

  Future<PrayerModel> getById(String id) async {
    final response = await _client.get('${ApiConfig.prayers}/$id');
    final item = _parseItem(response.data);
    return PrayerModel.fromJson(item);
  }

  Future<PrayerModel> create(Map<String, dynamic> data) async {
    final response = await _client.post(ApiConfig.prayers, data: data);
    final item = _parseItem(response.data);
    return PrayerModel.fromJson(item);
  }

  Future<void> delete(String id) async {
    await _client.delete('${ApiConfig.prayers}/$id');
  }

  Future<List<PrayerComment>> getComments(String prayerId) async {
    final response = await _client.get(
      '${ApiConfig.prayers}/$prayerId/comments',
    );
    final list = _parseList(response.data);
    return list.map((e) => PrayerComment.fromJson(e)).toList();
  }

  Future<List<PrayerCategory>> getCategories() async {
    final response = await _client.get(ApiConfig.prayersCategories);
    final list = _parseList(response.data);
    return list.map((e) => PrayerCategory.fromJson(e)).toList();
  }

  Future<PrayerComment> addComment(String prayerId, String content) async {
    final response = await _client.post(
      '${ApiConfig.prayers}/$prayerId/comments',
      data: {'content': content},
    );
    final item = _parseItem(response.data);
    return PrayerComment.fromJson(item);
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
