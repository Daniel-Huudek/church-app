class EventModel {
  final String id;
  final String title;
  final String? description;
  final String type;
  final DateTime date;
  final String startTime;
  final String? endTime;
  final String? location;
  final String? address;
  final String? ministryId;
  final String? ministryName;
  final String? organizerId;
  final String? organizerName;
  final String? bannerUrl;
  final String status;
  final int participants;
  final DateTime createdAt;

  const EventModel({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.date,
    required this.startTime,
    this.endTime,
    this.location,
    this.address,
    this.ministryId,
    this.ministryName,
    this.organizerId,
    this.organizerName,
    this.bannerUrl,
    this.status = 'AGENDADO',
    this.participants = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'type': type,
    'date': date.toIso8601String(),
    'startTime': startTime,
    'endTime': endTime,
    'location': location,
    'address': address,
    'ministryId': ministryId,
    'organizerId': organizerId,
  };

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: json['type'] as String? ?? 'EVENTO',
      date: DateTime.parse(json['date'] as String),
      startTime: json['startTime'] as String? ?? '00:00',
      endTime: json['endTime'] as String?,
      location: json['location'] as String?,
      address: json['address'] as String?,
      ministryId: json['ministryId'] as String?,
      ministryName: json['ministryName'] as String?,
      organizerId: json['organizerId'] as String?,
      organizerName: json['organizerName'] as String?,
      bannerUrl: json['bannerUrl'] as String?,
      status: json['status'] as String? ?? 'AGENDADO',
      participants: json['participants'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
