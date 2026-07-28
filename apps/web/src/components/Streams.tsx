import { useChurch, useContentLoading } from '../church-context';
import { hasText, latestStreams } from '../data/news';
import { youtubeEmbedUrl } from '../lib/youtube';
import '../styles/sections.css';

export function Streams() {
  const church = useChurch();
  const loading = useContentLoading();
  const streams = latestStreams(church.streams, 4);

  return (
    <section className="section" id="transmissoes" aria-labelledby="transmissoes-title">
      <div className="container">
        <h2 className="section-title" id="transmissoes-title">
          Nossas Transmissões
        </h2>
        <ul className="card-grid" aria-busy={loading || undefined}>
          {streams.map((item, index) => {
            const embed = !loading ? youtubeEmbedUrl(item.youtubeUrl ?? '') : null;
            const title = !loading && hasText(item.title) ? item.title.trim() : '';
            return (
              <li key={item.id || `stream-${index}`}>
                <article className="stream-card" aria-label={title || `Transmissão ${index + 1}`}>
                  {embed ? (
                    <div className="stream-card__embed">
                      <iframe
                        src={embed}
                        title={title || `Transmissão ${index + 1}`}
                        loading="lazy"
                        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                        allowFullScreen
                        referrerPolicy="strict-origin-when-cross-origin"
                      />
                    </div>
                  ) : (
                    <div
                      className="stream-card__embed media-skeleton media-skeleton--card"
                      aria-hidden="true"
                    />
                  )}
                  {title ? (
                    <h3 className="stream-card__title">{title}</h3>
                  ) : (
                    <div className="stream-card__title-skeleton" aria-hidden="true">
                      <div className="media-skeleton media-skeleton--line" />
                      <div className="media-skeleton media-skeleton--line media-skeleton--short" />
                    </div>
                  )}
                </article>
              </li>
            );
          })}
        </ul>
        <div className="more-wrap">
          <a className="btn btn-outline" href="#transmissoes">
            Ver mais
          </a>
        </div>
      </div>
    </section>
  );
}
