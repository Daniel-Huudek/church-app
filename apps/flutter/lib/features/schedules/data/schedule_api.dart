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
    return _client.unwrapList(response.data, ScheduleModel.fromJson);
  }

  Future<ScheduleModel> getById(String id) async {
    final response = await _client.get('${ApiConfig.schedules}/$id');
    return ScheduleModel.fromJson(_client.unwrapData(response.data));
  }

  Future<ScheduleModel> create(Map<String, dynamic> data) async {
    final response = await _client.post(ApiConfig.schedules, data: data);
    return ScheduleModel.fromJson(_client.unwrapData(response.data));
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
