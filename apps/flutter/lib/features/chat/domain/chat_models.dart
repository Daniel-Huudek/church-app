class ChatRoomModel {
  final String id;
  final String? name;
  final String type;
  final int unreadCount;
  final String? lastMessage;
  final DateTime updatedAt;

  const ChatRoomModel({
    required this.id,
    this.name,
    required this.type,
    this.unreadCount = 0,
    this.lastMessage,
    required this.updatedAt,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      type: json['type'] as String? ?? 'DIRECT',
      unreadCount: json['unreadCount'] as int? ?? 0,
      lastMessage: json['lastMessage'] as String?,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'unreadCount': unreadCount,
    'lastMessage': lastMessage,
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class ChatMessageModel {
  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final String type;
  final DateTime createdAt;

  const ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    this.type = 'TEXT',
    required this.createdAt,
  });

  bool get isMine => false;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      type: json['type'] as String? ?? 'TEXT',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'roomId': roomId,
    'senderId': senderId,
    'content': content,
    'type': type,
    'createdAt': createdAt.toIso8601String(),
  };
}
