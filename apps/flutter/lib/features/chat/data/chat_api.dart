import '../../../core/network/api_client.dart';
import '../../../core/config/api_config.dart';
import '../domain/chat_models.dart';

class ChatApi {
  final ApiClient _client;

  ChatApi(this._client);

  Future<List<ChatRoomModel>> listRooms() async {
    final response = await _client.get(ApiConfig.chats);
    return _client.unwrapList(response.data, ChatRoomModel.fromJson);
  }

  Future<ChatRoomModel> getRoom(String id) async {
    final response = await _client.get('${ApiConfig.chats}/$id');
    return ChatRoomModel.fromJson(_client.unwrapData(response.data));
  }

  Future<List<ChatMessageModel>> getMessages(String roomId, {int page = 1, int limit = 50}) async {
    final response = await _client.get(
      '${ApiConfig.chats}/$roomId/messages',
      queryParameters: {'page': page, 'limit': limit},
    );
    return _client.unwrapList(response.data, ChatMessageModel.fromJson);
  }

  Future<ChatMessageModel> sendMessage(String roomId, String content, {String type = 'TEXT'}) async {
    final response = await _client.post(
      '${ApiConfig.chats}/$roomId/messages',
      data: {'content': content, 'type': type},
    );
    return ChatMessageModel.fromJson(_client.unwrapData(response.data));
  }

  Future<ChatRoomModel> createDirectRoom(String otherUserId) async {
    final response = await _client.post(
      '${ApiConfig.chats}/direct',
      data: {'otherUserId': otherUserId},
    );
    return ChatRoomModel.fromJson(_client.unwrapData(response.data));
  }

  Future<void> markAsRead(String roomId) async {
    await _client.post('${ApiConfig.chats}/$roomId/read');
  }

  Future<int> getUnreadCount() async {
    final response = await _client.get(ApiConfig.chatUnread);
    final data = _client.unwrapData(response.data);
    return data['unread'] as int? ?? 0;
  }

  Future<ChatRoomModel> findOrCreateMinistryRoom(String ministry) async {
    final response = await _client.post('${ApiConfig.chats}/ministry', data: {'ministry': ministry});
    return ChatRoomModel.fromJson(_client.unwrapData(response.data));
  }
}
