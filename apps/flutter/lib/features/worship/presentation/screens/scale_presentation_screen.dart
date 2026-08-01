import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/worship_models.dart';
import '../providers/worship_provider.dart';
import '../services/metronome_player.dart';

/// Player de apresentação da escala: cifra com auto-scroll.
class ScalePresentationScreen extends ConsumerStatefulWidget {
  final String scaleId;
  final int initialIndex;

  const ScalePresentationScreen({
    super.key,
    required this.scaleId,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<ScalePresentationScreen> createState() =>
      _ScalePresentationScreenState();
}

class _ScalePresentationScreenState
    extends ConsumerState<ScalePresentationScreen> {
  final _scrollController = ScrollController();
  final _metronome = MetronomePlayer();
  Timer? _scrollTimer;

  List<Song> _songs = [];
  int _index = 0;
  bool _loading = true;
  bool _playing = false;
  bool _metronomeEnabled = true;
  int _activeBeat = -1;
  double _fontSize = 18;
  double _speed = 1.0;

  static const _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _index = widget.initialIndex;
    _metronome.prepare();
    _load();
  }

  @override
  void dispose() {
    _stopScroll();
    _scrollController.dispose();
    unawaited(_metronome.dispose());
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final result = await ref
          .read(worshipRepositoryProvider)
          .getWorshipEvent(widget.scaleId);
      final songs = (result.data.songs ?? []).map((e) => e.song).toList();
      if (!mounted) return;
      setState(() {
        _songs = songs;
        if (_index < 0 || _index >= songs.length) _index = 0;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Song? get _current => _songs.isEmpty || _index < 0 || _index >= _songs.length
      ? null
      : _songs[_index];

  bool get _hasNext => _index < _songs.length - 1;
  bool get _hasPrev => _index > 0;

  void _togglePlay() {
    if (_playing) {
      _stopScroll();
    } else {
      _startScroll();
    }
  }

  void _startScroll() {
    _scrollTimer?.cancel();
    setState(() => _playing = true);
    _startMetronome();
    // ~50ms tick; base pixels ≈ 0.55 at 1.0x
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!_scrollController.hasClients) return;
      final pos = _scrollController.position;
      final delta = 0.55 * _speed;
      final next = pos.pixels + delta;
      if (next >= pos.maxScrollExtent) {
        _scrollController.jumpTo(pos.maxScrollExtent);
        _stopScroll();
        return;
      }
      _scrollController.jumpTo(next);
    });
  }

  void _stopScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
    _stopMetronome();
    if (mounted && _playing) setState(() => _playing = false);
  }

  void _toggleMetronome() {
    final bpm = _current?.bpm;
    if (bpm == null || bpm <= 0) return;
    setState(() {
      _metronomeEnabled = !_metronomeEnabled;
      if (!_metronomeEnabled) _activeBeat = -1;
    });
    if (_playing) {
      if (_metronomeEnabled) {
        _startMetronome();
      } else {
        _stopMetronome();
      }
    }
  }

  void _startMetronome() {
    _stopMetronome();
    final bpm = _current?.bpm;
    if (!_metronomeEnabled || bpm == null || bpm <= 0) return;

    _metronome.start(
      bpm: bpm,
      onBeat: (beat) {
        if (mounted && _playing && _metronomeEnabled) {
          setState(() => _activeBeat = beat);
        }
      },
    );
  }

  void _stopMetronome() {
    _metronome.stop();
    _activeBeat = -1;
  }

  void _changeSpeed(int direction) {
    final i = _speeds.indexOf(_speed);
    final next = (i < 0 ? 2 : i) + direction;
    if (next < 0 || next >= _speeds.length) return;
    setState(() => _speed = _speeds[next]);
  }

  void _changeFont(int direction) {
    setState(() => _fontSize = (_fontSize + direction).clamp(14, 34));
  }

  void _goToSong(int index) {
    if (index < 0 || index >= _songs.length) return;
    _stopScroll();
    setState(() => _index = index);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF7F8FA);
    final song = _current;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF008CFF)),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              song?.title ?? 'Apresentação',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            if (_songs.isNotEmpty)
              Text(
                '${_index + 1} / ${_songs.length}'
                '${song?.key != null ? '  ·  Tom ${song!.key}' : ''}'
                '${song?.bpm != null ? '  ·  ${song!.bpm} BPM' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                ),
              ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : song == null
              ? Center(
                  child: Text(
                    'Nenhuma música nesta escala',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        child: _SongPresentationBody(
                          song: song,
                          fontSize: _fontSize,
                          isDark: isDark,
                        ),
                      ),
                    ),
                    _buildControls(isDark),
                  ],
                ),
    );
  }

  Widget _buildControls(bool isDark) {
    final bar = isDark ? const Color(0xFF161622) : Colors.white;
    final border = isDark ? const Color(0xFF2D2D44) : const Color(0xFFE5E7EB);
    final muted = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final bpm = _current?.bpm;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: bar,
          border: Border(top: BorderSide(color: border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _ctrlChip(
                  icon: Icons.text_decrease_rounded,
                  label: 'A−',
                  onTap: () => _changeFont(-1),
                  muted: muted,
                ),
                _ctrlChip(
                  icon: Icons.text_increase_rounded,
                  label: 'A+',
                  onTap: () => _changeFont(1),
                  muted: muted,
                ),
                const Spacer(),
                _ctrlChip(
                  icon: Icons.remove_rounded,
                  label: 'Vel',
                  onTap: () => _changeSpeed(-1),
                  muted: muted,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '${_speed}x',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Color(0xFF008CFF),
                    ),
                  ),
                ),
                _ctrlChip(
                  icon: Icons.add_rounded,
                  label: 'Vel',
                  onTap: () => _changeSpeed(1),
                  muted: muted,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildMetronomeControl(
              isDark: isDark,
              border: border,
              muted: muted,
              bpm: bpm,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _hasPrev ? () => _goToSong(_index - 1) : null,
                    icon: const Icon(Icons.skip_previous_rounded, size: 20),
                    label: const Text('Anterior'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF008CFF),
                      side: BorderSide(
                        color: _hasPrev
                            ? const Color(0xFF008CFF).withValues(alpha: 0.4)
                            : border,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _togglePlay,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF008CFF),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF008CFF).withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _hasNext ? () => _goToSong(_index + 1) : null,
                    icon: const Icon(Icons.skip_next_rounded, size: 20),
                    label: const Text('Próxima'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF008CFF),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          const Color(0xFF008CFF).withValues(alpha: 0.3),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetronomeControl({
    required bool isDark,
    required Color border,
    required Color muted,
    required int? bpm,
  }) {
    final available = bpm != null && bpm > 0;
    final active = available && _metronomeEnabled;

    return InkWell(
      onTap: available ? _toggleMetronome : null,
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF008CFF).withValues(alpha: isDark ? 0.18 : 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: active
                ? const Color(0xFF008CFF).withValues(alpha: 0.45)
                : border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              available
                  ? active
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded
                  : Icons.music_off_rounded,
              size: 20,
              color: active ? const Color(0xFF008CFF) : muted,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                available
                    ? 'Batida · $bpm BPM'
                    : 'Cadastre o BPM para ouvir a batida',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? const Color(0xFF008CFF) : muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (available) ...[
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(4, (index) {
                  final highlighted =
                      _playing && active && _activeBeat == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: highlighted ? 9 : 6,
                    height: highlighted ? 9 : 6,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: highlighted
                          ? const Color(0xFF008CFF)
                          : muted.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
              const SizedBox(width: 9),
              Text(
                active ? 'ON' : 'OFF',
                style: TextStyle(
                  color: active ? const Color(0xFF008CFF) : muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _ctrlChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color muted,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: muted),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SongPresentationBody extends StatelessWidget {
  final Song song;
  final double fontSize;
  final bool isDark;

  const _SongPresentationBody({
    required this.song,
    required this.fontSize,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final chords = song.chords?.trim();
    final baseColor =
        isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151);
    const chordColor = Color(0xFF008CFF);

    if (chords == null || chords.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Text(
          'Esta música não tem cifra cadastrada.',
          style: TextStyle(
            fontSize: 15,
            color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ChordPresentationText(
          text: chords,
          fontSize: fontSize + 3,
          chordColor: chordColor,
          baseColor: baseColor,
        ),
        // Espaço extra para o auto-scroll chegar ao fim com folga.
        const SizedBox(height: 120),
      ],
    );
  }
}

/// Cifra com acordes em destaque (azul) e restante do texto em tom neutro.
class _ChordPresentationText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color chordColor;
  final Color baseColor;

  const _ChordPresentationText({
    required this.text,
    required this.fontSize,
    required this.chordColor,
    required this.baseColor,
  });

  static final _chordRe = RegExp(
    r'(\[[^\]]+\]|(?<![A-Za-z0-9/])([A-G](?:#|b)?)(m|maj|min|dim|aug|sus|add|M)?([0-9]*)(/([A-G](?:#|b)?))?(?![A-Za-z0-9]))',
  );

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontFamily: 'monospace',
      fontSize: fontSize,
      height: 1.55,
      fontWeight: FontWeight.w500,
      color: baseColor,
    );
    final chordStyle = base.copyWith(
      color: chordColor,
      fontWeight: FontWeight.w800,
      fontSize: fontSize + 1,
    );

    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: _line(line, base, chordStyle),
          ),
      ],
    );
  }

  Widget _line(String line, TextStyle base, TextStyle chordStyle) {
    if (line.isEmpty) return SelectableText(' ', style: base);

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final m in _chordRe.allMatches(line)) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: line.substring(cursor, m.start), style: base));
      }
      var token = m[0]!;
      if (token.startsWith('[') && token.endsWith(']')) {
        token = token.substring(1, token.length - 1);
      }
      spans.add(TextSpan(text: token, style: chordStyle));
      cursor = m.end;
    }
    if (cursor < line.length) {
      spans.add(TextSpan(text: line.substring(cursor), style: base));
    }
    if (spans.isEmpty) {
      return SelectableText(line, style: base);
    }
    return SelectableText.rich(TextSpan(children: spans));
  }
}
