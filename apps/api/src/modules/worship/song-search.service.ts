import { AppError } from '@church-app/shared';

interface SearchResult {
  source: 'deezer' | 'youtube';
  title: string;
  artist: string;
  album?: string;
  cover?: string;
  thumbnail?: string;
  preview?: string;
  duration?: number;
  link?: string;
  videoId?: string;
  lyrics?: string;
}

export class SongSearchService {
  async search(query: string): Promise<SearchResult[]> {
    if (!query.trim()) throw new AppError('Informe o nome da música', 400);

    const [deezerResults, youtubeResults] = await Promise.all([
      this._searchDeezer(query).catch(() => [] as SearchResult[]),
      this._searchYoutube(query).catch(() => [] as SearchResult[]),
    ]);

    const results = [...deezerResults, ...youtubeResults];
    if (results.length === 0) throw new AppError('Nenhuma música encontrada', 404);
    return results;
  }

  private async _searchDeezer(query: string): Promise<SearchResult[]> {
    const url = `https://api.deezer.com/search?q=${encodeURIComponent(query)}&limit=10`;

    const res = await fetch(url, {
      headers: { Accept: 'application/json' },
    });
    if (!res.ok) throw new AppError('Erro ao buscar no Deezer', 502);

    const body = await res.json() as { data: any[] };
    if (!body.data?.length) return [];

    const results: SearchResult[] = [];
    for (const item of body.data.slice(0, 5)) {
      const title = item.title ?? '';
      const artist = item.artist?.name ?? '';
      results.push({
        source: 'deezer',
        title,
        artist,
        album: item.album?.title,
        cover: item.album?.cover_medium,
        preview: item.preview,
        duration: item.duration,
        link: item.link,
        lyrics: await this._fetchLyrics(title, artist).catch(() => undefined),
      });
    }
    return results;
  }

  private async _searchYoutube(query: string): Promise<SearchResult[]> {
    const apiKey = process.env.YOUTUBE_API_KEY;
    if (!apiKey) return [];

    const url = `https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&q=${encodeURIComponent(query)}&maxResults=3&key=${apiKey}`;
    const res = await fetch(url, { headers: { Accept: 'application/json' } });
    if (!res.ok) return [];

    const body = await res.json() as { items?: any[] };
    if (!body.items?.length) return [];

    return body.items.map((item: any) => ({
      source: 'youtube' as const,
      title: item.snippet?.title ?? '',
      artist: item.snippet?.channelTitle ?? '',
      thumbnail: item.snippet?.thumbnails?.medium?.url ?? item.snippet?.thumbnails?.default?.url,
      videoId: item.id?.videoId,
      link: item.id?.videoId ? `https://www.youtube.com/watch?v=${item.id.videoId}` : undefined,
    }));
  }

  private async _fetchLyrics(title: string, artist: string): Promise<string | undefined> {
    const url = `https://api.lyrics.ovh/v1/${encodeURIComponent(artist)}/${encodeURIComponent(title)}`;
    const res = await fetch(url, { headers: { Accept: 'application/json' } });
    if (!res.ok) return undefined;
    const body = await res.json() as { lyrics?: string };
    return body.lyrics?.trim() || undefined;
  }
}
