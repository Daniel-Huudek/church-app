import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
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
            ?.map((e) => e.toString())
            .toList() ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar: $e'), backgroundColor: Colors.red),
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
          const SnackBar(content: Text('Usuário atualizado!')),
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
                  child: const Center(
                    child: Text('📷', style: TextStyle(fontSize: 32)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Função: $_selectedRole',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF111827))),
                const SizedBox(height: 16),
                Text('Permissões',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF6B7280))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allPermissions.map((perm) {
                    final checked = _selectedPermissions.contains(perm);
                    return _permChip(perm.replaceAll('_', ' '), perm, checked);
                  }).toList(),
                ),
              ],
            ),
    );
  }

  static const _allPermissions = [
    'users_read', 'users_write', 'users_delete',
    'members_read', 'members_write', 'members_delete',
    'events_read', 'events_write', 'events_delete',
    'finance_read', 'finance_write', 'finance_reports',
    'prayers_read', 'prayers_write',
    'schedules_read', 'schedules_write',
    'notifications_send',
  ];

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
