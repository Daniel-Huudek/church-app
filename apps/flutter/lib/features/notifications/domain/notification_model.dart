class NotificationModel {
  final String id;
  final String type;
  final String recipientId;
  final String message;
  final String status;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.recipientId,
    required this.message,
    this.status = 'PENDING',
    required this.createdAt,
  });

  bool get isUnread => status == 'PENDING';

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'GENERAL',
      recipientId: json['recipientId'] as String,
      message: json['message'] as String,
      status: json['status'] as String? ?? 'PENDING',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
