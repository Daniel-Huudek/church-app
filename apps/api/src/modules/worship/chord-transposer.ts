const SHARP_SCALE = [
  'C',
  'C#',
  'D',
  'D#',
  'E',
  'F',
  'F#',
  'G',
  'G#',
  'A',
  'A#',
  'B',
] as const;
const FLAT_SCALE = [
  'C',
  'Db',
  'D',
  'Eb',
  'E',
  'F',
  'Gb',
  'G',
  'Ab',
  'A',
  'Bb',
  'B',
] as const;

const ROOT_ALIASES: Record<string, string> = {
  Db: 'C#',
  Eb: 'D#',
  Fb: 'E',
  Gb: 'F#',
  Ab: 'G#',
  Bb: 'A#',
  Cb: 'B',
  'E#': 'F',
  'B#': 'C',
};

const CHORD_TOKEN =
  /^([A-G](?:#|b)?)((?:(?:maj|min|dim|aug|sus|add|m|M)|\d+|[#b]\d+|\([^)]*\))*)(?:\/([A-G](?:#|b)?))?$/;
const LOOSE_TOKEN = /\S+/g;
const LINE_LABELS = new Set([
  'intro',
  'verse',
  'verso',
  'chorus',
  'refrão',
  'refrao',
  'bridge',
  'ponte',
  'solo',
  'final',
]);

function rootIndex(root: string): number | undefined {
  const index = SHARP_SCALE.indexOf(
    (ROOT_ALIASES[root] ?? root) as (typeof SHARP_SCALE)[number],
  );
  return index < 0 ? undefined : index;
}

function transposeRoot(
  root: string,
  semitones: number,
  preferFlats: boolean,
): string {
  const index = rootIndex(root);
  if (index === undefined) return root;
  const normalized = (((index + semitones) % 12) + 12) % 12;
  return (preferFlats ? FLAT_SCALE : SHARP_SCALE)[normalized];
}

function stripNotation(token: string): string {
  return token.replace(/^[|:,(]+/, '').replace(/[|:,.);]+$/, '');
}

export function transposeChordToken(
  token: string,
  semitones: number,
  preferFlats = false,
): string {
  const match = CHORD_TOKEN.exec(token);
  if (!match) return token;
  const [, root, suffix, bass] = match;
  const head = `${transposeRoot(root, semitones, preferFlats)}${suffix}`;
  return bass ? `${head}/${transposeRoot(bass, semitones, preferFlats)}` : head;
}

function isChordLine(line: string): boolean {
  const tokens = line.match(LOOSE_TOKEN) ?? [];
  const meaningful = tokens
    .map(stripNotation)
    .filter((token) => token && !LINE_LABELS.has(token.toLowerCase()));
  const chords = meaningful.filter((token) => CHORD_TOKEN.test(token)).length;
  return (
    chords > 0 && (meaningful.length === 1 || chords / meaningful.length >= 0.6)
  );
}

function transposeLooseLine(
  line: string,
  semitones: number,
  preferFlats: boolean,
): string {
  if (!isChordLine(line)) return line;
  return line.replace(LOOSE_TOKEN, (raw) => {
    const chord = stripNotation(raw);
    if (!CHORD_TOKEN.test(chord)) return raw;
    return raw.replace(
      chord,
      transposeChordToken(chord, semitones, preferFlats),
    );
  });
}

export function transposeChordText(
  source: string,
  semitones: number,
  preferFlats = false,
): string {
  if (!source || semitones === 0) return source;
  if (/\[[^\]]+\]/.test(source)) {
    return source.replace(
      /\[([^\]]+)\]/g,
      (_, chord: string) =>
        `[${transposeChordToken(chord, semitones, preferFlats)}]`,
    );
  }
  return source
    .split('\n')
    .map((line) => transposeLooseLine(line, semitones, preferFlats))
    .join('\n');
}

export function transposeKey(
  key: string | null,
  semitones: number,
): string | undefined {
  if (!key?.trim()) return undefined;
  const root = CHORD_TOKEN.exec(key.trim())?.[1] ?? '';
  const preferFlats =
    root.includes('b') || ['F', 'Bb', 'Eb', 'Ab', 'Db', 'Gb'].includes(root);
  return transposeChordToken(key.trim(), semitones, preferFlats);
}
