/**
 * Converte pt_naa.bib (MySword .BIB formato LZSS) → naa.json
 * 
 * MySword LZSS format:
 * - Header: 16 bytes
 * - Data: LZSS compressed with 4096-byte window
 * - Control byte (8 flags, MSB first), then literals or (hi, lo) references
 */

const fs = require('fs');
const path = require('path');

const BIB_PATH = path.join(__dirname, '..', 'apps', 'flutter', 'assets', 'bible', 'pt_naa.bib');
const OUTPUT_PATH = path.join(__dirname, '..', 'apps', 'flutter', 'assets', 'bible', 'naa', 'naa.json');

// Book names in Portuguese (by MySword book index, may start at 1 or 0)
const BOOK_NAMES = [
  '', 'Gênesis', 'Êxodo', 'Levítico', 'Números', 'Deuteronômio',
  'Josué', 'Juízes', 'Rute', '1 Samuel', '2 Samuel',
  '1 Reis', '2 Reis', '1 Crônicas', '2 Crônicas', 'Esdras',
  'Neemias', 'Ester', 'Jó', 'Salmos', 'Provérbios',
  'Eclesiastes', 'Cantares', 'Isaías', 'Jeremias', 'Lamentações',
  'Ezequiel', 'Daniel', 'Oseias', 'Joel', 'Amós', 'Obadias',
  'Jonas', 'Miqueias', 'Naum', 'Habacuque', 'Sofonias',
  'Ageu', 'Zacarias', 'Malaquias',
  'Mateus', 'Marcos', 'Lucas', 'João', 'Atos', 'Romanos',
  '1 Coríntios', '2 Coríntios', 'Gálatas', 'Efésios',
  'Filipenses', 'Colossenses', '1 Tessalonicenses',
  '2 Tessalonicenses', '1 Timóteo', '2 Timóteo', 'Tito',
  'Filemom', 'Hebreus', 'Tiago', '1 Pedro', '2 Pedro',
  '1 João', '2 João', '3 João', 'Judas', 'Apocalipse',
];

const BOOK_IDS = [
  '', 'GEN', 'EXO', 'LEV', 'NUM', 'DEU', 'JOS', 'JDG', 'RUT',
  '1SA', '2SA', '1KI', '2KI', '1CH', '2CH', 'EZR', 'NEH',
  'EST', 'JOB', 'PSA', 'PRO', 'ECC', 'SNG', 'ISA', 'JER',
  'LAM', 'EZK', 'DAN', 'HOS', 'JOL', 'AMO', 'OBA', 'JON',
  'MIC', 'NAM', 'HAB', 'ZEP', 'HAG', 'ZEC', 'MAL',
  'MAT', 'MRK', 'LUK', 'JHN', 'ACT', 'ROM', '1CO', '2CO',
  'GAL', 'EPH', 'PHP', 'COL', '1TH', '2TH', '1TI', '2TI',
  'TIT', 'PHM', 'HEB', 'JAS', '1PE', '2PE', '1JN', '2JN',
  '3JN', 'JUD', 'REV',
];

function lzssDecompress(data, maxOutput, useMsb) {
  const windowSize = 4096;
  const window = Buffer.alloc(windowSize, 0);
  let wp = 0;
  const output = [];
  let ip = 0;

  while (ip < data.length && output.length < maxOutput) {
    if (ip >= data.length) break;
    const flags = data[ip++];

    for (let i = 0; i < 8 && ip < data.length && output.length < maxOutput; i++) {
      const flagBit = useMsb ? (flags >> (7 - i)) : ((flags >> i) & 1);

      if (flagBit & 1) {
        const literal = data[ip++];
        output.push(literal);
        window[wp] = literal;
        wp = (wp + 1) & (windowSize - 1);
      } else {
        if (ip + 1 >= data.length) break;
        const lo = data[ip++];
        const hi = data[ip++];
        const offset = ((hi & 0xF0) << 4) | lo;
        const length = (hi & 0x0F) + 3;

        for (let j = 0; j < length && output.length < maxOutput; j++) {
          const refPos = (wp - offset - 1 + windowSize) & (windowSize - 1);
          const byte = window[refPos];
          output.push(byte);
          window[wp] = byte;
          wp = (wp + 1) & (windowSize - 1);
        }
      }
    }
  }

  return Buffer.from(output);
}

function main() {
  console.log('📖 Lendo', BIB_PATH);
  const buf = fs.readFileSync(BIB_PATH);
  const data = buf.slice(16);

  for (const msb of [false, true]) {
    for (const offset of [0, 1, 2, 3, 4]) {
      try {
        const result = lzssDecompress(data.slice(offset), 6000000, msb);
        const text = result.toString('utf8');
        
        // Check for Portuguese text
        let ptChars = 0;
        let totalChars = 0;
        let lines = text.split('\n');
        for (const line of lines) {
          totalChars += line.length;
          for (const c of line) {
            if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c > 191) {
              ptChars++;
            }
          }
        }

        const ratio = totalChars > 0 ? ptChars / totalChars : 0;
        if (result.length > 1000 && ratio > 0.3) {
          console.log(`\n✅ LZSS MSB=${msb} offset=${offset}: ${result.length} bytes, ${(ratio*100).toFixed(0)}% texto`);
          const preview = text.substring(0, 300);
          console.log('Preview:', JSON.stringify(preview));
          
          // Look for book names
          for (const name of ['Gênesis', 'Êxodo', 'Mateus', 'João']) {
            if (text.includes(name)) {
              console.log(`  Encontrou: "${name}"`);
            }
          }
        }
      } catch (e) {
        // ignore
      }
    }
  }

  // If nothing found, show the best attempt
  // Try all combinations
  console.log('\n=== Detailed search ===');
  for (const msb of [false, true]) {
    for (let offset = 0; offset < 100; offset++) {
      try {
        const result = lzssDecompress(data.slice(offset), 100000, msb);
        const text = result.toString('utf8');
        let letters = 0;
        for (const c of text) {
          if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')) letters++;
        }
        if (text.length > 100 && letters > 20) {
          console.log(`MSB=${msb} offset=${offset}: ${result.length} bytes, ${letters} letters`);
          console.log('  ', JSON.stringify(text.substring(0, 100)));
        }
      } catch(e) {}
    }
  }
}

main();
