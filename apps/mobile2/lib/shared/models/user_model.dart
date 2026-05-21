class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final String role;
  final List<String> permissions;
  final List<String> ministries;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    required this.role,
    this.permissions = const [],
    this.ministries = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAdmin => role == 'ADMINISTRADOR';
  bool get isPastor => role == 'PASTOR';
  bool get isFinanceiro => role == 'FINANCEIRO';
  bool get isLider => role == 'LIDER';
  bool get isMembro => role == 'MEMBRO';

  bool hasPermission(String permission) => permissions.contains(permission);
  bool hasAnyRole(List<String> roles) => roles.contains(role);

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      role: json['role'] as String? ?? 'MEMBRO',
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      ministries: (json['ministries'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'avatar': avatar,
        'role': role,
        'permissions': permissions,
        'ministries': ministries,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
