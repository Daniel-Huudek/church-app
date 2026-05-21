import '../../../core/network/api_client.dart';
import '../../../core/config/api_config.dart';
import '../domain/schedule_model.dart';

class ScheduleApi {
  final ApiClient _client;

  ScheduleApi(this._client);

  Future<List<ScheduleModel>> list({int page = 1}) async {
    final response = await _client.get(
      ApiConfig.schedules,
      queryParameters: {'page': page},
    );
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? data as List<dynamic>;
    return list
        .map((e) => ScheduleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ScheduleModel> getById(String id) async {
    final response = await _client.get('${ApiConfig.schedules}/$id');
    final data = response.data as Map<String, dynamic>;
    return ScheduleModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<ScheduleModel> create(Map<String, dynamic> data) async {
    final response = await _client.post(ApiConfig.schedules, data: data);
    final result = response.data as Map<String, dynamic>;
    return ScheduleModel.fromJson(result['data'] as Map<String, dynamic>);
  }

  Future<void> confirmPresence(String scheduleId, String positionId) async {
    await _client.post(
      '${ApiConfig.schedules}/confirm',
      data: {
        'scheduleId': scheduleId,
        'positionId': positionId,
      },
    );
  }
}
