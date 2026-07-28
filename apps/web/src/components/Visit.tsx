import { church } from '../data/church';
import '../styles/visit.css';

export function Visit() {
  return (
    <section className="section visit" id="visite" aria-labelledby="visite-title">
      <div className="container">
        <p className="section-label">Visite</p>
        <h2 className="section-title" id="visite-title">
          Como chegar
        </h2>
        <p className="section-lead">
          Estamos no centro de Avaré. Será uma alegria receber você e sua família.
        </p>
        <div className="visit__layout">
          <div className="visit__details">
            <div className="visit__row">
              <span>Endereço</span>
              <strong>{church.address.full}</strong>
            </div>
            <div className="visit__row">
              <span>Telefone</span>
              <a href={church.phoneHref}>{church.phone}</a>
            </div>
            <div className="visit__row">
              <span>E-mail</span>
              <a href={church.emailHref}>{church.email}</a>
            </div>
            <div className="visit__actions">
              <a className="btn btn-dark" href={church.mapUrl} target="_blank" rel="noreferrer">
                Abrir no Maps
              </a>
              <a className="btn btn-primary" href={church.phoneHref}>
                Ligar agora
              </a>
            </div>
          </div>
          <iframe
            className="visit__map"
            title="Mapa da Primeira IPI Avaré"
            loading="lazy"
            referrerPolicy="no-referrer-when-downgrade"
            src="https://maps.google.com/maps?q=Rua%20Goi%C3%A1s%201142%20Avar%C3%A9%20SP&t=&z=16&ie=UTF8&iwloc=&output=embed"
          />
        </div>
      </div>
    </section>
  );
}
