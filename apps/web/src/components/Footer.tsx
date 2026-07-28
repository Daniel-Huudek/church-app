import { Link } from 'react-router-dom';
import { church } from '../data/church';
import '../styles/footer.css';

function FooterLink({ href, children }: { href: string; children: string }) {
  if (href.startsWith('/#' ) || href.startsWith('#')) {
    return <a href={href}>{children}</a>;
  }
  if (href.startsWith('/')) {
    return <Link to={href}>{children}</Link>;
  }
  return <a href={href}>{children}</a>;
}

export function Footer() {
  return (
    <footer className="site-footer" id="conectar">
      <div className="container">
        <div className="site-footer__grid">
          <div>
            <Link className="site-footer__brand" to="/">
              <img src="/logo.png" alt="" width={36} height={36} />
              <strong>IPI Avaré</strong>
            </Link>
            <p className="site-footer__about">{church.about}</p>
          </div>

          <div>
            <h3>Link Úteis</h3>
            <ul className="site-footer__links">
              {church.usefulLinks.map((link) => (
                <li key={link.label}>
                  <FooterLink href={link.href}>{link.label}</FooterLink>
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
      </div>
      <div className="site-footer__bar">
        <p className="site-footer__copy">
          Todos os direitos reservados. {church.fullName}.
        </p>
      </div>
    </footer>
  );
}
