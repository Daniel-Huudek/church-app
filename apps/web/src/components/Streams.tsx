import { useChurch } from '../church-context';
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
            const image = item.image?.trim();
            return (
              <li key={item.id}>
                <article
                  className={`media-card${image ? ' media-card--photo' : ''}`}
                  aria-label={item.title}
                  style={image ? { backgroundImage: `url(${image})` } : undefined}
                />
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
