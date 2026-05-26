import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/chat_api.dart';
import '../../domain/chat_models.dart';
import '../../../../shared/providers/async_state.dart';
import '../../../../shared/utils/error_helper.dart';

final chatApiProvider = Provider<ChatApi>((ref) {
  return ChatApi(ref.read(apiClientProvider));
});

final chatRoomListProvider = StateNotifierProvider.autoDispose<ChatRoomListNotifier, AsyncState<List<ChatRoomModel>>>((ref) {
  return ChatRoomListNotifier(ref.read(chatApiProvider));
});

class ChatRoomListNotifier extends StateNotifier<AsyncState<List<ChatRoomModel>>> {
  final ChatApi _api;

  ChatRoomListNotifier(this._api) : super(const AsyncState(data: [])) {
    load();
  }

  Future<void> load() async {
    state = AsyncState(data: state.data, loading: true);
    try {
      final rooms = await _api.listRooms();
      state = AsyncState(data: rooms, loading: false);
    } catch (e) {
      state = AsyncState(data: state.data, loading: false, error: formatError(e));
    }
  }
}

class ChatMessagesState {
  final List<ChatMessageModel> messages;
  final bool loading;
  final String? error;

  const ChatMessagesState({
    this.messages = const [],
    this.loading = true,
    this.error,
  });
}

final chatMessagesProvider = StateNotifierProvider.autoDispose.family<ChatMessagesNotifier, ChatMessagesState, String>((ref, roomId) {
  return ChatMessagesNotifier(ref.read(chatApiProvider), roomId);
});

class ChatMessagesNotifier extends StateNotifier<ChatMessagesState> {
  final ChatApi _api;
  final String _roomId;

  ChatMessagesNotifier(this._api, this._roomId) : super(const ChatMessagesState()) {
    load();
  }

  Future<void> load() async {
    state = ChatMessagesState(messages: state.messages, loading: true);
    try {
      final messages = await _api.getMessages(_roomId);
      state = ChatMessagesState(messages: messages.reversed.toList(), loading: false);
    } catch (e) {
      state = ChatMessagesState(messages: state.messages, loading: false, error: formatError(e));
    }
  }

  Future<void> send(String content) async {
    try {
      await _api.sendMessage(_roomId, content);
      await _api.markAsRead(_roomId);
      await load();
    } catch (e) {
      state = ChatMessagesState(messages: state.messages, loading: false, error: formatError(e));
    }
  }
}
