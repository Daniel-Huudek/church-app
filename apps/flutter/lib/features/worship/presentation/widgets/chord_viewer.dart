import 'package:flutter/material.dart';

class ChordViewer extends StatelessWidget {
  final String chords; final int transpose; final TextStyle? textStyle;
  const ChordViewer({super.key, required this.chords, this.transpose = 0, this.textStyle});

  static const _keys = ['C','Cm','C7','Cm7','C#','C#m','D','Dm','D7','Dm7','Eb','Ebm','E','Em','E7','Em7','F','Fm','F7','Fm7','F#','F#m','G','Gm','G7','Gm7','Ab','Abm','A','Am','A7','Am7','Bb','Bbm','B','Bm','B7','Bm7'];

  String get _transposed {
    if (transpose == 0) return chords;
    final re = RegExp(r'\b([A-G][#b]?)(m?)(7?)\b');
    return chords.replaceAllMapped(re, (m) {
      final f = '${m[1]}${m[2]}${m[3]}'; final idx = _keys.indexOf(f); return idx == -1 ? f : _keys[(idx + transpose + _keys.length) % _keys.length];
    });
  }

  @override
  Widget build(BuildContext context) {
    final style = textStyle ?? TextStyle(fontFamily: 'monospace', fontSize: 15, height: 1.6, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF111827));
    final lines = _transposed.split('\n');
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((l) {
        final matches = RegExp(r'\[([^\]]+)\]').allMatches(l);
        return matches.isEmpty ? Text(l, style: style) : RichText(text: TextSpan(children: [
          for (final m in matches) TextSpan(text: m[1]!, style: style.copyWith(color: const Color(0xFF008CFF), fontWeight: FontWeight.bold)),
          TextSpan(text: l.replaceAll(RegExp(r'\[[^\]]+\]'), ''), style: style),
        ]));
      }).toList(),
    ));
  }
}
