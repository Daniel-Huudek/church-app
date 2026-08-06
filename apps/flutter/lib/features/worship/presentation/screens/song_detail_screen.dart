import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/api_client.dart';
import '../../data/worship_api.dart';
import '../../domain/worship_models.dart';
import '../widgets/chord_viewer.dart';

class SongDetailScreen extends ConsumerStatefulWidget {
  final String songId;
  const SongDetailScreen({super.key, required this.songId});

  @override
  ConsumerState<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends ConsumerState<SongDetailScreen> {
  Song? _song;
  bool _loading = true;
  double _fontSize = 15;
  int _transpose = 0;
  bool _preferFlats = false;

  static const _sharpKeys = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  static const _flatKeys = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = WorshipApi(ref.read(apiClientProvider));
      final raw = await api.getSong(widget.songId);
      final map = Map<String, dynamic>.from(raw);
      final data = map.containsKey('data') && map['data'] is Map
          ? Map<String, dynamic>.from(map['data'] as Map)
          : map;
      if (!mounted) return;
      setState(() {
        _song = Song.fromJson(data);
        _transpose = 0;
        _preferFlats = ChordTransposer.prefersFlats(_song?.key);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? get _displayKey {
    final original = _song?.key;
    if (original == null || original.trim().isEmpty) {
      if (_transpose == 0) return null;
      return ChordTransposer.transposeKey('C', _transpose);
    }
    return ChordTransposer.transposeKey(
      original,
      _transpose,
      preferFlats: _preferFlats,
    );
  }

  void _shiftTranspose(int delta) {
    setState(() => _transpose = (_transpose + delta).clamp(-11, 11));
  }

  Future<void> _pickKey() async {
    final song = _song;
    if (song == null) return;
    final original = song.key?.trim();
    if (original == null || original.isEmpty) return;
    final suffix = ChordTransposer.splitChord(original)?.$2 ?? '';
    final isMinor = suffix.startsWith('min') ||
        (suffix.startsWith('m') && !suffix.startsWith('maj'));
    final roots = _preferFlats ? _flatKeys : _sharpKeys;
    final keyOptions = roots.map((root) => isMinor ? '${root}m' : root).toList();
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Escolher tom',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Original: $original',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 280,
                  child: GridView.builder(
                    itemCount: keyOptions.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.6,
                    ),
                    itemBuilder: (_, i) {
                      final key = keyOptions[i];
                      final isSelected = ChordTransposer.semitonesBetween(_displayKey ?? original, key) == 0;
                      return InkWell(
                        onTap: () => Navigator.pop(ctx, key),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF008CFF)
                                : const Color(0xFF008CFF).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            key,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : const Color(0xFF008CFF),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted) return;
    final semitones = ChordTransposer.semitonesBetween(original, selected);
    // Prefer shortest path signed (-5 instead of +7 when closer)
    final signed = semitones > 6 ? semitones - 12 : semitones;
    setState(() {
      _transpose = signed;
      _preferFlats = selected.contains('b');
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
            color: const Color(0xFF008CFF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF008CFF), size: 24),
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(
          _song?.title ?? 'Música',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF111827)),
        ),
        actions: [
          if (_song != null)
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF008CFF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.edit_rounded, color: Color(0xFF008CFF), size: 22),
                onPressed: () async {
                  await context.push('/worship/songs/${widget.songId}/edit');
                  if (mounted) _load();
                },
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _song == null
              ? Center(child: Text('Música não encontrada', style: TextStyle(color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF))))
              : _buildContent(isDark),
    );
  }

  Widget _buildContent(bool isDark) {
    final s = _song!;
    final hasChords = s.chords != null && s.chords!.trim().isNotEmpty;
    final hasLyrics = s.lyrics != null && s.lyrics!.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(s),
          if (s.youtubeUrl != null) ...[
            const SizedBox(height: 20),
            _buildYouTubeCard(s),
          ],
          if (hasChords) ...[
            const SizedBox(height: 20),
            _buildTransposeControls(isDark),
          ],
          if (hasChords || hasLyrics) ...[
            const SizedBox(height: 16),
            _buildFontControls(isDark),
            const SizedBox(height: 24),
            if (hasLyrics) _section('Letra', child: _lyricsBody(s.lyrics!, isDark), icon: Icons.text_fields_rounded, isDark: isDark),
            if (hasLyrics && hasChords) const SizedBox(height: 16),
            if (hasChords)
              _section(
                'Cifra',
                icon: Icons.piano_rounded,
                isDark: isDark,
                child: ChordViewer(
                  chords: s.chords!,
                  transpose: _transpose,
                  preferFlats: _preferFlats,
                  textStyle: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: _fontSize,
                    height: 1.6,
                    color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                  ),
                ),
              ),
          ],
          if (s.notes != null) ...[
            const SizedBox(height: 16),
            _section(
              'Observações',
              icon: Icons.edit_note_rounded,
              isDark: isDark,
              child: SelectableText(
                s.notes!,
                style: TextStyle(
                  fontSize: _fontSize,
                  height: 1.6,
                  color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _lyricsBody(String lyrics, bool isDark) {
    return SelectableText(
      lyrics,
      style: TextStyle(
        fontSize: _fontSize,
        height: 1.6,
        color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
      ),
    );
  }

  Widget _buildTransposeControls(bool isDark) {
    final hasOriginalKey = _song?.key?.trim().isNotEmpty == true;
    final displayKey = _displayKey ?? 'Não informado';
    final card = isDark ? const Color(0xFF161622) : Colors.white;
    final border = isDark ? const Color(0xFF2D2D44) : const Color(0xFFE5E7EB);
    final muted = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Diminuir meio tom',
            onPressed: () => _shiftTranspose(-1),
            icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFF008CFF)),
          ),
          Expanded(
            child: Column(
              children: [
                Text('Tom', style: TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: hasOriginalKey ? _pickKey : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF008CFF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayKey,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF008CFF),
                          ),
                        ),
                        if (hasOriginalKey) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.expand_more_rounded, size: 18, color: Color(0xFF008CFF)),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_transpose != 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    _transpose > 0 ? '+$_transpose' : '$_transpose',
                    style: TextStyle(fontSize: 11, color: muted, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Aumentar meio tom',
            onPressed: () => _shiftTranspose(1),
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF008CFF)),
          ),
          if (_transpose != 0)
            TextButton(
              onPressed: () => setState(() {
                _transpose = 0;
                _preferFlats = ChordTransposer.prefersFlats(_song?.key);
              }),
              child: const Text('Reset'),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(Song s) {
    final displayKey = _displayKey;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF008CFF), Color(0xFF0066CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF008CFF).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 28),
              ),
              const Spacer(),
              if (displayKey != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Tom: $displayKey',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            s.title,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
          ),
          if (s.artist != null) ...[
            const SizedBox(height: 6),
            Text(s.artist!, style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.8))),
          ],
          if (s.bpm != null || s.capo != null || s.duration != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (s.bpm != null) _tag('${s.bpm} BPM', Icons.speed_rounded),
                if (s.bpm != null && s.capo != null) const SizedBox(width: 8),
                if (s.capo != null) _tag('Capo ${s.capo}', Icons.straighten_rounded),
                if ((s.bpm != null || s.capo != null) && s.duration != null) const SizedBox(width: 8),
                if (s.duration != null) _tag('${s.duration}s', Icons.timer_outlined),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildYouTubeCard(Song s) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(s.youtubeUrl!)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Color(0xFFEF4444), size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ouvir no YouTube',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFEF4444)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.youtubeUrl!,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded, color: Color(0xFF9CA3AF), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFontControls(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161622) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF2D2D44) : const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _fontSize = (_fontSize - 1).clamp(10, 30)),
            child: Container(
              padding: const EdgeInsets.all(14),
              child: Icon(
                Icons.text_decrease_rounded,
                size: 24,
                color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563),
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF008CFF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.text_fields_rounded, size: 16, color: Color(0xFF008CFF)),
                const SizedBox(width: 6),
                Text(
                  '${_fontSize.toInt()}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF008CFF)),
                ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _fontSize = (_fontSize + 1).clamp(10, 30)),
            child: Container(
              padding: const EdgeInsets.all(14),
              child: Icon(
                Icons.text_increase_rounded,
                size: 24,
                color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _section(
    String title, {
    required Widget child,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF008CFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: const Color(0xFF008CFF)),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
