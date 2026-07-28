import { useChurch, useContentLoading } from '../church-context';
import { hasText, latestNews } from '../data/news';
import '../styles/sections.css';

export function News() {
  const church = useChurch();
  const loading = useContentLoading();
  const news = latestNews(church.news, 4);

  return (
    <section className="section" id="noticias" aria-labelledby="noticias-title">
      <div className="container">
        <h2 className="section-title" id="noticias-title">
          Notícias IPI Avaré
        </h2>
        <ul className="card-grid" aria-busy={loading || undefined}>
          {news.map((item, index) => {
            const image = !loading ? item.image?.trim() : '';
            const title = !loading && hasText(item.title) ? item.title.trim() : '';
            return (
              <li key={item.id || `news-card-${index}`}>
                <article
                  className={`media-card${image ? ' media-card--photo' : ' media-skeleton media-skeleton--card'}`}
                  aria-label={title || `Notícia ${index + 1}`}
                  style={image ? { backgroundImage: `url(${image})` } : undefined}
                >
                  {title && !image ? <span className="media-card__label">{title}</span> : null}
                  {!title ? (
                    <div className="media-card__skeleton-copy" aria-hidden="true">
                      <div className="media-skeleton media-skeleton--line" />
                      <div className="media-skeleton media-skeleton--line media-skeleton--short" />
                    </div>
                  ) : null}
                </article>
              </li>
            );
          })}
        </ul>
        <div className="more-wrap">
          <a className="btn btn-outline" href="#noticias">
            Ver mais
          </a>
        </div>
      </div>
    </section>
  );
}
