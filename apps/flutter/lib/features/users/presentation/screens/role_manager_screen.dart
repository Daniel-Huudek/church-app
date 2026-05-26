import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  ];

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
          content: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Cargos salvos com sucesso!'),
          ]),
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
        content: const Text('Isso vai restaurar as permissões padrão de todos os cargos. As personalizações serão perdidas.'),
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

  Color _roleColor(String name) {
    final colors = {
      'ADMINISTRADOR': const Color(0xFFEF4444),
      'PASTOR': const Color(0xFF8B5CF6),
      'FINANCEIRO': const Color(0xFF10B981),
      'LIDER': const Color(0xFFF59E0B),
      'LIDER_LOUVOR': const Color(0xFF3B82F6),
      'LOUVOR': const Color(0xFFEC4899),
      'MEMBRO': const Color(0xFF06B6D4),
      'VISITANTE': const Color(0xFF6B7280),
    };
    return colors[name] ?? const Color(0xFF008CFF);
  }

  IconData _roleIcon(String name) {
    final icons = {
      'ADMINISTRADOR': Icons.shield_rounded,
      'PASTOR': Icons.church_rounded,
      'FINANCEIRO': Icons.account_balance_rounded,
      'LIDER': Icons.star_rounded,
      'LIDER_LOUVOR': Icons.music_note_rounded,
      'LOUVOR': Icons.music_note_rounded,
      'MEMBRO': Icons.person_rounded,
      'VISITANTE': Icons.visibility_rounded,
    };
    return icons[name] ?? Icons.badge_rounded;
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
        title: const Text('Cargos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded, color: Color(0xFFEF4444), size: 22),
            onPressed: _reset,
            tooltip: 'Resetar',
          ),
          IconButton(
            icon: const Icon(Icons.check_rounded, color: Color(0xFF008CFF), size: 26),
            onPressed: _save,
            tooltip: 'Salvar',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  height: 90,
                  color: isDark ? const Color(0xFF161622) : Colors.white,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: _roles.map((r) {
                      final selected = _selectedRole == r.name;
                      final color = _roleColor(r.name);
                      return GestureDetector(
                        onTap: () => setState(() => _selectedRole = r.name),
                        child: Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? color.withValues(alpha: 0.15) : (isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF9FAFB)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected ? color : (isDark ? const Color(0xFF2D2D44) : const Color(0xFFE5E7EB)),
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_roleIcon(r.name), color: color, size: 22),
                              const SizedBox(height: 5),
                              Text(r.name.replaceAll('_', ' ').split(' ').map((w) => w[0]).join(),
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: selected ? color : (isDark ? Colors.white : const Color(0xFF6B7280))),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: _selectedRole == null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.touch_app_rounded, size: 48, color: isDark ? const Color(0xFF6B7280) : const Color(0xFFD1D5DB)),
                              const SizedBox(height: 12),
                              Text('Selecione um cargo acima',
                                style: TextStyle(fontSize: 15, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF))),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: _roleColor(_selectedRole!).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(_roleIcon(_selectedRole!), color: _roleColor(_selectedRole!), size: 22),
                                ),
                                const SizedBox(width: 12),
                                Text(_selectedRole!.replaceAll('_', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' '),
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF111827))),
                              ],
                            ),
                            const SizedBox(height: 24),
                            ..._modules.map((module) {
                              final key = module.$1;
                              final icon = module.$2;
                              final label = module.$3;
                              final role = _roles.where((r) => r.name == _selectedRole).toList();
                              final canWrite = role.isNotEmpty && role.first.permissions.contains('${key}_write');
                              final canDelete = role.isNotEmpty && role.first.permissions.contains('${key}_delete');
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF161622) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: isDark ? const Color(0xFF2D2D44) : const Color(0xFFF3F4F6)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: _roleColor(_selectedRole!).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(icon, size: 18, color: _roleColor(_selectedRole!)),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(label,
                                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF111827))),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          _permChip('Criar / Editar', '${key}_write', canWrite, isDark),
                                          const SizedBox(width: 10),
                                          _permChip('Excluir', '${key}_delete', canDelete, isDark),
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

  Widget _permChip(String label, String perm, bool checked, bool isDark) {
    return GestureDetector(
      onTap: () => _togglePermission(_selectedRole!, perm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
            Icon(
              checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: checked ? Colors.white : (isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
            ),
            const SizedBox(width: 6),
            Text(label,
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: checked ? Colors.white : (isDark ? Colors.white : const Color(0xFF111827)),
              )),
          ],
        ),
      ),
    );
  }
}
