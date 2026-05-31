/**
 * Baixa NAA (Nova Almeida Atualizada) do YouVersion via scraper
 * e gera assets/bible/naa/naa.json
 *
 * Uso: node scripts/fetch-naa.js
 */

const https = require('https');
const fs = require('fs');
const path = require('path');

const BIBLE_ID = 1840; // NAA no YouVersion

const BOOKS = [
  ['GEN', 'Gênesis', 50], ['EXO', 'Êxodo', 40], ['LEV', 'Levítico', 27],
  ['NUM', 'Números', 36], ['DEU', 'Deuteronômio', 34], ['JOS', 'Josué', 24],
  ['JDG', 'Juízes', 21], ['RUT', 'Rute', 4], ['1SA', '1 Samuel', 31],
  ['2SA', '2 Samuel', 24], ['1KI', '1 Reis', 22], ['2KI', '2 Reis', 25],
  ['1CH', '1 Crônicas', 29], ['2CH', '2 Crônicas', 36], ['EZR', 'Esdras', 10],
  ['NEH', 'Neemias', 13], ['EST', 'Ester', 10], ['JOB', 'Jó', 42],
  ['PSA', 'Salmos', 150], ['PRO', 'Provérbios', 31], ['ECC', 'Eclesiastes', 12],
  ['SNG', 'Cantares', 8], ['ISA', 'Isaías', 66], ['JER', 'Jeremias', 52],
  ['LAM', 'Lamentações', 5], ['EZK', 'Ezequiel', 48], ['DAN', 'Daniel', 12],
  ['HOS', 'Oseias', 14], ['JOL', 'Joel', 3], ['AMO', 'Amós', 9],
  ['OBA', 'Obadias', 1], ['JON', 'Jonas', 4], ['MIC', 'Miqueias', 7],
  ['NAM', 'Naum', 3], ['HAB', 'Habacuque', 3], ['ZEP', 'Sofonias', 3],
  ['HAG', 'Ageu', 2], ['ZEC', 'Zacarias', 14], ['MAL', 'Malaquias', 4],
  ['MAT', 'Mateus', 28], ['MRK', 'Marcos', 16], ['LUK', 'Lucas', 24],
  ['JHN', 'João', 21], ['ACT', 'Atos', 28], ['ROM', 'Romanos', 16],
  ['1CO', '1 Coríntios', 16], ['2CO', '2 Coríntios', 13],
  ['GAL', 'Gálatas', 6], ['EPH', 'Efésios', 6], ['PHP', 'Filipenses', 4],
  ['COL', 'Colossenses', 4], ['1TH', '1 Tessalonicenses', 5],
  ['2TH', '2 Tessalonicenses', 3], ['1TI', '1 Timóteo', 6],
  ['2TI', '2 Timóteo', 4], ['TIT', 'Tito', 3], ['PHM', 'Filemom', 1],
  ['HEB', 'Hebreus', 13], ['JAS', 'Tiago', 5], ['1PE', '1 Pedro', 5],
  ['2PE', '2 Pedro', 3], ['1JN', '1 João', 5], ['2JN', '2 João', 1],
  ['3JN', '3 João', 1], ['JUD', 'Judas', 1], ['REV', 'Apocalipse', 22],
];

// Slug map: book name (PT) -> YouVersion slug
const SLUGS = {
  'Gênesis': 'genesis', 'Êxodo': 'exodo', 'Levítico': 'levitico',
  'Números': 'numeros', 'Deuteronômio': 'deuteronomio',
  'Josué': 'josue', 'Juízes': 'juizes', 'Rute': 'rute',
  '1 Samuel': '1-samuel', '2 Samuel': '2-samuel',
  '1 Reis': '1-reis', '2 Reis': '2-reis',
  '1 Crônicas': '1-cronicas', '2 Crônicas': '2-cronicas',
  'Esdras': 'esdras', 'Neemias': 'neemias', 'Ester': 'ester',
  'Jó': 'jo', 'Salmos': 'salmos', 'Provérbios': 'proverbios',
  'Eclesiastes': 'eclesiastes', 'Cantares': 'cantares',
  'Isaías': 'isaias', 'Jeremias': 'jeremias', 'Lamentações': 'lamentacoes',
  'Ezequiel': 'ezequiel', 'Daniel': 'daniel', 'Oseias': 'oseias',
  'Joel': 'joel', 'Amós': 'amos', 'Obadias': 'obadias',
  'Jonas': 'jonas', 'Miqueias': 'miqueias', 'Naum': 'naum',
  'Habacuque': 'habacuque', 'Sofonias': 'sofonias', 'Ageu': 'ageu',
  'Zacarias': 'zacarias', 'Malaquias': 'malaquias',
  'Mateus': 'mateus', 'Marcos': 'marcos', 'Lucas': 'lucas',
  'João': 'joao', 'Atos': 'atos', 'Romanos': 'romanos',
  '1 Coríntios': '1-corintios', '2 Coríntios': '2-corintios',
  'Gálatas': 'galatas', 'Efésios': 'efesios',
  'Filipenses': 'filipenses', 'Colossenses': 'colossenses',
  '1 Tessalonicenses': '1-tessalonicenses',
  '2 Tessalonicenses': '2-tessalonicenses',
  '1 Timóteo': '1-timoteo', '2 Timóteo': '2-timoteo',
  'Tito': 'tito', 'Filemom': 'filemom', 'Hebreus': 'hebreus',
  'Tiago': 'tiago', '1 Pedro': '1-pedro', '2 Pedro': '2-pedro',
  '1 João': '1-joao', '2 João': '2-joao', '3 João': '3-joao',
  'Judas': 'judas', 'Apocalipse': 'apocalipse',
};

function fetchUrl(url) {
  return new Promise((resolve, reject) => {
    https.get(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7',
      },
      timeout: 15000,
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(data));
    }).on('error', reject).on('timeout', function() { this.destroy(); reject(new Error('timeout')); });
  });
}

function getBookSlug(name) {
  return SLUGS[name] || name.toLowerCase().replace(/[^a-z0-9]/g, '-');
}

async function main() {
  console.log('📖 Baixando NAA do YouVersion (bible.com)...');
  console.log('⚠ Isso pode levar vários minutos (delay de 1s entre capítulos)\n');

  const bible = {};
  let totalVerses = 0;
  let failedChapters = [];

  for (const [id, name, chapters] of BOOKS) {
    console.log(`📚 ${name} (${chapters} capítulos)`);
    const chapterMap = {};
    const slug = getBookSlug(name);

    for (let ch = 1; ch <= chapters; ch++) {
      const url = `https://www.bible.com/pt/bible/${BIBLE_ID}/${slug}.${ch}.NAA`;
      process.stdout.write(`  ${ch}/${chapters}\r`);

      const html = await fetchUrl(url);

      // Parse verses from HTML using various patterns
      const verseTexts = [];
      
      // Pattern 1: YouVersion modern layout - look for verse numbers in spans
      const verseRegex = /<span class="text[^"]*"[^>]*>.*?<span class="versenum[^"]*"[^>]*>(?:<sup[^>]*>)?(\d+)(?:<\/sup>)?<\/span>\s*(.*?)<\/span>/gs;
      let match;
      while ((match = verseRegex.exec(html)) !== null) {
        const num = parseInt(match[1]);
        const txt = match[2].replace(/<[^>]+>/g, '').replace(/\s+/g, ' ').trim();
        if (num && txt) verseTexts[num - 1] = txt;
      }

      // Pattern 2: alternative YouVersion format
      if (verseTexts.filter(v => v).length === 0) {
        const altRegex = /<span data-number="(\d+)"[^>]*>.*?<\/span>\s*(.*?)<\/span>/gs;
        while ((match = altRegex.exec(html)) !== null) {
          const num = parseInt(match[1]);
          const txt = match[2].replace(/<[^>]+>/g, '').replace(/\s+/g, ' ').trim();
          if (num && txt) verseTexts[num - 1] = txt;
        }
      }

      // Pattern 3: simpler regex - numbers followed by text
      if (verseTexts.filter(v => v).length === 0) {
        const simpleRegex = /(?:<p[^>]*>|>)\s*(\d+)[:.]?\s*(.*?)(?=<[^p]|$)/gs;
        while ((match = simpleRegex.exec(html)) !== null) {
          const num = parseInt(match[1]);
          if (num >= 1 && num <= 200) {
            const txt = match[2].replace(/<[^>]+>/g, '').replace(/\s+/g, ' ').trim();
            if (txt && txt.length > 5) verseTexts[num - 1] = txt;
          }
        }
      }

      const validVerses = verseTexts.filter(v => v);
      if (validVerses.length > 0) {
        chapterMap[ch.toString()] = validVerses;
        totalVerses += validVerses.length;
      } else {
        failedChapters.push(`${name} ${ch}`);
        // Try to save raw HTML for debugging
        const debugDir = path.join(__dirname, '..', 'tmp', 'debug');
        if (!fs.existsSync(debugDir)) fs.mkdirSync(debugDir, { recursive: true });
        fs.writeFileSync(path.join(debugDir, `${id}_${ch}.html`), html.substring(0, 50000));
      }

      await new Promise(r => setTimeout(r, 1200));
    }

    bible[id] = { name, chapters: chapterMap };
  }

  // Save JSON
  const outputPath = path.join(__dirname, '..', 'apps', 'flutter', 'assets', 'bible', 'naa', 'naa.json');
  const dir = path.dirname(outputPath);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(outputPath, JSON.stringify(bible, null, 2), 'utf-8');

  const stats = fs.statSync(outputPath);
  console.log(`\n✅ Concluído!`);
  console.log(`📁 ${outputPath}`);
  console.log(`📖 ${totalVerses} versículos`);
  console.log(`💾 ${(stats.size / 1024 / 1024).toFixed(2)} MB`);

  if (failedChapters.length > 0) {
    console.log(`\n⚠ ${failedChapters.length} capítulos falharam:`);
    console.log(failedChapters.slice(0, 10).join(', '));
    if (failedChapters.length > 10) console.log(`  e mais ${failedChapters.length - 10}...`);
  }
}

main().catch(console.error);
