class MemberAddress {
  final String? street;
  final String? number;
  final String? complement;
  final String? neighborhood;
  final String? city;
  final String? state;
  final String? zipCode;

  const MemberAddress({
    this.street,
    this.number,
    this.complement,
    this.neighborhood,
    this.city,
    this.state,
    this.zipCode,
  });

  bool get hasAny =>
      (street?.isNotEmpty ?? false) ||
      (neighborhood?.isNotEmpty ?? false) ||
      (city?.isNotEmpty ?? false) ||
      (zipCode?.isNotEmpty ?? false);

  factory MemberAddress.fromJson(Map<String, dynamic> json) {
    return MemberAddress(
      street: json['street'] as String?,
      number: json['number'] as String?,
      complement: json['complement'] as String?,
      neighborhood: json['neighborhood'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: json['zipCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'street': street,
        'number': number,
        'complement': complement,
        'neighborhood': neighborhood,
        'city': city,
        'state': state,
        'zipCode': zipCode,
      };
}

class MemberModel {
  final String id;
  final String? userId;
  final String name;
  final String? email;
  final String? phone;
  final String? avatar;
  final DateTime? birthDate;
  final String? gender;
  final String? maritalStatus;
  final String status;
  final String role;
  final String? ministryId;
  final String? ministryName;
  final List<String> ministryIds;
  final List<String> ministries;
  final DateTime? baptismDate;
  final String? baptismChurch;
  final DateTime? conversionDate;
  final DateTime? admissionDate;
  final String? admissionType;
  final bool isBaptized;
  final String? occupation;
  final String? notes;
  final MemberAddress? address;
  final DateTime createdAt;

  const MemberModel({
    required this.id,
    this.userId,
    required this.name,
    this.email,
    this.phone,
    this.avatar,
    this.birthDate,
    this.gender,
    this.maritalStatus,
    this.status = 'ATIVO',
    this.role = 'MEMBRO',
    this.ministryId,
    this.ministryName,
    this.ministryIds = const [],
    this.ministries = const [],
    this.baptismDate,
    this.baptismChurch,
    this.conversionDate,
    this.admissionDate,
    this.admissionType,
    this.isBaptized = false,
    this.occupation,
    this.notes,
    this.address,
    required this.createdAt,
  });

  String get age {
    if (birthDate == null) return '';
    final now = DateTime.now();
    final diff = now.difference(birthDate!);
    return '${(diff.inDays / 365).floor()} anos';
  }

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    final ministry = json['ministry'];
    String? ministryName;
    String? ministryId = json['ministryId'] as String?;
    if (ministry is Map) {
      ministryName = ministry['name'] as String?;
      ministryId ??= ministry['id'] as String?;
    }

    final ministryIds = <String>[];
    if (json['ministryIds'] is List) {
      for (final item in json['ministryIds'] as List) {
        final value = item?.toString();
        if (value != null && value.isNotEmpty && !ministryIds.contains(value)) {
          ministryIds.add(value);
        }
      }
    }
    if (ministryId != null && !ministryIds.contains(ministryId)) {
      ministryIds.insert(0, ministryId);
    }

    final ministries = <String>[];
    if (json['ministries'] is List) {
      for (final item in json['ministries'] as List) {
        if (item is Map && item['name'] != null) {
          final value = item['name'].toString();
          if (value.isNotEmpty && !ministries.contains(value)) ministries.add(value);
        } else {
          final value = item.toString();
          if (value.isNotEmpty && !ministries.contains(value)) ministries.add(value);
        }
      }
    }
    if (ministryName != null && !ministries.contains(ministryName)) {
      ministries.insert(0, ministryName);
    }

    return MemberModel(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      birthDate: json['dateOfBirth'] != null ? DateTime.parse(json['dateOfBirth'] as String) : null,
      gender: json['gender'] as String?,
      maritalStatus: json['maritalStatus'] as String?,
      status: json['status'] as String? ?? 'ATIVO',
      role: json['role'] as String? ?? 'MEMBRO',
      ministryId: ministryIds.isNotEmpty ? ministryIds.first : ministryId,
      ministryName: ministries.isNotEmpty ? ministries.first : ministryName,
      ministryIds: ministryIds,
      ministries: ministries,
      baptismDate: json['baptismDate'] != null ? DateTime.parse(json['baptismDate'] as String) : null,
      baptismChurch: json['baptismChurch'] as String?,
      conversionDate: json['conversionDate'] != null ? DateTime.parse(json['conversionDate'] as String) : null,
      admissionDate: json['admissionDate'] != null ? DateTime.parse(json['admissionDate'] as String) : null,
      admissionType: json['admissionType'] as String?,
      isBaptized: json['isBaptized'] as bool? ?? false,
      occupation: json['occupation'] as String?,
      notes: json['notes'] as String?,
      address: json['address'] is Map
          ? MemberAddress.fromJson(Map<String, dynamic>.from(json['address'] as Map))
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'email': email,
        'phone': phone,
        'avatar': avatar,
        'dateOfBirth': birthDate?.toIso8601String(),
        'gender': gender,
        'maritalStatus': maritalStatus,
        'status': status,
        'role': role,
        'ministryId': ministryId,
        'ministryIds': ministryIds,
        'ministries': ministries,
        'baptismDate': baptismDate?.toIso8601String(),
        'baptismChurch': baptismChurch,
        'conversionDate': conversionDate?.toIso8601String(),
        'admissionDate': admissionDate?.toIso8601String(),
        'admissionType': admissionType,
        'isBaptized': isBaptized,
        'occupation': occupation,
        'notes': notes,
        if (address != null) 'address': address!.toJson(),
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
