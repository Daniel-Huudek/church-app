import 'package:church_app_mobile/features/worship/presentation/widgets/chord_viewer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChordTransposer', () {
    test('transposes roots by semitone', () {
      expect(ChordTransposer.transposeRoot('C', 2), 'D');
      expect(ChordTransposer.transposeRoot('Bb', 2, preferFlats: true), 'C');
      expect(ChordTransposer.transposeRoot('G', -1), 'F#');
    });

    test('transposes chord tokens with quality and bass', () {
      expect(ChordTransposer.transposeChordToken('Am7', 2), 'Bm7');
      expect(
        ChordTransposer.transposeText('Am   G/B   F', 2),
        'Bm   A/C#   G',
      );
    });

    test('computes semitones between keys', () {
      expect(ChordTransposer.semitonesBetween('G', 'A'), 2);
      expect(ChordTransposer.semitonesBetween('Am', 'Bm'), 2);
    });

    test('transposes bracket chords', () {
      expect(
        ChordTransposer.transposeText('[C]Love [G]song', 2),
        '[D]Love [A]song',
      );
    });
  });
}
