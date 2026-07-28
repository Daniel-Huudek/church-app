import { useChurch } from '../church-context';
import '../styles/home.css';

export function EventsPanel() {
  const church = useChurch();

  return (
    <section className="events-strip" id="eventos" aria-labelledby="eventos-title">
      <div className="container">
        <div className="events-strip__head">
          <h2 id="eventos-title">Eventos e Programações</h2>
          <a className="btn-ghost-link" href="#eventos">
            ver mais
          </a>
        </div>
        <ul className="events-strip__list">
          {church.events.map((event) => {
            const thumb = event.image?.trim();
            return (
              <li className="events-strip__item" key={`${event.title}-${event.date}-${event.time}`}>
                <div
                  className={`events-strip__thumb${thumb ? ' events-strip__thumb--photo' : ' media-skeleton'}`}
                  style={thumb ? { backgroundImage: `url(${thumb})` } : undefined}
                  aria-hidden="true"
                />
                <div>
                  <h3>{event.title}</h3>
                  <p className="events-strip__meta">
                    {event.date}
                    <br />
                    {event.time}
                  </p>
                </div>
              </li>
            );
          })}
        </ul>
      </div>
    </section>
  );
}
