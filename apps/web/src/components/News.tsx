import { useChurch } from '../church-context';
import '../styles/sections.css';

export function News() {
  const church = useChurch();

  return (
    <section className="section" id="noticias" aria-labelledby="noticias-title">
      <div className="container">
        <h2 className="section-title" id="noticias-title">
          Notícias IPI Avaré
        </h2>
        <ul className="card-grid">
          {church.news.map((item) => (
            <li key={item.id}>
              <article className="media-card" aria-label={item.title} />
            </li>
          ))}
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
