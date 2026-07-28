import type { MediaItem } from './church';

/** Keep the 4 latest news slots — pad with empty skeletons when the API has fewer. */
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
