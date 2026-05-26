import '../../../core/network/api_client.dart';
import '../../../core/config/api_config.dart';
import '../domain/chat_models.dart';

class ChatApi {
  final ApiClient _client;

  ChatApi(this._client);

  Future<List<ChatRoomModel>> listRooms() async {
    final response = await _client.get(ApiConfig.chats);
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => ChatRoomModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatRoomModel> getRoom(String id) async {
    final response = await _client.get('${ApiConfig.chats}/$id');
    final data = response.data as Map<String, dynamic>;
    return ChatRoomModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<List<ChatMessageModel>> getMessages(String roomId, {int page = 1, int limit = 50}) async {
    final response = await _client.get(
      '${ApiConfig.chats}/$roomId/messages',
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMessageModel> sendMessage(String roomId, String content, {String type = 'TEXT'}) async {
    final response = await _client.post(
      '${ApiConfig.chats}/$roomId/messages',
      data: {'content': content, 'type': type},
    );
    final result = response.data as Map<String, dynamic>;
    return ChatMessageModel.fromJson(result['data'] as Map<String, dynamic>);
  }

  Future<ChatRoomModel> createDirectRoom(String otherUserId) async {
    final response = await _client.post(
      '${ApiConfig.chats}/direct',
      data: {'otherUserId': otherUserId},
    );
    final result = response.data as Map<String, dynamic>;
    return ChatRoomModel.fromJson(result['data'] as Map<String, dynamic>);
  }

  Future<void> markAsRead(String roomId) async {
    await _client.post('${ApiConfig.chats}/$roomId/read');
  }

  Future<int> getUnreadCount() async {
    final response = await _client.get(ApiConfig.chatUnread);
    final data = response.data as Map<String, dynamic>;
    return (data['data'] as Map<String, dynamic>)['unread'] as int? ?? 0;
  }
}
