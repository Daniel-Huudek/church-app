import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../providers/prayer_provider.dart';
import '../../domain/prayer_model.dart';
import '../widgets/tab_button.dart';
import '../widgets/prayer_card.dart';

class PrayerFeedScreen extends ConsumerStatefulWidget {
  const PrayerFeedScreen({super.key});

  @override
  ConsumerState<PrayerFeedScreen> createState() => _PrayerFeedScreenState();
}

class _PrayerFeedScreenState extends ConsumerState<PrayerFeedScreen> {
  int _activeTab = 0;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future(() => _load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _load() {
    if (_activeTab == 0) {
      ref.read(prayerFeedProvider.notifier).loadFeed();
    } else {
      ref.read(prayerFeedProvider.notifier).loadMine();
    }
  }

  Future<void> _onRefresh() async {
    _load();
  }

  void _editPrayer(BuildContext context, PrayerModel prayer) {
    final titleCtrl = TextEditingController(text: prayer.title);
    final contentCtrl = TextEditingController(text: prayer.content);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20, right: 20, top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Editar Pedido', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
              color: Theme.of(ctx).brightness == Brightness.dark ? Colors.white : const Color(0xFF111827))),
            const SizedBox(height: 16),
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Título', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: contentCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Pedido', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(prayerFeedProvider.notifier).update(prayer.id, {
                  'title': titleCtrl.text.trim(),
                  'content': contentCtrl.text.trim(),
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Salvar', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePrayer(BuildContext context, PrayerModel prayer, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir pedido'),
        content: Text('Tem certeza que deseja excluir "${prayer.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(prayerFeedProvider.notifier).delete(prayer.id);
    }
  }

  List<PrayerModel> _filtered(List<PrayerModel> prayers) {
    final q = _searchCtrl.text.toLowerCase().trim();
    if (q.isEmpty) return prayers;
    return prayers.where((p) {
      return p.content.toLowerCase().contains(q) ||
          p.authorName.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(prayerFeedProvider);
    final list = _filtered(state.data);
    final feedCount = state.data.length;
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightSurface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Orações',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkText
                              : AppColors.lightText)),
                  const SizedBox(height: 4),
                  Text(_countText(state.data.length),
                      style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary)),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Buscar pedidos...',
                        hintStyle: TextStyle(
                            color: isDark
                                ? const Color(0xFF6B7280)
                                : const Color(0xFF9CA3AF),
                            fontSize: 15),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                          color: isDark
                              ? const Color(0xFFF9FAFB)
                              : const Color(0xFF111827),
                          fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: TabButton(
                      label: 'Pedidos ($feedCount)',
                      isActive: _activeTab == 0,
                      isDark: isDark,
                      onTap: () {
                        setState(() => _activeTab = 0);
                        _load();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TabButton(
                      label: 'Meus (${_mineCount(state.data)})',
                      isActive: _activeTab == 1,
                      isDark: isDark,
                      onTap: () {
                        setState(() => _activeTab = 1);
                        _load();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    state.error!,
                    style: const TextStyle(
                        color: Color(0xFFEF4444), fontSize: 13),
                    textAlign: TextAlign.center,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            Expanded(
              child: state.loading
                  ? const Center(child: CircularProgressIndicator())
                  : list.isEmpty
                      ? _buildEmpty(isDark, _activeTab == 1)
                      : RefreshIndicator(
                          onRefresh: _onRefresh,
                          color: AppColors.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                            itemCount: list.length,
                            itemBuilder: (context, index) => PrayerCard(
                              prayer: list[index],
                              isDark: isDark,
                              index: index,
                              currentUserId: user?.id ?? '',
                              isAdmin: user?.role == 'ADMINISTRADOR',
                              onTap: () => context.push('/prayers/${list[index].id}'),
                              onReact: (type) {
                                ref.read(prayerApiProvider).toggleReaction(list[index].id, type);
                              },
                              onEdit: () => _editPrayer(context, list[index]),
                              onDelete: () => _deletePrayer(context, list[index], ref),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/prayers/create'),
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Image.asset('assets/images/add.png',
            width: 24, height: 24, color: Colors.white),
      ),
    );
  }

  int _mineCount(List<PrayerModel> prayers) {
    return prayers.length;
  }

  String _countText(int c) {
    if (c == 0) return 'Nenhum pedido ainda';
    if (c == 1) return '1 pedido registrado';
    return '$c pedidos registrados';
  }

  Widget _buildEmpty(bool isDark, bool isMine) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      child: ListView(
        children: [
          const SizedBox(height: 60),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.favorite_outline_rounded,
                  size: 48,
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                ),
                const SizedBox(height: 16),
                Text(
                  isMine
                      ? 'Você ainda não fez pedidos'
                      : 'Nenhum pedido de oração',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkText
                          : AppColors.lightText),
                ),
                const SizedBox(height: 4),
                Text(
                  'Compartilhe seus pedidos com a igreja',
                  style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
