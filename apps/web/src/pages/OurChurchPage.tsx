import { useChurch, useContentLoading } from '../church-context';
import '../styles/pages.css';

export function OurChurchPage() {
  const church = useChurch();
  const loading = useContentLoading();
  const { ourChurch, address } = church;
  const image = !loading ? ourChurch.image?.trim() : '';
  const history = ourChurch.history.filter((paragraph) => paragraph.trim());

  return (
    <div className="page-our-church">
      <section className="page-our-church__intro" aria-labelledby="our-church-title">
        <div className="container">
          <h1 className="page-title" id="our-church-title">
            {ourChurch.titlePrefix}{' '}
            <span className="page-title__accent">{ourChurch.titleAccent}</span>
          </h1>

          <div className="page-our-church__split">
            <div className="page-our-church__history">
              <h2 className="page-our-church__section-label">Nossa história</h2>
              {loading || history.length === 0 ? (
                <div className="page-our-church__history-skeleton" aria-busy="true">
                  <div className="media-skeleton media-skeleton--line" />
                  <div className="media-skeleton media-skeleton--line" />
                  <div className="media-skeleton media-skeleton--line media-skeleton--short" />
                  <div className="media-skeleton media-skeleton--line" />
                  <div className="media-skeleton media-skeleton--line media-skeleton--shorter" />
                </div>
              ) : (
                history.map((paragraph) => <p key={paragraph.slice(0, 48)}>{paragraph}</p>)
              )}
            </div>

            <figure
              className={`page-our-church__photo${image ? '' : ' media-skeleton'}`}
              aria-label="Fachada da igreja"
            >
              {image ? (
                <img src={image} alt={`${church.fullName} — fachada`} width={1200} height={900} />
              ) : null}
            </figure>
          </div>
        </div>
      </section>

      <section className="page-our-church__schedule" aria-labelledby="schedule-title">
        <div className="container">
          <h2 className="page-our-church__section-heading" id="schedule-title">
            Programação
          </h2>
          <p className="page-our-church__section-lead">
            Venha adorar conosco. Todos são bem-vindos.
          </p>
          <ul className="page-our-church__schedule-list">
            {ourChurch.schedule.map((item) => (
              <li key={`${item.day}-${item.time}`}>
                <p className="page-our-church__schedule-day">{item.day}</p>
                <p className="page-our-church__schedule-time">{item.time}</p>
                {item.label ? <p className="page-our-church__schedule-label">{item.label}</p> : null}
              </li>
            ))}
          </ul>
        </div>
      </section>

      <section className="page-our-church__map" aria-labelledby="map-title">
        <div className="container">
          <div className="page-our-church__map-head">
            <div>
              <h2 className="page-our-church__section-heading" id="map-title">
                Onde estamos
              </h2>
              <p className="page-our-church__section-lead">{address.line}</p>
            </div>
            <a className="btn btn-outline" href={address.mapUrl} target="_blank" rel="noreferrer">
              Abrir no Maps
            </a>
          </div>
          <iframe
            className="page-our-church__map-frame"
            title={`Mapa — ${church.fullName}`}
            loading="lazy"
            referrerPolicy="no-referrer-when-downgrade"
            src={address.mapEmbed}
          />
        </div>
      </section>
    </div>
  );
}
