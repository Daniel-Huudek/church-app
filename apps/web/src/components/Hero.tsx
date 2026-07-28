import { church } from '../data/church';
import '../styles/hero.css';

function Skyline() {
  return (
    <div className="hero__skyline" aria-hidden="true">
      <div className="hero__beacon" />
      <svg viewBox="0 0 1440 900" preserveAspectRatio="xMidYMax slice">
        <defs>
          <linearGradient id="hill" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#163250" />
            <stop offset="100%" stopColor="#0a1626" />
          </linearGradient>
          <linearGradient id="towerFill" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#f4f1ea" stopOpacity="0.92" />
            <stop offset="100%" stopColor="#c9d5e5" stopOpacity="0.55" />
          </linearGradient>
        </defs>
        <path
          d="M0 690 C180 630 320 710 480 680 C650 645 760 600 920 630 C1080 660 1220 620 1440 650 L1440 900 L0 900 Z"
          fill="url(#hill)"
        />
        <g transform="translate(980 210)">
          <path
            d="M70 20 C70 20 118 78 118 150 L118 420 L22 420 L22 150 C22 78 70 20 70 20 Z"
            fill="url(#towerFill)"
          />
          <path d="M70 8 L86 34 L54 34 Z" fill="#f6d98a" />
          <rect x="58" y="170" width="24" height="10" rx="2" fill="#0b1526" opacity="0.55" />
          <rect x="58" y="230" width="24" height="10" rx="2" fill="#0b1526" opacity="0.55" />
          <rect x="58" y="290" width="24" height="10" rx="2" fill="#0b1526" opacity="0.55" />
          <path d="M58 360 L82 360 L82 420 L58 420 Z" fill="#0b1526" opacity="0.7" />
          <circle cx="70" cy="48" r="7" fill="#e8b84a" opacity="0.95" />
        </g>
        <g opacity="0.35" fill="#f6d98a">
          <circle cx="220" cy="160" r="1.6" />
          <circle cx="310" cy="110" r="1.2" />
          <circle cx="430" cy="180" r="1.4" />
          <circle cx="560" cy="90" r="1.1" />
          <circle cx="690" cy="140" r="1.5" />
          <circle cx="820" cy="70" r="1.2" />
        </g>
      </svg>
    </div>
  );
}

export function Hero() {
  return (
    <section className="hero" id="topo" aria-labelledby="hero-brand">
      <Skyline />
      <div className="container hero__content">
        <div className="hero__brand">
          <img src="/logo.png" alt="Primeira IPI Avaré" width={288} height={262} />
          <h1 className="hero__brand-name" id="hero-brand">
            {church.brand}
          </h1>
        </div>
        <p className="hero__headline">{church.tagline}</p>
        <p className="hero__support">
          Igreja Presbiteriana Independente no centro de Avaré — culto, comunhão e acolhimento para
          toda a família.
        </p>
        <div className="hero__actions">
          <a className="btn btn-primary" href="#visite">
            Visite-nos
          </a>
          <a className="btn btn-ghost" href="#cultos">
            Ver horários
          </a>
        </div>
      </div>
    </section>
  );
}
