import { describe, expect, it } from 'vitest';
import {
  transposeChordText,
  transposeChordToken,
  transposeKey,
} from './chord-transposer';

describe('worship chord transposer', () => {
  it('transposes qualities, extensions and inverted bass notes', () => {
    expect(transposeChordToken('Am7', 2)).toBe('Bm7');
    expect(transposeChordToken('G/B', 2)).toBe('A/C#');
    expect(transposeChordToken('Bbmaj7', 2, true)).toBe('Cmaj7');
  });

  it('preserves lyrics while transposing loose chord lines', () => {
    expect(transposeChordText('C  G/B  Am7\nA Deus seja a glória', 2)).toBe(
      'D  A/C#  Bm7\nA Deus seja a glória',
    );
  });

  it('only transposes bracketed content in ChordPro text', () => {
    expect(transposeChordText('[C]A Deus [G]cantamos', 2)).toBe(
      '[D]A Deus [A]cantamos',
    );
  });

  it('keeps the key quality and preferred accidental style', () => {
    expect(transposeKey('Am', 2)).toBe('Bm');
    expect(transposeKey('Bb', 1)).toBe('B');
    expect(transposeKey('Bb', -2)).toBe('Ab');
  });
});
