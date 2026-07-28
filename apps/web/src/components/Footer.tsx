import { church } from '../data/church';
import '../styles/footer.css';

export function Footer() {
  return (
    <footer className="site-footer" id="conectar">
      <div className="container">
        <div className="site-footer__grid">
          <div>
            <a className="site-footer__brand" href="#topo" id="nossa-igreja">
              <img src="/logo.png" alt="" width={36} height={36} />
              <strong>IPI Avaré</strong>
            </a>
            <p className="site-footer__about" id="o-que-somos">
              {church.about}
            </p>
          </div>

          <div>
            <h3>Link Úteis</h3>
            <ul className="site-footer__links">
              {church.usefulLinks.map((link) => (
                <li key={link.label}>
                  <a href={link.href}>{link.label}</a>
                </li>
              ))}
            </ul>
          </div>

          <div className="site-footer__contact">
            <h3>Nos encontre</h3>
            <p>{church.address.line}</p>
            <a href={church.address.emailHref}>{church.address.email}</a>
          </div>

          <iframe
            className="site-footer__map"
            title="Mapa da IPI Avaré"
            loading="lazy"
            referrerPolicy="no-referrer-when-downgrade"
            src={church.address.mapEmbed}
          />
        </div>

        <p className="site-footer__copy">
          Todos os direitos reservados. {church.fullName}.
        </p>
      </div>
    </footer>
  );
}
