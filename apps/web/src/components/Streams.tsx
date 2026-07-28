import { useChurch } from '../church-context';
import { youtubeEmbedUrl } from '../lib/youtube';
import '../styles/sections.css';

export function Streams() {
  const church = useChurch();

  return (
    <section className="section" id="transmissoes" aria-labelledby="transmissoes-title">
      <div className="container">
        <h2 className="section-title" id="transmissoes-title">
          Nossas Transmissões
        </h2>
        <ul className="card-grid">
          {church.streams.map((item) => {
            const embed = youtubeEmbedUrl(item.youtubeUrl ?? '');
            return (
              <li key={item.id}>
                <article className="stream-card" aria-label={item.title}>
                  {embed ? (
                    <div className="stream-card__embed">
                      <iframe
                        src={embed}
                        title={item.title}
                        loading="lazy"
                        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                        allowFullScreen
                        referrerPolicy="strict-origin-when-cross-origin"
                      />
                    </div>
                  ) : (
                    <div className="media-card" aria-hidden="true" />
                  )}
                  {item.title ? <h3 className="stream-card__title">{item.title}</h3> : null}
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
