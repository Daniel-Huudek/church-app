import { useChurch } from '../church-context';
import '../styles/sections.css';

export function WeeklyWord() {
  const church = useChurch();

  return (
    <section className="weekly-word" id="palavra" aria-labelledby="palavra-title">
      <div className="weekly-word__glow" aria-hidden="true" />
      <div className="container weekly-word__inner">
        <p className="weekly-word__eyebrow" id="palavra-title">
          Palavra da semana
        </p>
        <div className="weekly-word__mark" aria-hidden="true">
          “
        </div>
        <blockquote className="weekly-word__text">{church.weeklyWord.text}</blockquote>
        <div className="weekly-word__rule" aria-hidden="true" />
        <cite className="weekly-word__ref">{church.weeklyWord.reference}</cite>
      </div>
    </section>
  );
}
