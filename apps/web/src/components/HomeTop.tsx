import { useChurch, useContentLoading } from '../church-context';
import { HeroSlider } from './HeroSlider';
import { hasText, latestNews } from '../data/news';
import '../styles/home.css';

export function HomeTop() {
  const church = useChurch();
  const loading = useContentLoading();
  const news = latestNews(church.news, 4);

  return (
    <section className="home-top" id="topo" aria-label="Destaques">
      <div className="container home-top__grid">
        <HeroSlider />

        <aside className="news-panel" id="noticias-destaque" aria-labelledby="noticias-side-title">
          <div className="news-panel__head">
            <h2 id="noticias-side-title">Notícias</h2>
            <a className="btn-ghost-link" href="#noticias">
              ver mais
            </a>
          </div>
          <ul className="news-panel__list" aria-busy={loading || undefined}>
            {news.map((item, index) => {
              const image = !loading ? item.image?.trim() : '';
              const title = !loading && hasText(item.title) ? item.title.trim() : '';
              return (
                <li className="news-panel__item" key={item.id || `news-${index}`}>
                  <div
                    className={`news-panel__thumb${image ? ' news-panel__thumb--photo' : ' media-skeleton'}`}
                    style={image ? { backgroundImage: `url(${image})` } : undefined}
                    aria-hidden="true"
                  />
                  <div className="news-panel__body">
                    {title ? (
                      <h3>{title}</h3>
                    ) : (
                      <>
                        <div className="media-skeleton media-skeleton--line" aria-hidden="true" />
                        <div
                          className="media-skeleton media-skeleton--line media-skeleton--short"
                          aria-hidden="true"
                        />
                      </>
                    )}
                  </div>
                </li>
              );
            })}
          </ul>
        </aside>
      </div>
    </section>
  );
}
