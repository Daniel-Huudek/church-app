import { church } from '../data/church';
import '../styles/sections.css';

export function Streams() {
  return (
    <section className="section" id="transmissoes" aria-labelledby="transmissoes-title">
      <div className="container">
        <h2 className="section-title" id="transmissoes-title">
          Nossas Transmissões
        </h2>
        <ul className="card-grid">
          {church.streams.map((item) => (
            <li key={item.id}>
              <article className="media-card" aria-label={item.title} />
            </li>
          ))}
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
