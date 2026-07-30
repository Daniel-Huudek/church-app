import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/router/app_routes.dart';
import '../../domain/hinario_models.dart';
import '../providers/hinario_provider.dart';

class HinarioHomeScreen extends ConsumerStatefulWidget {
  const HinarioHomeScreen({super.key});

  @override
  ConsumerState<HinarioHomeScreen> createState() => _HinarioHomeScreenState();
}

class _HinarioHomeScreenState extends ConsumerState<HinarioHomeScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CtpHymn> _filter(List<CtpHymn> hymns) {
    if (_query.isEmpty) return hymns;
    final q = _query.toLowerCase().trim();
    return hymns.where((h) {
      return h.number.toLowerCase().contains(q) ||
          h.title.toLowerCase().contains(q) ||
          h.lyrics.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightSurface;
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final accent = AppColors.primary;
    final accentLight = accent.withValues(alpha: 0.12);
    final hymnsAsync = ref.watch(hinarioListProvider);

    return Scaffold(
      backgroundColor: bg,
      body: hymnsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: isDark ? Colors.white30 : Colors.black26),
                const SizedBox(height: 16),
                Text(
                  'Não foi possível carregar o hinário.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.invalidate(hinarioListProvider),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
        data: (hymns) {
          final filtered = _filter(hymns);
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 110,
                floating: false,
                pinned: true,
                backgroundColor: bg,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 12),
                  title: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hinário',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Cantai Todos os Povos',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: accent,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SearchHeaderDelegate(
                  bg: surface,
                  isDark: isDark,
                  query: _query,
                  onChanged: (v) => setState(() => _query = v),
                  controller: _searchCtrl,
                  accent: accent,
                  accentLight: accentLight,
                ),
              ),
              if (_query.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: accentLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${hymns.length} hinos',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: accent,
                          ),
                        ),
                        Icon(Icons.library_music_rounded,
                            size: 16, color: accent),
                      ],
                    ),
                  ),
                ),
              if (_query.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final hymn = filtered[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _HymnListTile(
                            hymn: hymn,
                            isDark: isDark,
                            surface: surface,
                            accent: accent,
                            accentLight: accentLight,
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final hymn = filtered[index];
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => context.go(
                              AppRoutes.hinarioHymn(hymn.number),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF16161F)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : Colors.black.withValues(alpha: 0.04),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                hymn.number,
                                style: TextStyle(
                                  fontSize: hymn.number.length > 3 ? 13 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF1A1A2E),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Color bg;
  final bool isDark;
  final String query;
  final ValueChanged<String> onChanged;
  final TextEditingController controller;
  final Color accent;
  final Color accentLight;

  _SearchHeaderDelegate({
    required this.bg,
    required this.isDark,
    required this.query,
    required this.onChanged,
    required this.controller,
    required this.accent,
    required this.accentLight,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
          hintText: 'Buscar por número ou título...',
          hintStyle:
              TextStyle(color: accent.withValues(alpha: 0.5), fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: accent, size: 20),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                  color: accent,
                )
              : null,
          filled: true,
          fillColor: accentLight,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 56;

  @override
  double get minExtent => 56;

  @override
  bool shouldRebuild(covariant _SearchHeaderDelegate old) =>
      query != old.query || bg != old.bg;
}

class _HymnListTile extends StatelessWidget {
  final CtpHymn hymn;
  final bool isDark;
  final Color surface;
  final Color accent;
  final Color accentLight;

  const _HymnListTile({
    required this.hymn,
    required this.isDark,
    required this.surface,
    required this.accent,
    required this.accentLight,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.go(AppRoutes.hinarioHymn(hymn.number)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.04),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 40,
                decoration: BoxDecoration(
                  color: accentLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  hymn.number,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hymn.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white38 : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
