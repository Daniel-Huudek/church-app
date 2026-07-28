import { church } from '../data/church';
import '../styles/footer.css';

export function Footer() {
  const year = new Date().getFullYear();

  return (
    <footer className="site-footer">
      <div className="container site-footer__inner">
        <a className="site-footer__brand" href="#topo">
          <img src="/logo.png" alt="" width={32} height={32} />
          {church.brand}
        </a>
        <p className="site-footer__copy">
          © {year} {church.fullName}
        </p>
      </div>
    </footer>
  );
}
