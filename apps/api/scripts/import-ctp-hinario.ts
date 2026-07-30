/**
 * Importa o hinário CTP (Cantai Todos os Povos) para a tabela Song.
 *
 * Uso (na pasta apps/api, com DATABASE_URL configurada):
 *   pnpm import:ctp
 *   pnpm import:ctp -- --dry-run
 *   pnpm import:ctp -- --force   # atualiza letras/notas se o hino já existir
 */
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { PrismaClient } from '@prisma/client';

interface CtpHymn {
  number: string;
  title: string;
  displayTitle: string;
  artist: string;
  lyrics: string;
  reference: string | null;
  history: string | null;
  copyright: string | null;
  notes: string | null;
  tags: string[];
}

interface CtpFile {
  source: string;
  count: number;
  hymns: CtpHymn[];
}

const __dirname = dirname(fileURLToPath(import.meta.url));
const DATA_PATH = join(__dirname, '../src/modules/worship/data/ctp-hinario.json');
const TAG_COLORS: Record<string, string> = {
  CTP: '#1B4F72',
  Hinário: '#2874A6',
};

async function ensureTag(prisma: PrismaClient, name: string) {
  const existing = await prisma.tag.findFirst({ where: { name } });
  if (existing) return existing;
  return prisma.tag.create({
    data: { name, color: TAG_COLORS[name] ?? '#008CFF' },
  });
}

async function main() {
  const dryRun = process.argv.includes('--dry-run');
  const force = process.argv.includes('--force');

  const payload = JSON.parse(readFileSync(DATA_PATH, 'utf-8')) as CtpFile;
  if (!payload.hymns?.length) {
    throw new Error('Arquivo CTP sem hinos');
  }

  console.log(`Fonte: ${payload.source}`);
  console.log(`Hinos no JSON: ${payload.count} (array=${payload.hymns.length})`);
  if (dryRun) {
    console.log('[dry-run] Nenhuma alteração no banco.');
    console.log('Exemplo:', payload.hymns[0].displayTitle);
    return;
  }

  const prisma = new PrismaClient();
  try {
    const tagIds = new Map<string, string>();
    for (const name of ['CTP', 'Hinário']) {
      const tag = await ensureTag(prisma, name);
      tagIds.set(name, tag.id);
    }

    let created = 0;
    let updated = 0;
    let skipped = 0;

    for (const hymn of payload.hymns) {
      const title = hymn.displayTitle;
      const existing = await prisma.song.findFirst({
        where: {
          title,
          artist: hymn.artist,
          isActive: true,
        },
        include: { tags: true },
      });

      if (existing && !force) {
        skipped += 1;
        continue;
      }

      if (existing && force) {
        await prisma.song.update({
          where: { id: existing.id },
          data: {
            lyrics: hymn.lyrics,
            notes: hymn.notes,
            artist: hymn.artist,
          },
        });

        for (const name of hymn.tags) {
          const tagId = tagIds.get(name);
          if (!tagId) continue;
          const linked = existing.tags.some((t) => t.tagId === tagId);
          if (!linked) {
            await prisma.songTag.create({
              data: { songId: existing.id, tagId },
            });
          }
        }
        updated += 1;
        continue;
      }

      const song = await prisma.song.create({
        data: {
          title,
          artist: hymn.artist,
          lyrics: hymn.lyrics,
          notes: hymn.notes,
        },
      });

      for (const name of hymn.tags) {
        const tagId = tagIds.get(name);
        if (!tagId) continue;
        await prisma.songTag.create({
          data: { songId: song.id, tagId },
        });
      }
      created += 1;
    }

    console.log(`Importação concluída: created=${created} updated=${updated} skipped=${skipped}`);
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
