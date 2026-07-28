import { useChurch, useContentLoading } from '../church-context';
import { hasText, latestEvents } from '../data/news';
import '../styles/home.css';

export function EventsPanel() {
  const church = useChurch();
  const loading = useContentLoading();
  const events = latestEvents(church.events, 4);

  return (
    <section className="events-strip" id="eventos" aria-labelledby="eventos-title">
      <div className="container">
        <div className="events-strip__head">
          <h2 id="eventos-title">Eventos e Programações</h2>
          <a className="btn-ghost-link" href="#eventos">
            ver mais
          </a>
        </div>
        <ul className="events-strip__list" aria-busy={loading || undefined}>
          {events.map((event, index) => {
            const thumb = !loading ? event.image?.trim() : '';
            const title = !loading && hasText(event.title) ? event.title.trim() : '';
            const date = !loading && hasText(event.date) ? event.date.trim() : '';
            const time = !loading && hasText(event.time) ? event.time.trim() : '';
            return (
              <li className="events-strip__item" key={`event-${index}-${title || 'sk'}`}>
                <div
                  className={`events-strip__thumb${thumb ? ' events-strip__thumb--photo' : ' media-skeleton'}`}
                  style={thumb ? { backgroundImage: `url(${thumb})` } : undefined}
                  aria-hidden="true"
                />
                <div className="events-strip__body">
                  {title ? (
                    <h3>{title}</h3>
                  ) : (
                    <div className="media-skeleton media-skeleton--line" aria-hidden="true" />
                  )}
                  {date || time ? (
                    <p className="events-strip__meta">
                      {date}
                      {date && time ? <br /> : null}
                      {time}
                    </p>
                  ) : (
                    <>
                      <div
                        className="media-skeleton media-skeleton--line media-skeleton--short"
                        aria-hidden="true"
                      />
                      <div
                        className="media-skeleton media-skeleton--line media-skeleton--shorter"
                        aria-hidden="true"
                      />
                    </>
                  )}
                </div>
              </li>
            );
          })}
        </ul>
      </div>
    </section>
  );
}
