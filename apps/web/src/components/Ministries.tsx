import { church } from '../data/church';
import '../styles/ministries.css';

export function Ministries() {
  return (
    <section className="section ministries" id="ministerios" aria-labelledby="ministerios-title">
      <div className="container">
        <p className="section-label">Ministérios</p>
        <h2 className="section-title" id="ministerios-title">
          Servindo juntos
        </h2>
        <p className="section-lead">
          Áreas em que a igreja vive o evangelho no cotidiano — da adoração ao cuidado uns dos
          outros.
        </p>
        <ul className="ministries__list">
          {church.ministries.map((ministry) => (
            <li className="ministries__item" key={ministry.name}>
              <h3>{ministry.name}</h3>
              <p>{ministry.description}</p>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
