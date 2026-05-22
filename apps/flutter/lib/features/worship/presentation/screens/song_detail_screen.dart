import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../data/worship_api.dart';
import '../../domain/worship_models.dart';
import '../providers/worship_provider.dart';
import '../widgets/chord_viewer.dart';

class SongDetailScreen extends ConsumerStatefulWidget {
  final String songId;
  const SongDetailScreen({super.key, required this.songId});
  @override ConsumerState<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends ConsumerState<SongDetailScreen> {
  Song? _song; bool _loading = true; int _transpose = 0; bool _showChords = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { final r = await ref.read(worshipApiProvider).getSong(widget.songId); if (mounted) setState(() { _song = Song.fromJson(r['data'] as Map<String, dynamic>? ?? r); _loading = false; }); } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC),
      appBar: AppBar(title: Text(_song?.title ?? 'Música', style: const TextStyle(fontWeight: FontWeight.w600))),
      body: _loading ? const Center(child: CircularProgressIndicator())
      : _song == null ? const Center(child: Text('Música não encontrada'))
      : SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)])),
          child: SafeArea(bottom: false, child: Column(children: [
            Text(_song!.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
            if (_song!.artist != null) ...[const SizedBox(height: 4), Text(_song!.artist!, style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.8)))],
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (_song!.key != null) _infoChip('Tom: ${_song!.key}', Icons.music_note),
              if (_song!.bpm != null) _infoChip('${_song!.bpm} BPM', Icons.speed),
              if (_song!.duration != null) _infoChip('${_song!.duration! ~/ 60}:${(_song!.duration! % 60).toString().padLeft(2, '0')}', Icons.timer_outlined),
            ]),
            if (_song!.youtubeUrl != null) ...[const SizedBox(height: 12),
              OutlinedButton.icon(icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white), label: const Text('Ver no YouTube', style: TextStyle(color: Colors.white)), onPressed: () {}, style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white54)))],
          ])),
        ),
        if (_song!.lyrics != null || _song!.chords != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), child: Row(children: [
          if (_song!.chords != null) _toggleBtn('Cifra', _showChords, () => setState(() => _showChords = true), isDark),
          if (_song!.lyrics != null) _toggleBtn('Letra', !_showChords, () => setState(() => _showChords = false), isDark),
          if (_song!.chords != null) ...[const Spacer(), _transposeBtn(-1, isDark), const SizedBox(width: 4),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(_transpose == 0 ? 'Tom original' : '${_transpose > 0 ? '+' : ''}$_transpose', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary))),
            const SizedBox(width: 4), _transposeBtn(1, isDark)],
        ])),
        if (_showChords && _song!.chords != null) ChordViewer(chords: _song!.chords!, transpose: _transpose)
        else if (!_showChords && _song!.lyrics != null) Padding(padding: const EdgeInsets.all(20), child: SelectableText(_song!.lyrics!, style: TextStyle(fontSize: 16, height: 1.7, color: isDark ? Colors.white : const Color(0xFF111827)))),
        const SizedBox(height: 40),
      ])),
    );
  }

  Widget _infoChip(String t, IconData i) => Container(margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(i, color: Colors.white, size: 14), const SizedBox(width: 4), Text(t, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500))]));
  Widget _toggleBtn(String l, bool a, VoidCallback t, bool d) => GestureDetector(onTap: t, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), margin: const EdgeInsets.only(right: 8),
    decoration: BoxDecoration(color: a ? AppColors.primary : null, borderRadius: BorderRadius.circular(20), border: Border.all(color: a ? AppColors.primary : const Color(0xFFD1D5DB))),
    child: Text(l, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: a ? Colors.white : (d ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280))))));
  Widget _transposeBtn(int dir, bool d) => GestureDetector(onTap: () => setState(() => _transpose += dir),
    child: Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Center(child: Icon(dir > 0 ? Icons.add : Icons.remove, size: 18, color: AppColors.primary))));
}
