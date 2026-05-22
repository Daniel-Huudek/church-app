import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../domain/worship_models.dart';
import '../providers/worship_provider.dart';
import '../widgets/song_card.dart';
import '../widgets/playlist_card.dart';
import 'playlist_detail_screen.dart';
import 'song_detail_screen.dart';

class WorshipDashboardScreen extends ConsumerWidget {
  const WorshipDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final songsAsync = ref.watch(songsProvider);
    final playlistsAsync = ref.watch(playlistsProvider);
    final favorites = ref.watch(favoritesProvider).valueOrNull ?? <Song>[];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200, pinned: false, floating: false, stretch: true,
            backgroundColor: const Color(0xFF008CFF),
            flexibleSpace: FlexibleSpaceBar(stretchModes: const [StretchMode.zoomBackground], background: Stack(fit: StackFit.expand, children: [
              Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [const Color(0xFF008CFF), const Color(0xFF0066CC), const Color(0xFF004D99)]))),
              Positioned(right: -40, top: -40, child: Container(width: 180, height: 180, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.04)))),
              Positioned(left: -60, bottom: -60, child: Container(width: 220, height: 220, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.03)))),
              Positioned(right: 20, bottom: 20, child: Icon(Icons.music_note_rounded, size: 120, color: Colors.white.withValues(alpha: 0.06))),
              Positioned(left: 24, bottom: 24, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text('LOUVOR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.6), letterSpacing: 2)),
                const SizedBox(height: 4), const Text('Biblioteca Musical', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                const SizedBox(height: 6), Text('Músicas, cifras e repertórios', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7))),
              ])),
            ])),
          ),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 8), child: GestureDetector(onTap: () => showSearch(context: context, delegate: _SongSearchDelegate(ref)),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1A2E) : Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 8)]),
              child: Row(children: [Icon(Icons.search_rounded, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF), size: 20), const SizedBox(width: 10), Text('Buscar músicas...', style: TextStyle(color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF), fontSize: 15))]))))),

          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 20), child: Row(children: [
            _QuickAction(icon: Icons.queue_music_rounded, label: 'Nova Playlist', color: const Color(0xFF008CFF), isDark: isDark, onTap: () => _showCreatePlaylistDialog(context, ref)),
            const SizedBox(width: 10), _QuickAction(icon: Icons.favorite_rounded, label: 'Favoritas', color: const Color(0xFFEF4444), isDark: isDark, onTap: () {}),
            const SizedBox(width: 10), _QuickAction(icon: Icons.history_rounded, label: 'Recentes', color: const Color(0xFF10B981), isDark: isDark, onTap: () {}),
          ]))),

          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 12), child: Row(children: [
            Text('Favoritas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF111827))),
            const Spacer(), if (favorites.isNotEmpty) Text('${favorites.length} músicas', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF))),
          ]))),
          ref.watch(favoritesProvider).when(
            data: (s) => s.isEmpty
              ? SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Container(height: 120, decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1A2E) : Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.favorite_outline_rounded, size: 28, color: isDark ? const Color(0xFF6B7280) : const Color(0xFFD1D5DB)), const SizedBox(height: 6),
                    Text('Nenhuma favorita', style: TextStyle(color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF), fontSize: 13))])))))
              : SliverToBoxAdapter(child: SizedBox(height: 120, child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal: 20), scrollDirection: Axis.horizontal, itemCount: s.length, separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _FavoriteCard(song: s[i], isDark: isDark, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SongDetailScreen(songId: s[i].id))))))),
            loading: () => const SliverToBoxAdapter(child: SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 12), child: Row(children: [
            Text('Playlists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF111827))),
            const Spacer(),
            GestureDetector(onTap: () => _showCreatePlaylistDialog(context, ref), child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), decoration: BoxDecoration(color: const Color(0xFF008CFF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Row(children: [Icon(Icons.add_rounded, size: 16, color: const Color(0xFF008CFF)), const SizedBox(width: 4), Text('Nova', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF008CFF)))]))),
          ]))),
          playlistsAsync.when(
            data: (pl) => pl.isEmpty
              ? SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Container(height: 100, decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1A2E) : Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: Center(child: Text('Nenhuma playlist', style: TextStyle(color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)))))))
              : SliverToBoxAdapter(child: SizedBox(height: 200, child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal: 20), scrollDirection: Axis.horizontal, itemCount: pl.length, separatorBuilder: (_, __) => const SizedBox(width: 14), itemBuilder: (_, i) => PlaylistCard(playlist: pl[i])))),
            loading: () => const SliverToBoxAdapter(child: SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 12), child: Row(children: [
            Text('Biblioteca', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF111827))),
            const Spacer(),
            songsAsync.whenOrNull(data: (s) => Text('${s.length} músicas', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)))) ?? const SizedBox(),
          ]))),
          songsAsync.when(
            data: (s) => SliverList(delegate: SliverChildBuilderDelegate(
              (_, i) => Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, i == s.length - 1 ? 100 : 8), child: GestureDetector(onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SongDetailScreen(songId: s[i].id))),
                child: SongCard(song: s[i], isFavorite: favorites.any((f) => f.id == s[i].id), onFavorite: () => ref.read(favoritesProvider.notifier).toggle(s[i].id)))),
              childCount: s.length,
            )),
            loading: () => const SliverToBoxAdapter(child: SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))),
            error: (e, _) => SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(20), child: Center(child: Text('Erro: $e', style: const TextStyle(color: Color(0xFFEF4444)))))),
          ),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Text('Nova Playlist'), content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Nome da playlist'), autofocus: true),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')), ElevatedButton(onPressed: () async { if (ctrl.text.trim().isEmpty) return; await ref.read(worshipApiProvider).createPlaylist({'name': ctrl.text.trim()}); if (ctx.mounted) Navigator.pop(ctx); ref.invalidate(playlistsProvider); }, child: const Text('Criar'))]));
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon; final String label; final Color color; final bool isDark; final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.isDark, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1A2E) : Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 8)]),
    child: Column(children: [Icon(icon, color: color, size: 22), const SizedBox(height: 6), Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)))]))));
}

class _FavoriteCard extends StatelessWidget {
  final Song song; final bool isDark; final VoidCallback onTap;
  const _FavoriteCard({required this.song, required this.isDark, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(width: 140, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1A2E) : Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 8)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 16)),
      const Spacer(), Text(song.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF111827)), maxLines: 1, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 2), if (song.artist != null) Text(song.artist!, style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)), maxLines: 1, overflow: TextOverflow.ellipsis),
    ])));
}

class _SongSearchDelegate extends SearchDelegate {
  final WidgetRef ref;
  _SongSearchDelegate(this.ref);
  @override List<Widget>? buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  @override Widget? buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));
  @override Widget buildResults(BuildContext context) {
    ref.read(songsProvider.notifier).load(search: query);
    return ref.watch(songsProvider).when(data: (s) => ListView.builder(padding: const EdgeInsets.all(16), itemCount: s.length, itemBuilder: (_, i) => Padding(padding: const EdgeInsets.only(bottom: 8), child: SongCard(song: s[i]))), loading: () => const Center(child: CircularProgressIndicator()), error: (_, __) => const SizedBox());
  }
  @override Widget buildSuggestions(BuildContext context) => const SizedBox();
}
