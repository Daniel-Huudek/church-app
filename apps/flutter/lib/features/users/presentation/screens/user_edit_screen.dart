import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../data/role_definitions.dart';

class UserEditScreen extends ConsumerStatefulWidget {
  final String userId;
  const UserEditScreen({super.key, required this.userId});

  @override
  ConsumerState<UserEditScreen> createState() => _UserEditScreenState();
}

class _UserEditScreenState extends ConsumerState<UserEditScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;
  bool _saving = false;
  String _selectedRole = 'MEMBRO';
  List<String> _selectedPermissions = [];
  List<RoleDefinition> _roleDefs = [];

  static const _roles = ['ADMINISTRADOR', 'PASTOR', 'FINANCEIRO', 'LIDER', 'LIDER_LOUVOR', 'LOUVOR', 'MEMBRO', 'VISITANTE'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _roleDefs = await RoleDefinitionsService.load(ref.read(apiClientProvider));
      final res = await ref.read(apiClientProvider).get('/users/${widget.userId}');
      final data = (res.data as Map)['data'] as Map<String, dynamic>;
      final role = data['role'] as String? ?? 'MEMBRO';
      final perms = (data['permissions'] as List?)?.cast<String>() ?? [];
      setState(() {
        _user = data;
        _selectedRole = role;
        _selectedPermissions = perms.isNotEmpty ? perms : RoleDefinitionsService.getPermissionsForRole(_roleDefs, role);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _onRoleChanged(String role) {
    setState(() {
      _selectedRole = role;
      _selectedPermissions = List.from(RoleDefinitionsService.getPermissionsForRole(_roleDefs, role));
    });
  }

  void _togglePermission(String perm) {
    setState(() {
      if (_selectedPermissions.contains(perm)) {
        _selectedPermissions.remove(perm);
      } else {
        _selectedPermissions.add(perm);
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(apiClientProvider).put('/users/${widget.userId}', data: {'role': _selectedRole});
      await ref.read(apiClientProvider).put('/users/${widget.userId}/permissions', data: {'permissions': _selectedPermissions});
      if (mounted) context.pop();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF008CFF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF008CFF), size: 24),
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(_user?['name'] as String? ?? 'Editar',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF111827))),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Salvando...' : 'Salvar',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF008CFF))),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161622) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFF2D2D44) : const Color(0xFFF3F4F6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF008CFF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.badge_rounded, size: 16, color: Color(0xFF008CFF)),
                        ),
                        const SizedBox(width: 10),
                        Text('Cargo',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF111827))),
                      ]),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _roles.map((r) {
                          final selected = _selectedRole == r;
                          return GestureDetector(
                            onTap: () => _onRoleChanged(r),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? const Color(0xFF008CFF) : (isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF9FAFB)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected ? const Color(0xFF008CFF) : (isDark ? const Color(0xFF2D2D44) : const Color(0xFFE5E7EB)),
                                ),
                              ),
                              child: Text(r,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                  color: selected ? Colors.white : (isDark ? Colors.white : const Color(0xFF111827)))),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161622) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFF2D2D44) : const Color(0xFFF3F4F6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF008CFF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.security_rounded, size: 16, color: Color(0xFF008CFF)),
                        ),
                        const SizedBox(width: 10),
                        Text('Permissões (${_selectedRole})',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF111827))),
                        const Spacer(),
                        Text('${_selectedPermissions.length}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF008CFF))),
                      ]),
                      const SizedBox(height: 12),
                      ...['users', 'members', 'events', 'prayers', 'finance'].expand((module) {
                        final moduleName = module[0].toUpperCase() + module.substring(1);
                        final write = '${module}_write';
                        final del = '${module}_delete';
                        final hasWrite = _selectedPermissions.contains(write);
                        final hasDel = _selectedPermissions.contains(del);
                        return [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(moduleName,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF))),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12, left: 8),
                            child: Row(children: [
                              _permChip('Criar / Editar', write, hasWrite),
                              const SizedBox(width: 8),
                              _permChip('Excluir', del, hasDel),
                            ]),
                          ),
                        ];
                      }),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _permChip(String label, String perm, bool checked) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _togglePermission(perm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: checked ? const Color(0xFF008CFF) : (isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF9FAFB)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: checked ? const Color(0xFF008CFF) : (isDark ? const Color(0xFF2D2D44) : const Color(0xFFE5E7EB)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (checked)
              const Icon(Icons.check_rounded, color: Colors.white, size: 16),
            if (checked) const SizedBox(width: 4),
            Text(label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: checked ? Colors.white : (isDark ? Colors.white : const Color(0xFF111827)))),
          ],
        ),
      ),
    );
  }
}
