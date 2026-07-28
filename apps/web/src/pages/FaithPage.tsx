import { useChurch } from '../church-context';
import '../styles/pages.css';

export function FaithPage() {
  const church = useChurch();

  return (
    <section className="page-faith" aria-labelledby="faith-title">
      <div className="container page-faith__inner">
        <h1 className="page-title" id="faith-title">
          {church.faith.titlePrefix}{' '}
          <span className="page-title__accent">{church.faith.titleAccent}</span>
        </h1>
        <div className="page-faith__body">
          {church.faith.paragraphs.map((paragraph) => (
            <p key={paragraph}>{paragraph}</p>
          ))}
        </div>
      </div>
    </section>
  );
}
