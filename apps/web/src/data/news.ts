import type { ChurchEvent, MediaItem, StreamItem } from './church';

export function hasText(value?: string | null): boolean {
  return Boolean(value?.trim());
}

/** Keep N slots — pad with empty skeletons when the API has fewer items. */
export function latestNews(news: MediaItem[], count = 4): MediaItem[] {
  const items = news.slice(0, count).map((item, index) => ({
    id: item.id || `news-${index}`,
    title: item.title ?? '',
    image: item.image ?? '',
  }));

  while (items.length < count) {
    items.push({
      id: `news-skeleton-${items.length}`,
      title: '',
      image: '',
    });
  }

  return items;
}

export function latestStreams(streams: StreamItem[], count = 4): StreamItem[] {
  const items = streams.slice(0, count).map((item, index) => ({
    id: item.id || `stream-${index}`,
    title: item.title ?? '',
    youtubeUrl: item.youtubeUrl ?? '',
  }));

  while (items.length < count) {
    items.push({
      id: `stream-skeleton-${items.length}`,
      title: '',
      youtubeUrl: '',
    });
  }

  return items;
}

export function latestEvents(events: ChurchEvent[], count = 4): ChurchEvent[] {
  const items = events.slice(0, count).map((item) => ({
    title: item.title ?? '',
    date: item.date ?? '',
    time: item.time ?? '',
    image: item.image ?? '',
  }));

  while (items.length < count) {
    items.push({
      title: '',
      date: '',
      time: '',
      image: '',
    });
  }

  return items;
}
