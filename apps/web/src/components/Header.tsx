import { church } from '../data/church';
import '../styles/header.css';

export function Header() {
  return (
    <header className="site-header">
      <div className="container site-header__inner">
        <a className="site-header__brand" href="#topo" aria-label={church.brand}>
          <img src="/logo.png" alt="" width={40} height={40} />
          <span>{church.shortName}</span>
        </a>
        <nav className="site-header__nav" aria-label="Principal">
          <a href="#cultos">Cultos</a>
          <a href="#sobre">Sobre</a>
          <a href="#ministerios">Ministérios</a>
          <a href="#visite">Visite</a>
        </nav>
      </div>
    </header>
  );
}
