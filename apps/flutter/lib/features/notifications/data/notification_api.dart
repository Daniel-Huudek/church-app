import '../../../core/network/api_client.dart';
import '../../../core/config/api_config.dart';
import '../domain/notification_model.dart';

class NotificationApi {
  final ApiClient _client;

  NotificationApi(this._client);

  Future<List<NotificationModel>> list({int page = 1, int limit = 20}) async {
    final response = await _client.get(
      ApiConfig.notifications,
      queryParameters: {'page': page, 'limit': limit},
    );
    return _client.unwrapList(response.data, NotificationModel.fromJson);
  }

  Future<int> getUnreadCount() async {
    final response = await _client.get(ApiConfig.unreadCount);
    final data = _client.unwrapData(response.data);
    return data['unread'] as int? ?? 0;
  }

  Future<void> markAllAsRead() async {
    await _client.post(ApiConfig.notificationsRead);
  }
}
