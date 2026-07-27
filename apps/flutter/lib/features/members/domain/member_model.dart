class MemberModel {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? avatar;
  final DateTime? birthDate;
  final String? gender;
  final String? maritalStatus;
  final String status;
  final String role;
  final List<String> ministries;
  final DateTime? baptismDate;
  final DateTime? conversionDate;
  final DateTime createdAt;

  const MemberModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.avatar,
    this.birthDate,
    this.gender,
    this.maritalStatus,
    this.status = 'ATIVO',
    this.role = 'MEMBRO',
    this.ministries = const [],
    this.baptismDate,
    this.conversionDate,
    required this.createdAt,
  });

  String get age {
    if (birthDate == null) return '';
    final now = DateTime.now();
    final diff = now.difference(birthDate!);
    return '${(diff.inDays / 365).floor()} anos';
  }

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      birthDate: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'] as String)
          : null,
      gender: json['gender'] as String?,
      maritalStatus: json['maritalStatus'] as String?,
      status: json['status'] as String? ?? 'ATIVO',
      role: json['role'] as String? ?? 'MEMBRO',
      ministries: (json['ministries'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      baptismDate: json['baptismDate'] != null
          ? DateTime.parse(json['baptismDate'] as String)
          : null,
      conversionDate: json['conversionDate'] != null
          ? DateTime.parse(json['conversionDate'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'avatar': avatar,
    'dateOfBirth': birthDate?.toIso8601String(),
    'gender': gender,
    'maritalStatus': maritalStatus,
    'status': status,
    'role': role,
    'ministries': ministries,
    'baptismDate': baptismDate?.toIso8601String(),
    'conversionDate': conversionDate?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };
}

class MinistryModel {
  final String id;
  final String name;
  final String? description;
  final String? leaderId;

  const MinistryModel({
    required this.id,
    required this.name,
    this.description,
    this.leaderId,
  });

  factory MinistryModel.fromJson(Map<String, dynamic> json) {
    return MinistryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      leaderId: json['leaderId'] as String?,
    );
  }
}
