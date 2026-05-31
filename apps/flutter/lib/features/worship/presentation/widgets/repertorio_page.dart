import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/router/app_routes.dart';
import '../../domain/worship_models.dart';
import '../providers/worship_provider.dart';
import 'segmented_tab.dart';

class RepertorioPage extends ConsumerStatefulWidget {
  final bool isDark;
  final int repertorioTab;
  final ValueChanged<int> onTabChanged;
  final bool canCreate;

  const RepertorioPage({
    super.key,
    required this.isDark,
    required this.repertorioTab,
    required this.onTabChanged,
    required this.canCreate,
  });

  @override
  ConsumerState<RepertorioPage> createState() => _RepertorioPageState();
}

class _RepertorioPageState extends ConsumerState<RepertorioPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(songsProvider);
    final isDark = widget.isDark;
    final repertorioTab = widget.repertorioTab;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text('Repertório',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: const Color(0xFF008CFF))),
              ),
              const SizedBox(height: 20),
              SegmentedTab(
                isDark: isDark, currentTab: repertorioTab, onTabChanged: widget.onTabChanged,
                labels: const ['Músicas', 'Artistas'],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: repertorioTab == 0 ? _buildMusicas(isDark, songsAsync) : _buildArtistas(isDark),
              ),
            ],
          ),
        ),
        if (widget.canCreate)
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20, bottom: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.worshipRepertorioFetch),
                    child: Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(Icons.language_rounded, color: Colors.white, size: 26),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.worshipRepertorioCreate),
                    child: Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMusicas(bool isDark, AsyncValue<List<Song>> songsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? const Color(0xFF2D2D44) : const Color(0xFFE5E7EB)),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF111827)),
            decoration: InputDecoration(
              hintText: 'Buscar músicas...',
              hintStyle: TextStyle(color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
              prefixIcon: Icon(Icons.search_rounded, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: songsAsync.when(
            data: (songs) {
              final query = _searchCtrl.text.toLowerCase();
              final filtered = query.isEmpty
                  ? songs
                  : songs.where((s) =>
                      s.title.toLowerCase().contains(query) ||
                      (s.artist?.toLowerCase().contains(query) ?? false)).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    query.isEmpty ? 'Nenhuma música cadastrada' : 'Nenhuma música encontrada',
                    style: TextStyle(color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
                  ),
                );
              }

              return ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final song = filtered[i];
                  return GestureDetector(
                    onTap: () => context.push('/worship/songs/${song.id}'),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF161622) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2D2D44) : const Color(0xFFE5E7EB), width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 8, offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF008CFF).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.music_note_rounded, color: Color(0xFF008CFF), size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(song.title,
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF111827))),
                                if (song.artist != null) ...[
                                  const SizedBox(height: 3),
                                  Text(song.artist!,
                                    style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF))),
                                ],
                              ],
                            ),
                          ),
                          if (song.key != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF008CFF).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(song.key!,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF008CFF))),
                            ),
                          if (song.youtubeUrl != null) ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => launchUrl(Uri.parse(song.youtubeUrl!)),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.play_arrow_rounded, color: Color(0xFFEF4444), size: 18),
                              ),
                            ),
                          ],
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded, color: isDark ? const Color(0xFF6B7280) : const Color(0xFFD1D5DB), size: 22),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erro: $e', style: const TextStyle(color: Color(0xFFEF4444)))),
          ),
        ),
      ],
    );
  }

  Widget _buildArtistas(bool isDark) {
    return Center(
      child: Text('Em breve',
        style: TextStyle(fontSize: 14, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF))),
    );
  }
}
