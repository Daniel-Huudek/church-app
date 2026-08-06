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
    final slash = token.indexOf('/');
    final head = slash < 0 ? token : token.substring(0, slash);
    final bass = slash < 0 ? null : token.substring(slash + 1);
    final parts = splitChord(head);
    if (parts == null || (bass != null && rootIndex(bass) == null)) return token;
    final (root, suffix) = parts;
    final transposed = '${transposeRoot(root, semitones, preferFlats: preferFlats)}$suffix';
    if (bass == null) return transposed;
    return '$transposed/${transposeRoot(bass, semitones, preferFlats: preferFlats)}';
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

  static final _chordTokenRe = RegExp(
    r'^[A-G](?:#|b)?(?:(?:maj|min|dim|aug|sus|add|m|M)|\d+|[#b]\d+|\([^)]*\))*(?:/[A-G](?:#|b)?)?$',
  );

  static final _tokenRe = RegExp(r'\S+');

  static const _lineLabels = {'intro', 'verse', 'verso', 'chorus', 'refrão', 'refrao', 'bridge', 'ponte', 'solo', 'final'};

  static String _stripNotation(String token) {
    return token.replaceFirst(RegExp(r'^[|:,(]+'), '').replaceFirst(RegExp(r'[|:,.);]+$'), '');
  }

  static bool isChordToken(String token) => _chordTokenRe.hasMatch(_stripNotation(token));

  /// Linhas livres só são tratadas como cifra quando a maioria dos seus
  /// elementos são acordes. Isso evita transformar palavras da letra, como
  /// "A Deus", em notas.
  static bool isLooseChordLine(String line) {
    var chords = 0;
    var words = 0;
    for (final match in _tokenRe.allMatches(line)) {
      final token = _stripNotation(match[0]!);
      if (token.isEmpty || _lineLabels.contains(token.toLowerCase())) continue;
      words++;
      if (_chordTokenRe.hasMatch(token)) chords++;
    }
    return chords > 0 && (words == 1 || chords / words >= 0.6);
  }

  static String _transposeLoose(String source, int semitones, {bool preferFlats = false}) {
    if (!isLooseChordLine(source)) return source;
    return source.replaceAllMapped(_tokenRe, (m) {
      final raw = m[0]!;
      final chord = _stripNotation(raw);
      if (!_chordTokenRe.hasMatch(chord)) return raw;
      final start = raw.indexOf(chord);
      return '${raw.substring(0, start)}${transposeChordToken(chord, semitones, preferFlats: preferFlats)}${raw.substring(start + chord.length)}';
    });
  }

  static String transposeText(String source, int semitones, {bool preferFlats = false}) {
    if (semitones == 0 || source.isEmpty) return source;

    // Em ChordPro, apenas o conteúdo entre colchetes é cifra. Em texto livre,
    // a classificação é feita linha a linha para proteger a letra.
    if (!source.contains(RegExp(r'\[[^\]]+\]'))) {
      return source.split('\n').map((line) => _transposeLoose(line, semitones, preferFlats: preferFlats)).join('\n');
    }
    final buffer = StringBuffer();
    var cursor = 0;
    for (final m in RegExp(r'\[([^\]]+)\]').allMatches(source)) {
      if (m.start > cursor) {
        buffer.write(source.substring(cursor, m.start));
      }
      final inner = transposeChordToken(m[1]!, semitones, preferFlats: preferFlats);
      buffer.write('[$inner]');
      cursor = m.end;
    }
    if (cursor < source.length) {
      buffer.write(source.substring(cursor));
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

    if (!ChordTransposer.isLooseChordLine(line)) {
      return SelectableText(line.isEmpty ? ' ' : line, style: style);
    }
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final m in RegExp(r'\S+').allMatches(line)) {
      if (!ChordTransposer.isChordToken(m[0]!)) continue;
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
