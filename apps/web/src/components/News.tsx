import { useChurch } from '../church-context';
import { latestNews } from '../data/news';
import '../styles/sections.css';

export function News() {
  const church = useChurch();
  const news = latestNews(church.news, 4);

  return (
    <section className="section" id="noticias" aria-labelledby="noticias-title">
      <div className="container">
        <h2 className="section-title" id="noticias-title">
          Notícias IPI Avaré
        </h2>
        <ul className="card-grid">
          {news.map((item, index) => {
            const image = item.image?.trim();
            const hasTitle = Boolean(item.title?.trim());
            return (
              <li key={item.id || `news-card-${index}`}>
                <article
                  className={`media-card${image ? ' media-card--photo' : ' media-skeleton media-skeleton--card'}`}
                  aria-label={hasTitle ? item.title : `Notícia ${index + 1}`}
                  style={image ? { backgroundImage: `url(${image})` } : undefined}
                >
                  {!image && hasTitle ? (
                    <span className="media-card__label">{item.title}</span>
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
