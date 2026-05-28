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
    return _client.unwrapList(response.data, EventModel.fromJson);
  }

  Future<EventModel> getById(String id) async {
    final response = await _client.get('${ApiConfig.events}/$id');
    return EventModel.fromJson(_client.unwrapData(response.data));
  }

  Future<EventModel> create(Map<String, dynamic> data) async {
    final response = await _client.post(ApiConfig.events, data: data);
    return EventModel.fromJson(_client.unwrapData(response.data));
  }

  Future<EventModel> update(String id, Map<String, dynamic> data) async {
    final response = await _client.put('${ApiConfig.events}/$id', data: data);
    return EventModel.fromJson(_client.unwrapData(response.data));
  }

  Future<void> delete(String id) async {
    await _client.delete('${ApiConfig.events}/$id');
  }

  Future<List<String>> getTypes() async {
    final response = await _client.get(ApiConfig.eventTypes);
    final list = _client.unwrapList(response.data, (m) => m['value'] as String);
    return list.map((e) => e.toString()).toList();
  }
}
