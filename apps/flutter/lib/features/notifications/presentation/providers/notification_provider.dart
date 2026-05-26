import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/notification_api.dart';
import '../../domain/notification_model.dart';
import '../../../../shared/providers/async_state.dart';

final notificationApiProvider = Provider<NotificationApi>((ref) {
  return NotificationApi(ref.read(apiClientProvider));
});

final notificationListProvider = StateNotifierProvider.autoDispose<NotificationListNotifier, AsyncState<List<NotificationModel>>>((ref) {
  return NotificationListNotifier(ref.read(notificationApiProvider));
});

class NotificationListNotifier extends StateNotifier<AsyncState<List<NotificationModel>>> {
  final NotificationApi _api;

  NotificationListNotifier(this._api) : super(const AsyncState(data: [])) {
    load();
  }

  Future<void> load() async {
    state = AsyncState(data: state.data, loading: true);
    try {
      final notifications = await _api.list();
      state = AsyncState(data: notifications, loading: false);
    } catch (e) {
      state = AsyncState(data: state.data, loading: false, error: e.toString());
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _api.markAllAsRead();
      await load();
    } catch (e) {
      state = AsyncState(data: state.data, loading: false, error: 'Erro ao marcar como lidas: $e');
    }
  }
}
