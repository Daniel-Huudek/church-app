class ScheduleModel {
  final String id;
  final String? eventId;
  final String? eventName;
  final String? ministryId;
  final String? ministryName;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String status;
  final int positions;
  final int confirmed;

  const ScheduleModel({
    required this.id,
    this.eventId,
    this.eventName,
    this.ministryId,
    this.ministryName,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.status = 'PENDENTE',
    this.positions = 0,
    this.confirmed = 0,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'] as String,
      eventId: json['eventId'] as String?,
      eventName: json['eventName'] as String?,
      ministryId: json['ministryId'] as String?,
      ministryName: json['ministryName'] as String?,
      date: DateTime.parse(json['date'] as String),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      status: json['status'] as String? ?? 'PENDENTE',
      positions: json['positions'] as int? ?? 0,
      confirmed: json['confirmed'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'eventName': eventName,
    'ministryId': ministryId,
    'ministryName': ministryName,
    'date': date.toIso8601String(),
    'startTime': startTime,
    'endTime': endTime,
    'status': status,
    'positions': positions,
    'confirmed': confirmed,
  };
}

class SchedulePosition {
  final String id;
  final String scheduleId;
  final String? memberId;
  final String? memberName;
  final String? memberAvatar;
  final String position;
  final String status;

  const SchedulePosition({
    required this.id,
    required this.scheduleId,
    this.memberId,
    this.memberName,
    this.memberAvatar,
    required this.position,
    this.status = 'PENDENTE',
  });

  factory SchedulePosition.fromJson(Map<String, dynamic> json) {
    return SchedulePosition(
      id: json['id'] as String,
      scheduleId: json['scheduleId'] as String,
      memberId: json['memberId'] as String?,
      memberName: json['memberName'] as String?,
      memberAvatar: json['memberAvatar'] as String?,
      position: json['position'] as String,
      status: json['status'] as String? ?? 'PENDENTE',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'scheduleId': scheduleId,
    'memberId': memberId,
    'memberName': memberName,
    'memberAvatar': memberAvatar,
    'position': position,
    'status': status,
  };
}
