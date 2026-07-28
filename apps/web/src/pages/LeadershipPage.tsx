import { useChurch } from '../church-context';
import '../styles/pages.css';

export function LeadershipPage() {
  const { leadership } = useChurch();

  return (
    <section className="page-leadership" aria-labelledby="leadership-title">
      <div className="container page-leadership__inner">
        <h1 className="page-title" id="leadership-title">
          {leadership.titlePrefix}{' '}
          <span className="page-title__accent">{leadership.titleAccent}</span>
        </h1>

        <figure className="page-leadership__photo">
          <img src={leadership.image} alt={leadership.name} width={1200} height={640} />
        </figure>

        <h2 className="page-leadership__name">{leadership.name}</h2>
        <p className="page-leadership__role">{leadership.role}</p>
        <p className="page-leadership__bio">{leadership.bio}</p>
      </div>
    </section>
  );
}
