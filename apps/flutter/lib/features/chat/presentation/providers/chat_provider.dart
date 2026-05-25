import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/chat_api.dart';
import '../../domain/chat_models.dart';

final chatApiProvider = Provider<ChatApi>((ref) {
  return ChatApi(ref.read(apiClientProvider));
});

class ChatRoomListState {
  final List<ChatRoomModel> rooms;
  final bool loading;
  final String? error;

  const ChatRoomListState({
    this.rooms = const [],
    this.loading = true,
    this.error,
  });
}

final chatRoomListProvider = StateNotifierProvider.autoDispose<ChatRoomListNotifier, ChatRoomListState>((ref) {
  return ChatRoomListNotifier(ref.read(chatApiProvider));
});

class ChatRoomListNotifier extends StateNotifier<ChatRoomListState> {
  final ChatApi _api;

  ChatRoomListNotifier(this._api) : super(const ChatRoomListState()) {
    load();
  }

  Future<void> load() async {
    state = ChatRoomListState(rooms: state.rooms, loading: true);
    try {
      final rooms = await _api.listRooms();
      state = ChatRoomListState(rooms: rooms, loading: false);
    } catch (e) {
      state = ChatRoomListState(rooms: state.rooms, loading: false, error: e.toString());
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
      state = ChatMessagesState(messages: state.messages, loading: false, error: e.toString());
    }
  }

  Future<void> send(String content) async {
    try {
      await _api.sendMessage(_roomId, content);
      await _api.markAsRead(_roomId);
      await load();
    } catch (_) {}
  }
}
