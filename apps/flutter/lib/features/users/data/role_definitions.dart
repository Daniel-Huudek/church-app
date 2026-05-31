import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class RoleDefinition {
  final String name;
  List<String> permissions;

  RoleDefinition({required this.name, required this.permissions});

  factory RoleDefinition.fromJson(Map<String, dynamic> j) =>
      RoleDefinition(name: j['name'] as String, permissions: List<String>.from(j['permissions'] as List));
}

class RoleDefinitionsService {
  static Future<List<RoleDefinition>> load(ApiClient client) async {
    try {
      final res = await client.get('/users/roles');
      final list = ((res.data as Map)['data'] as List?) ?? [];
      return list.map((e) => RoleDefinition.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return _defaults();
    }
  }

  static Future<void> save(ApiClient client, List<RoleDefinition> roles) async {
    for (final r in roles) {
      await client.put('/users/roles/${r.name}', data: {'permissions': r.permissions});
    }
  }

  static Future<void> resetToDefaults(ApiClient client) async {
    await client.post('/users/roles/reset');
  }

  static List<String> getPermissionsForRole(List<RoleDefinition> roles, String roleName) {
    final role = roles.where((r) => r.name == roleName).toList();
    if (role.isNotEmpty) return role.first.permissions;
    return [];
  }

  static List<RoleDefinition> _defaults() => [
    RoleDefinition(name: 'ADMINISTRADOR', permissions: ['users_read','users_write','users_delete','members_read','members_write','members_delete','events_read','events_write','events_delete','prayers_read','prayers_write','prayers_delete','finance_read','finance_write','finance_delete','schedules_read','schedules_write']),
    RoleDefinition(name: 'PASTOR', permissions: ['users_read','users_write','users_delete','members_read','members_write','members_delete','events_read','events_write','events_delete','prayers_read','prayers_write','prayers_delete','finance_read','finance_write','finance_delete','schedules_read','schedules_write']),
    RoleDefinition(name: 'FINANCEIRO', permissions: ['members_read','events_read','prayers_read','schedules_read','finance_read','finance_write','finance_delete']),
    RoleDefinition(name: 'LIDER', permissions: ['members_read','members_write','members_delete','events_read','events_write','events_delete','prayers_read','prayers_write','prayers_delete','schedules_read','schedules_write']),
    RoleDefinition(name: 'LIDER_LOUVOR', permissions: ['events_read','events_write','events_delete','schedules_read']),
    RoleDefinition(name: 'LOUVOR', permissions: ['events_read','schedules_read']),
    RoleDefinition(name: 'MEMBRO', permissions: ['events_read','prayers_read','prayers_write','prayers_delete','schedules_read']),
    RoleDefinition(name: 'VISITANTE', permissions: ['events_read','prayers_read','prayers_write']),
  ];
}
