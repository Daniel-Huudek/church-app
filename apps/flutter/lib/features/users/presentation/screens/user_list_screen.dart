import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../providers/user_provider.dart';

class UserListScreen extends ConsumerStatefulWidget {
  const UserListScreen({super.key});

  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0D14) : const Color(0xFFF8F6F1);
    final accent = AppColors.primary;
    final state = ref.watch(userListProvider);

    var users = state.data;
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      users = users.where((u) =>
        u.name.toLowerCase().contains(q) || u.email.toLowerCase().contains(q)
      ).toList();
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Usuários',
                    style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${users.length}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accent),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => context.push('/users/roles'),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.admin_panel_settings_rounded, size: 20, color: accent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Buscar usuário...',
                  hintStyle: TextStyle(fontSize: 14, color: isDark ? Colors.white30 : Colors.black26),
                  prefixIcon: Icon(Icons.search_rounded, size: 20,
                    color: isDark ? Colors.white38 : Colors.black38),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF16161F) : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : const Color(0xFF1A1A2E)),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: state.loading
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null
                      ? Center(child: Text('Erro: ${state.error}',
                          style: TextStyle(color: isDark ? Colors.white60 : Colors.black45)))
                      : users.isEmpty
                          ? _empty(isDark)
                          : RefreshIndicator(
                              onRefresh: () => ref.read(userListProvider.notifier).load(),
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                                itemCount: users.length,
                                itemBuilder: (_, i) => _UserTile(
                                  user: users[i],
                                  onTap: () => context.push('/users/${users[i].id}/edit'),
                                  isDark: isDark,
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline_rounded, size: 48,
            color: isDark ? Colors.white24 : Colors.black12),
          const SizedBox(height: 12),
          Text(_query.isEmpty ? 'Nenhum usuário encontrado' : 'Nenhum resultado para "$_query"',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
              color: isDark ? Colors.white38 : Colors.black26)),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final dynamic user;
  final VoidCallback onTap;
  final bool isDark;

  const _UserTile({required this.user, required this.onTap, required this.isDark});

  static const _roleColors = <String, Color>{
    'ADMINISTRADOR': Color(0xFFEF4444),
    'PASTOR': Color(0xFF8B5CF6),
    'FINANCEIRO': Color(0xFF10B981),
    'LIDER': Color(0xFFF59E0B),
    'LIDER_LOUVOR': Color(0xFF3B82F6),
    'LOUVOR': Color(0xFFEC4899),
    'MEMBRO': Color(0xFF06B6D4),
    'VISITANTE': Color(0xFF6B7280),
  };

  static const _roleLabels = <String, String>{
    'ADMINISTRADOR': 'Admin', 'PASTOR': 'Pastor', 'FINANCEIRO': 'Financeiro',
    'LIDER': 'Líder', 'LIDER_LOUVOR': 'Líder Louvor', 'LOUVOR': 'Louvor',
    'MEMBRO': 'Membro', 'VISITANTE': 'Visitante',
  };

  Color get _color => _roleColors[user.role] ?? const Color(0xFF6B7280);
  String get _label => _roleLabels[user.role] ?? user.role;
  String get _initial => user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF16161F) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _color.withValues(alpha: 0.15),
                  child: Text(_initial,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _color)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                      const SizedBox(height: 2),
                      Text(user.email,
                        style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(_label,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _color)),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, size: 18,
                  color: isDark ? Colors.white24 : Colors.black12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
