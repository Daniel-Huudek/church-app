class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final String role;
  final List<String> permissions;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.role = 'MEMBRO',
    this.permissions = const [],
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatar: json['avatar'] as String?,
      role: json['role'] as String? ?? 'MEMBRO',
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
