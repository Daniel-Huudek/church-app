import { church } from '../data/church';
import '../styles/about.css';

export function About() {
  return (
    <section className="section about" id="sobre" aria-labelledby="sobre-title">
      <div className="container">
        <p className="section-label">Sobre</p>
        <h2 className="section-title" id="sobre-title">
          {church.fullName}
        </h2>
        <div className="about__grid">
          <p className="about__mission">{church.mission}</p>
          <dl className="about__meta">
            <dt>Denominação</dt>
            <dd>{church.denomination}</dd>
            <dt>Pastorado</dt>
            <dd>{church.pastor}</dd>
            <dt>Cidade</dt>
            <dd>
              {church.address.city}/{church.address.state}
            </dd>
          </dl>
        </div>
      </div>
    </section>
  );
}
