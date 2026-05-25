import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/notification_api.dart';
import '../../domain/notification_model.dart';

final notificationApiProvider = Provider<NotificationApi>((ref) {
  return NotificationApi(ref.read(apiClientProvider));
});

class NotificationListState {
  final List<NotificationModel> notifications;
  final bool loading;
  final String? error;
  final int unreadCount;

  const NotificationListState({
    this.notifications = const [],
    this.loading = true,
    this.error,
    this.unreadCount = 0,
  });
}

final notificationListProvider = StateNotifierProvider.autoDispose<NotificationListNotifier, NotificationListState>((ref) {
  return NotificationListNotifier(ref.read(notificationApiProvider));
});

class NotificationListNotifier extends StateNotifier<NotificationListState> {
  final NotificationApi _api;

  NotificationListNotifier(this._api) : super(const NotificationListState()) {
    load();
  }

  Future<void> load() async {
    state = NotificationListState(notifications: state.notifications, loading: true);
    try {
      final notifications = await _api.list();
      final unreadCount = notifications.where((n) => n.isUnread).length;
      state = NotificationListState(notifications: notifications, loading: false, unreadCount: unreadCount);
    } catch (e) {
      state = NotificationListState(notifications: state.notifications, loading: false, error: e.toString());
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _api.markAllAsRead();
      await load();
    } catch (e) {
      state = NotificationListState(notifications: state.notifications, loading: false, unreadCount: state.unreadCount, error: 'Erro ao marcar como lidas: $e');
    }
  }
}
