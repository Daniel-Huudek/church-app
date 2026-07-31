import 'package:flutter/material.dart';

/// Utilitário de transposição cromática para cifras e tons.
class ChordTransposer {
  ChordTransposer._();

  static const sharpScale = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
  ];
  static const flatScale = [
    'C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B',
  ];

  static const _alias = {
    'Db': 'C#',
    'Eb': 'D#',
    'Fb': 'E',
    'Gb': 'F#',
    'Ab': 'G#',
    'Bb': 'A#',
    'Cb': 'B',
    'E#': 'F',
    'B#': 'C',
  };

  /// Extrai a raiz (C, C#, Bb…) e o sufixo (m, 7, maj7…).
  static (String root, String suffix)? splitChord(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final match = RegExp(r'^([A-G])([#b]?)(.*)$').firstMatch(value);
    if (match == null) return null;
    final root = '${match[1]}${match[2]}';
    final suffix = match[3] ?? '';
    return (root, suffix);
  }

  static int? rootIndex(String root) {
    final normalized = _alias[root] ?? root;
    final idx = sharpScale.indexOf(normalized);
    if (idx >= 0) return idx;
    return flatScale.indexOf(root);
  }

  static String transposeRoot(String root, int semitones, {bool preferFlats = false}) {
    final idx = rootIndex(root);
    if (idx == null) return root;
    final next = (idx + semitones) % 12;
    final normalized = next < 0 ? next + 12 : next;
    final scale = preferFlats ? flatScale : sharpScale;
    return scale[normalized];
  }

  static String transposeChordToken(String token, int semitones, {bool preferFlats = false}) {
    final parts = splitChord(token);
    if (parts == null) return token;
    final (root, suffix) = parts;
    return '${transposeRoot(root, semitones, preferFlats: preferFlats)}$suffix';
  }

  static String? transposeKey(String? key, int semitones, {bool preferFlats = false}) {
    if (key == null || key.trim().isEmpty) return key;
    return transposeChordToken(key.trim(), semitones, preferFlats: preferFlats);
  }

  static int semitonesBetween(String fromKey, String toKey) {
    final from = splitChord(fromKey);
    final to = splitChord(toKey);
    if (from == null || to == null) return 0;
    final a = rootIndex(from.$1);
    final b = rootIndex(to.$1);
    if (a == null || b == null) return 0;
    return (b - a + 12) % 12;
  }

  /// Preferir bemóis quando o tom original usa bemóis (ex.: Bb, Eb).
  static bool prefersFlats(String? key) {
    final root = splitChord(key ?? '')?.$1 ?? '';
    return root.contains('b') || const {'F', 'Bb', 'Eb', 'Ab', 'Db', 'Gb'}.contains(root);
  }

  static final _looseChordRe = RegExp(
    r'(?<![A-Za-z0-9/])([A-G](?:#|b)?)(m|maj|min|dim|aug|sus|add|M)?([0-9]*)(/([A-G](?:#|b)?))?(?![A-Za-z0-9])',
  );

  static String _transposeLoose(String source, int semitones, {bool preferFlats = false}) {
    return source.replaceAllMapped(_looseChordRe, (m) {
      final root = m[1]!;
      final quality = m[2] ?? '';
      final digits = m[3] ?? '';
      final bass = m[5];
      final head = transposeChordToken('$root$quality$digits', semitones, preferFlats: preferFlats);
      if (bass == null) return head;
      final bassRoot = transposeRoot(bass, semitones, preferFlats: preferFlats);
      return '$head/$bassRoot';
    });
  }

  static String transposeText(String source, int semitones, {bool preferFlats = false}) {
    if (semitones == 0 || source.isEmpty) return source;

    // Processa ChordPro [Am7] e texto livre sem aplicar transpose duas vezes.
    final buffer = StringBuffer();
    var cursor = 0;
    for (final m in RegExp(r'\[([^\]]+)\]').allMatches(source)) {
      if (m.start > cursor) {
        buffer.write(
          _transposeLoose(
            source.substring(cursor, m.start),
            semitones,
            preferFlats: preferFlats,
          ),
        );
      }
      final inner = transposeChordToken(m[1]!, semitones, preferFlats: preferFlats);
      buffer.write('[$inner]');
      cursor = m.end;
    }
    if (cursor < source.length) {
      buffer.write(
        _transposeLoose(
          source.substring(cursor),
          semitones,
          preferFlats: preferFlats,
        ),
      );
    }
    return buffer.toString();
  }
}

/// Visualização de cifra com suporte a transpose e destaque de acordes.
class ChordViewer extends StatelessWidget {
  final String chords;
  final int transpose;
  final TextStyle? textStyle;
  final bool preferFlats;

  const ChordViewer({
    super.key,
    required this.chords,
    this.transpose = 0,
    this.textStyle,
    this.preferFlats = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = textStyle ??
        TextStyle(
          fontFamily: 'monospace',
          fontSize: 15,
          height: 1.6,
          color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
        );
    final chordStyle = style.copyWith(
      color: const Color(0xFF008CFF),
      fontWeight: FontWeight.w700,
    );

    final transposed = ChordTransposer.transposeText(
      chords,
      transpose,
      preferFlats: preferFlats,
    );
    final lines = transposed.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: _buildLine(line, style, chordStyle),
          ),
      ],
    );
  }

  Widget _buildLine(String line, TextStyle style, TextStyle chordStyle) {
    final bracketMatches = RegExp(r'\[([^\]]+)\]').allMatches(line).toList();
    if (bracketMatches.isNotEmpty) {
      final spans = <InlineSpan>[];
      var cursor = 0;
      for (final m in bracketMatches) {
        if (m.start > cursor) {
          spans.add(TextSpan(text: line.substring(cursor, m.start), style: style));
        }
        spans.add(TextSpan(text: m[1], style: chordStyle));
        cursor = m.end;
      }
      if (cursor < line.length) {
        spans.add(TextSpan(text: line.substring(cursor), style: style));
      }
      return SelectableText.rich(TextSpan(children: spans));
    }

    final chordRe = RegExp(
      r'([A-G](?:#|b)?)(m|maj|min|dim|aug|sus|add|M)?([0-9]*)(/([A-G](?:#|b)?))?',
    );
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final m in chordRe.allMatches(line)) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: line.substring(cursor, m.start), style: style));
      }
      spans.add(TextSpan(text: m[0], style: chordStyle));
      cursor = m.end;
    }
    if (cursor < line.length) {
      spans.add(TextSpan(text: line.substring(cursor), style: style));
    }
    if (spans.isEmpty) {
      return SelectableText(line.isEmpty ? ' ' : line, style: style);
    }
    return SelectableText.rich(TextSpan(children: spans));
  }
}
