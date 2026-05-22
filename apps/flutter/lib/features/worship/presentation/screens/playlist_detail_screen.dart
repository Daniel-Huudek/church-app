import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../data/worship_api.dart';
import '../../domain/worship_models.dart';
import '../providers/worship_provider.dart';
import '../widgets/song_card.dart';

class PlaylistDetailScreen extends ConsumerStatefulWidget {
  final String playlistId;
  const PlaylistDetailScreen({super.key, required this.playlistId});
  @override ConsumerState<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  Playlist? _p; bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { final r = await ref.read(worshipApiProvider).getPlaylist(widget.playlistId); if (mounted) setState(() { _p = Playlist.fromJson(r as Map? ?? r['data']); _loading = false; }); } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC),
      appBar: AppBar(title: Text(_p?.name ?? 'Playlist', style: const TextStyle(fontWeight: FontWeight.w600)),
        actions: [PopupMenuButton<String>(itemBuilder: (_) => [const PopupMenuItem(value: 'duplicate', child: Text('Duplicar')), const PopupMenuItem(value: 'delete', child: Text('Excluir', style: TextStyle(color: Color(0xFFEF4444))))],
          onSelected: (v) async { if (v == 'duplicate') { await ref.read(worshipApiProvider).duplicatePlaylist(widget.playlistId); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Playlist duplicada'))); if (mounted) _load(); } else if (v == 'delete') { await ref.read(worshipApiProvider).deletePlaylist(widget.playlistId); if (mounted) Navigator.pop(context); } })],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator())
      : _p == null ? const Center(child: Text('Playlist não encontrada'))
      : SingleChildScrollView(physics: const BouncingScrollPhysics(), padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.6)]), borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.queue_music_rounded, color: Colors.white, size: 32), const SizedBox(height: 12),
            Text(_p!.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
            if (_p!.description != null) ...[const SizedBox(height: 4), Text(_p!.description!, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14))],
            const SizedBox(height: 8), Text('${_p!.songs?.length ?? 0} músicas · ${(_p!.totalDuration / 60).ceil()}min', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 20),
        if (_p!.songs != null) ...(_p!.songs!.map((ps) => Padding(padding: const EdgeInsets.only(bottom: 8), child: SongCard(song: ps.song))).toList()),
        if (_p!.songs == null || _p!.songs!.isEmpty) Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(children: [
          Icon(Icons.music_note_outlined, size: 48, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)), const SizedBox(height: 12),
          Text('Playlist vazia', style: TextStyle(color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)))]))),
      ])),
    );
  }
}
