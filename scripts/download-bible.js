/**
 * Script para baixar a Bíblia NAA (Nova Almeida Atualizada) da API.Bible
 * e gerar o arquivo assets/bible/naa/naa.json para uso offline.
 *
 * Uso:
 *   1. Crie uma conta grátis em https://api.bible/sign-up
 *   2. Adicione a NAA ao seu plano (Starter é grátis)
 *   3. Copie sua API Key e Bible ID
 *   4. Execute:
 *      node scripts/download-bible.js SUA_API_KEY SEU_BIBLE_ID
 *
 * O arquivo será gerado em: apps/flutter/assets/bible/naa/naa.json
 */

const https = require('https');
const fs = require('fs');
const path = require('path');

const API_KEY = process.argv[2];
const BIBLE_ID = process.argv[3];

if (!API_KEY || !BIBLE_ID) {
  console.error('Uso: node scripts/download-bible.js API_KEY BIBLE_ID');
  console.error('Ex: node scripts/download-bible.js abc123xyz de4e12af7f28f599-02');
  process.exit(1);
}

const BASE_URL = 'https://rest.api.bible/v1';
const HEADERS = { 'api-key': API_KEY };

function get(path) {
  return new Promise((resolve, reject) => {
    const url = `${BASE_URL}${path}`;
    https.get(url, { headers: HEADERS }, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch {
          reject(new Error(`Falha ao parsear: ${url}`));
        }
      });
    }).on('error', reject);
  });
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function main() {
  console.log('📖 Baixando lista de livros da NAA...');
  const booksRes = await get(`/bibles/${BIBLE_ID}/books`);
  const books = booksRes.data;

  const bible = {};

  for (let i = 0; i < books.length; i++) {
    const book = books[i];
    const bookId = book.id;
    const bookName = book.name;
    console.log(`[${i + 1}/${books.length}] ${bookName} (${bookId})`);

    const chaptersRes = await get(`/bibles/${BIBLE_ID}/books/${bookId}/chapters`);
    const chapters = chaptersRes.data;
    const chapterMap = {};

    for (const ch of chapters) {
      const chNum = ch.id.split('.').pop();
      process.stdout.write(`  Capítulo ${chNum}... `);

      await sleep(350);

      try {
        const versesRes = await get(`/bibles/${BIBLE_ID}/chapters/${ch.id}/verses`);
        const verses = versesRes.data;
        const verseTexts = verses.map((v) => v.text.trim());
        chapterMap[chNum] = verseTexts;
        process.stdout.write(`${verseTexts.length} versículos\n`);
      } catch (err) {
        process.stdout.write(`ERRO: ${err.message}\n`);
      }
    }

    bible[bookId] = {
      name: bookName,
      chapters: chapterMap,
    };
  }

  const outputPath = path.join(__dirname, '..', 'apps', 'flutter', 'assets', 'bible', 'naa', 'naa.json');
  const dir = path.dirname(outputPath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  fs.writeFileSync(outputPath, JSON.stringify(bible, null, 2), 'utf-8');

  const totalVerses = Object.values(bible).reduce(
    (sum, b) => sum + Object.values(b.chapters).reduce((s, v) => s + v.length, 0),
    0,
  );
  const fileSize = (fs.statSync(outputPath).size / 1024 / 1024).toFixed(2);

  console.log('\n✅ Download concluído!');
  console.log(`📁 Arquivo: ${outputPath}`);
  console.log(`📚 Livros: ${books.length}`);
  console.log(`📖 Versículos: ${totalVerses}`);
  console.log(`💾 Tamanho: ${fileSize} MB`);
}

main().catch(console.error);
