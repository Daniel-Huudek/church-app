import { useChurch } from '../church-context';
import '../styles/home.css';

export function HomeTop() {
  const church = useChurch();

  return (
    <section className="home-top" id="topo" aria-label="Destaques">
      <div className="container home-top__grid">
        <article className="series-banner" aria-labelledby="series-title">
          <div className="series-banner__figure" aria-hidden="true" />
          <div className="series-banner__content">
            <p className="series-banner__subtitle">{church.series.subtitle}</p>
            <h1 className="series-banner__title" id="series-title">
              {church.series.title}
            </h1>
            <p className="series-banner__caption">{church.series.caption}</p>
          </div>
        </article>

        <aside className="events-panel" id="eventos" aria-labelledby="eventos-title">
          <div className="events-panel__head">
            <h2 id="eventos-title">Eventos e Programações</h2>
            <a className="btn-ghost-link" href="#eventos">
              ver mais
            </a>
          </div>
          <ul className="events-panel__list">
            {church.events.map((event) => (
              <li className="events-panel__item" key={`${event.title}-${event.date}-${event.time}`}>
                <div className="events-panel__thumb" aria-hidden="true" />
                <div>
                  <h3>{event.title}</h3>
                  <p className="events-panel__meta">
                    {event.date}
                    <br />
                    {event.time}
                  </p>
                </div>
              </li>
            ))}
          </ul>
        </aside>
      </div>
    </section>
  );
}
