import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../providers/user_provider.dart';

class UserEditScreen extends ConsumerStatefulWidget {
  final String userId;
  const UserEditScreen({super.key, required this.userId});

  @override
  ConsumerState<UserEditScreen> createState() => _UserEditScreenState();
}

class _UserEditScreenState extends ConsumerState<UserEditScreen> {
  bool _loading = false;
  bool _saving = false;
  String _selectedRole = 'MEMBRO';
  List<String> _selectedPermissions = [];
  Map<String, dynamic>? _user;

  static const _roles = [
    'ADMINISTRADOR', 'PASTOR', 'FINANCEIRO', 'LIDER',
    'LIDER_LOUVOR', 'LOUVOR', 'MEMBRO', 'VISITANTE',
  ];

  static const _roleColors = <String, Color>{
    'ADMINISTRADOR': Color(0xFFEF4444), 'PASTOR': Color(0xFF8B5CF6),
    'FINANCEIRO': Color(0xFF10B981), 'LIDER': Color(0xFFF59E0B),
    'LIDER_LOUVOR': Color(0xFF3B82F6), 'LOUVOR': Color(0xFFEC4899),
    'MEMBRO': Color(0xFF06B6D4), 'VISITANTE': Color(0xFF6B7280),
  };

  static const _roleLabels = <String, String>{
    'ADMINISTRADOR': 'Administrador', 'PASTOR': 'Pastor',
    'FINANCEIRO': 'Financeiro', 'LIDER': 'Líder',
    'LIDER_LOUVOR': 'Líder de Louvor', 'LOUVOR': 'Louvor',
    'MEMBRO': 'Membro', 'VISITANTE': 'Visitante',
  };

  static const _allPermissions = [
    'users_read', 'users_write', 'users_delete',
    'members_read', 'members_write', 'members_delete',
    'events_read', 'events_write', 'events_delete',
    'finance_read', 'finance_write', 'finance_reports',
    'prayers_read', 'prayers_write',
    'schedules_read', 'schedules_write',
    'notifications_send',
  ];

  static const _permLabels = <String, String>{
    'users_read': 'Ver usuários', 'users_write': 'Criar/Editar usuários', 'users_delete': 'Excluir usuários',
    'members_read': 'Ver membros', 'members_write': 'Criar/Editar membros', 'members_delete': 'Excluir membros',
    'events_read': 'Ver eventos', 'events_write': 'Criar/Editar eventos', 'events_delete': 'Excluir eventos',
    'finance_read': 'Ver finanças', 'finance_write': 'Lançar', 'finance_reports': 'Relatórios',
    'prayers_read': 'Ver orações', 'prayers_write': 'Responder orações',
    'schedules_read': 'Ver escalas', 'schedules_write': 'Gerenciar escalas',
    'notifications_send': 'Enviar notificações',
  };

  static const _permGroups = [
    ('users', Icons.people_rounded, 'Usuários', ['users_read', 'users_write', 'users_delete']),
    ('members', Icons.person_search_rounded, 'Membros', ['members_read', 'members_write', 'members_delete']),
    ('events', Icons.event_rounded, 'Eventos', ['events_read', 'events_write', 'events_delete']),
    ('finance', Icons.account_balance_rounded, 'Financeiro', ['finance_read', 'finance_write', 'finance_reports']),
    ('prayers', Icons.menu_book_rounded, 'Orações', ['prayers_read', 'prayers_write']),
    ('schedules', Icons.assignment_rounded, 'Escalas', ['schedules_read', 'schedules_write']),
    ('notifications', Icons.notifications_rounded, 'Notificações', ['notifications_send']),
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _loading = true);
    try {
      final response = await ref.read(apiClientProvider).get('/users/${widget.userId}');
      final data = response.data as Map<String, dynamic>;
      final userData = data['data'] as Map<String, dynamic>? ?? data;
      setState(() {
        _user = userData;
        _selectedRole = userData['role'] as String? ?? 'MEMBRO';
        _selectedPermissions = (userData['permissions'] as List<dynamic>?)
            ?.map((e) => e.toString()).toList() ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(apiClientProvider).put('/users/${widget.userId}', data: {'role': _selectedRole});
      await ref.read(apiClientProvider).put('/users/${widget.userId}/permissions', data: {'permissions': _selectedPermissions});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário atualizado!'), backgroundColor: Color(0xFF10B981)),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _togglePermission(String permission) {
    setState(() {
      if (_selectedPermissions.contains(permission)) {
        _selectedPermissions.remove(permission);
      } else {
        _selectedPermissions.add(permission);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0D14) : const Color(0xFFF8F6F1);
    final accent = AppColors.primary;
    final name = _user?['name'] as String? ?? 'Editar Usuário';
    final email = _user?['email'] as String? ?? '';
    final roleColor = _roleColors[_selectedRole] ?? const Color(0xFF6B7280);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        centerTitle: true,
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(
              _saving ? 'Salvando…' : 'Salvar',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: accent),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
              children: [
                // User header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF16161F) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: roleColor.withValues(alpha: 0.15),
                        child: Text(initial,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: roleColor)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                            const SizedBox(height: 2),
                            Text(email,
                              style: TextStyle(fontSize: 14, color: isDark ? Colors.white38 : Colors.black38)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Role section
                Text('Função', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF16161F) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
                    ),
                  ),
                  child: Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _roles.map((role) {
                      final selected = role == _selectedRole;
                      final color = _roleColors[role] ?? const Color(0xFF6B7280);
                      return GestureDetector(
                        onTap: () => setState(() => _selectedRole = role),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected ? color : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
                            ),
                          ),
                          child: Text(
                            _roleLabels[role] ?? role,
                            style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: selected ? color : (isDark ? Colors.white60 : Colors.black45),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Permissions
                Text('Permissões', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                ..._permGroups.map((group) {
                  final module = group.$1;
                  final icon = group.$2;
                  final label = group.$3;
                  final perms = group.$4;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF16161F) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(icon, size: 16, color: accent),
                              ),
                              const SizedBox(width: 10),
                              Text(label,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6, runSpacing: 6,
                            children: perms.map((perm) {
                              final checked = _selectedPermissions.contains(perm);
                              return GestureDetector(
                                onTap: () => _togglePermission(perm),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: checked ? accent : (isDark ? const Color(0xFF0D0D14) : const Color(0xFFF8F6F1)),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: checked ? accent : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (checked)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 4),
                                          child: Icon(Icons.check_rounded, size: 14, color: Colors.white),
                                        ),
                                      Text(
                                        _permLabels[perm] ?? perm,
                                        style: TextStyle(
                                          fontSize: 11, fontWeight: FontWeight.w600,
                                          color: checked ? Colors.white : (isDark ? Colors.white60 : Colors.black45),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
