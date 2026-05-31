import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../data/role_definitions.dart';

class RoleManagerScreen extends ConsumerStatefulWidget {
  const RoleManagerScreen({super.key});

  @override
  ConsumerState<RoleManagerScreen> createState() => _RoleManagerScreenState();
}

class _RoleManagerScreenState extends ConsumerState<RoleManagerScreen> {
  List<RoleDefinition> _roles = [];
  bool _loading = true;
  String? _selectedRole;

  static const _modules = [
    ('users', Icons.people_rounded, 'Usuários'),
    ('members', Icons.person_search_rounded, 'Membros'),
    ('events', Icons.event_rounded, 'Eventos'),
    ('prayers', Icons.menu_book_rounded, 'Orações'),
    ('finance', Icons.account_balance_rounded, 'Financeiro'),
    ('schedules', Icons.assignment_rounded, 'Escalas'),
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
    'LIDER_LOUVOR': 'Líder Louvor', 'LOUVOR': 'Louvor',
    'MEMBRO': 'Membro', 'VISITANTE': 'Visitante',
  };

  static const _roleIcons = <String, IconData>{
    'ADMINISTRADOR': Icons.shield_rounded, 'PASTOR': Icons.church_rounded,
    'FINANCEIRO': Icons.account_balance_rounded, 'LIDER': Icons.star_rounded,
    'LIDER_LOUVOR': Icons.music_note_rounded, 'LOUVOR': Icons.music_note_rounded,
    'MEMBRO': Icons.person_rounded, 'VISITANTE': Icons.visibility_rounded,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final client = ref.read(apiClientProvider);
    _roles = await RoleDefinitionsService.load(client);
    if (_selectedRole == null && _roles.isNotEmpty) _selectedRole = _roles[0].name;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final client = ref.read(apiClientProvider);
    await RoleDefinitionsService.save(client, _roles);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cargos salvos com sucesso!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _reset() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Resetar cargos?'),
        content: const Text('Isso vai restaurar as permissões padrão de todos os cargos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Resetar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final client = ref.read(apiClientProvider);
    await RoleDefinitionsService.resetToDefaults(client);
    _roles = await RoleDefinitionsService.load(client);
    if (mounted) setState(() {});
  }

  void _togglePermission(String roleName, String perm) {
    setState(() {
      final role = _roles.where((r) => r.name == roleName).toList();
      if (role.isNotEmpty) {
        if (role.first.permissions.contains(perm)) {
          role.first.permissions.remove(perm);
        } else {
          role.first.permissions.add(perm);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0D14) : const Color(0xFFF8F6F1);
    final accent = AppColors.primary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Cargos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        centerTitle: true,
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.restart_alt_rounded, color: const Color(0xFFEF4444)),
            onPressed: _reset,
            tooltip: 'Resetar',
          ),
          IconButton(
            icon: Icon(Icons.check_rounded, color: accent),
            onPressed: _save,
            tooltip: 'Salvar',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Role selector
                SizedBox(
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    children: _roles.map((r) {
                      final selected = _selectedRole == r.name;
                      final color = _roleColors[r.name] ?? const Color(0xFF6B7280);
                      return GestureDetector(
                        onTap: () => setState(() => _selectedRole = r.name),
                        child: Container(
                          width: 76,
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? color.withValues(alpha: 0.12) : (isDark ? const Color(0xFF16161F) : Colors.white),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected ? color : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04)),
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_roleIcons[r.name] ?? Icons.badge_rounded, color: color, size: 22),
                              const SizedBox(height: 4),
                              Text(
                                _roleLabels[r.name]?.split('').where((c) => c.toUpperCase() == c && c != ' ').join() ?? r.name[0],
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                  color: selected ? color : (isDark ? Colors.white60 : Colors.black45)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Permissions
                Expanded(
                  child: _selectedRole == null
                      ? Center(child: Text('Selecione um cargo',
                          style: TextStyle(fontSize: 15, color: isDark ? Colors.white38 : Colors.black26)))
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: (_roleColors[_selectedRole!] ?? const Color(0xFF6B7280)).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(_roleIcons[_selectedRole!] ?? Icons.badge_rounded,
                                    color: _roleColors[_selectedRole!] ?? const Color(0xFF6B7280), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _roleLabels[_selectedRole!] ?? _selectedRole!,
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ..._modules.map((m) {
                              final key = m.$1;
                              final icon = m.$2;
                              final label = m.$3;
                              final role = _roles.where((r) => r.name == _selectedRole).toList();
                              final canWrite = role.isNotEmpty && role.first.permissions.contains('${key}_write');
                              final canDelete = role.isNotEmpty && role.first.permissions.contains('${key}_delete');
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF16161F) : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
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
                                              color: (_roleColors[_selectedRole!] ?? accent).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(icon, size: 16,
                                              color: _roleColors[_selectedRole!] ?? accent),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(label,
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8, runSpacing: 8,
                                        children: [
                                          _permChip('Criar / Editar', '${key}_write', canWrite),
                                          _permChip('Excluir', '${key}_delete', canDelete),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
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
    final accent = AppColors.primary;
    return GestureDetector(
      onTap: () => _togglePermission(_selectedRole!, perm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: checked ? accent : (isDark ? const Color(0xFF0D0D14) : const Color(0xFFF8F6F1)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: checked ? accent : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 16,
              color: checked ? Colors.white : (isDark ? Colors.white30 : Colors.black26),
            ),
            const SizedBox(width: 6),
            Text(label,
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: checked ? Colors.white : (isDark ? Colors.white60 : Colors.black45),
              )),
          ],
        ),
      ),
    );
  }
}
