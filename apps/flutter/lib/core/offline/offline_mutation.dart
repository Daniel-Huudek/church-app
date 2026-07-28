enum OfflineMutationType {
  scheduleConfirm,
  worshipConfirm,
}

class OfflineMutation {
  final String id;
  final OfflineMutationType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  const OfflineMutation({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
  });

  String get dedupeKey {
    switch (type) {
      case OfflineMutationType.scheduleConfirm:
        return 'schedule_confirm:${payload['scheduleId']}:${payload['positionId']}';
      case OfflineMutationType.worshipConfirm:
        return 'worship_confirm:${payload['worshipEventId']}:${payload['memberId']}';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
      };

  factory OfflineMutation.fromJson(Map<String, dynamic> json) {
    return OfflineMutation(
      id: json['id'] as String,
      type: OfflineMutationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => OfflineMutationType.scheduleConfirm,
      ),
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class MutationOutcome {
  final bool queued;

  const MutationOutcome({this.queued = false});
}
