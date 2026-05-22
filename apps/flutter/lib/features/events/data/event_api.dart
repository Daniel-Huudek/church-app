import '../../../core/network/api_client.dart';
import '../../../core/config/api_config.dart';
import '../domain/event_model.dart';

class EventApi {
  final ApiClient _client;

  EventApi(this._client);

  Future<List<EventModel>> list({
    DateTime? startDate,
    DateTime? endDate,
    String? type,
  }) async {
    final params = <String, dynamic>{};
    if (startDate != null) params['startDate'] = startDate.toIso8601String();
    if (endDate != null) params['endDate'] = endDate.toIso8601String();
    if (type != null) params['type'] = type;

    final response = await _client.get(
      ApiConfig.events,
      queryParameters: params,
    );
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<EventModel> getById(String id) async {
    final response = await _client.get('${ApiConfig.events}/$id');
    final data = response.data as Map<String, dynamic>;
    return EventModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<EventModel> create(Map<String, dynamic> data) async {
    final response = await _client.post(ApiConfig.events, data: data);
    final result = response.data as Map<String, dynamic>;
    return EventModel.fromJson(result['data'] as Map<String, dynamic>);
  }

  Future<EventModel> update(String id, Map<String, dynamic> data) async {
    final response = await _client.put('${ApiConfig.events}/$id', data: data);
    final result = response.data as Map<String, dynamic>;
    return EventModel.fromJson(result['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _client.delete('${ApiConfig.events}/$id');
  }

  Future<List<String>> getTypes() async {
    final response = await _client.get(ApiConfig.eventTypes);
    final data = response.data as Map<String, dynamic>;
    return (data['data'] as List<dynamic>).cast<String>();
  }
}
