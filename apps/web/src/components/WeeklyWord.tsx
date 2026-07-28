import { church } from '../data/church';
import '../styles/sections.css';

export function WeeklyWord() {
  return (
    <section className="weekly-word" id="palavra" aria-labelledby="palavra-title">
      <div className="container">
        <h2 className="weekly-word__label" id="palavra-title">
          Palavra da semana
        </h2>
        <blockquote className="weekly-word__text">“{church.weeklyWord.text}”</blockquote>
        <p className="weekly-word__ref">{church.weeklyWord.reference}</p>
      </div>
    </section>
  );
}
