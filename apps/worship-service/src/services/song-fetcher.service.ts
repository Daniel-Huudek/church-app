import * as cheerio from 'cheerio';
import { AppError } from '@church-app/shared';

interface FetchedSong {
  title: string;
  artist?: string;
  key?: string;
  lyrics?: string;
  chords?: string;
  youtubeUrl?: string;
}

export class SongFetcherService {
  async fetchFromUrl(url: string): Promise<FetchedSong> {
    const hostname = new URL(url).hostname.replace('www.', '');

    if (hostname.includes('cifraclub')) return this._fetchCifraClub(url);
    if (hostname.includes('letras')) return this._fetchLetras(url);

    throw new AppError(
      `Site não suportado: ${hostname}. Suportados: cifraclub.com.br, letras.mus.br`,
      400,
    );
  }

  private async _fetchHtml(url: string): Promise<cheerio.CheerioAPI> {
    const res = await fetch(url, {
      headers: {
        'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        Accept: 'text/html,application/xhtml+xml',
      },
    });
    if (!res.ok) throw new AppError('Erro ao acessar a URL', 502);
    const html = await res.text();
    return cheerio.load(html);
  }

  private async _fetchCifraClub(url: string): Promise<FetchedSong> {
    const $ = await this._fetchHtml(url);

    const title =
      $('h1[itemprop="name"]').text().trim() ||
      $('h1.t1').text().trim() ||
      $('title').text().split('-')[0]?.trim() ||
      '';

    const artist =
      $('h2[itemprop="byArtist"] a').text().trim() ||
      $('p.music-artist a').text().trim() ||
      '';

    const key =
      $('.cifra-ton a').text().trim() ||
      $('span#cifra_ton').text().trim() ||
      $('[itemprop="key"]').text().trim() ||
      '';

    const chords: string[] = [];
    $('pre[itemprop="chordBlock"]').each((_, el) => {
      chords.push($(el).text().trim());
    });
    const chordsText = chords.join('\n\n');

    const lyrics: string[] = [];
    $('.lyrics p, .letra p, [itemprop="lyrics"] p').each((_, el) => {
      const text = $(el).text().trim();
      if (text) lyrics.push(text);
    });
    const lyricsText = lyrics.join('\n\n');

    if (!title) throw new AppError('Não foi possível extrair os dados desta página', 400);

    return {
      title,
      artist: artist || undefined,
      key: key || undefined,
      chords: chordsText || undefined,
      lyrics: lyricsText || undefined,
    };
  }

  private async _fetchLetras(url: string): Promise<FetchedSong> {
    const $ = await this._fetchHtml(url);

    const title =
      $('h1[itemprop="headline"]').text().trim() ||
      $('h1.mus-name').text().trim() ||
      $('title').text().split('-')[0]?.trim() ||
      '';

    const artist =
      $('h2[itemprop="author"] a').text().trim() ||
      $('a.art-name').text().trim() ||
      $('.artist-content a').text().trim() ||
      '';

    const lyrics: string[] = [];
    $('.lyrics p, .letra p, [itemprop="lyrics"] p, .cnt-letra p').each((_, el) => {
      const text = $(el).text().trim();
      if (text) lyrics.push(text);
    });
    const lyricsText = lyrics.join('\n\n');

    if (!title) throw new AppError('Não foi possível extrair os dados desta página', 400);

    return {
      title,
      artist: artist || undefined,
      lyrics: lyricsText || undefined,
    };
  }
}
