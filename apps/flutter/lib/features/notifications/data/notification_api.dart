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
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final response = await _client.get(ApiConfig.unreadCount);
    final data = response.data as Map<String, dynamic>;
    return (data['data'] as Map<String, dynamic>)['unread'] as int? ?? 0;
  }

  Future<void> markAllAsRead() async {
    await _client.post(ApiConfig.notificationsRead);
  }
}
