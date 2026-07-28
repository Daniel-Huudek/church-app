import { useEffect, useRef } from 'react';
import { church } from '../data/church';
import '../styles/worship.css';

export function Worship() {
  const listRef = useRef<HTMLUListElement>(null);

  useEffect(() => {
    const root = listRef.current;
    if (!root) return;

    const items = Array.from(root.querySelectorAll<HTMLElement>('.worship__item'));
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add('is-visible');
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.25 },
    );

    items.forEach((item, index) => {
      item.style.transitionDelay = `${index * 120}ms`;
      observer.observe(item);
    });

    return () => observer.disconnect();
  }, []);

  return (
    <section className="section worship" id="cultos" aria-labelledby="cultos-title">
      <div className="container">
        <p className="section-label">Cultos</p>
        <h2 className="section-title" id="cultos-title">
          Horários da semana
        </h2>
        <p className="section-lead">
          Reserve um tempo conosco. Confirme eventuais alterações pelos canais da igreja.
        </p>
        <ul className="worship__list" ref={listRef}>
          {church.services.map((service) => (
            <li className="worship__item" key={`${service.day}-${service.time}`}>
              <div className="worship__when">
                <span className="worship__day">{service.day}</span>
                <span className="worship__time">{service.time}</span>
              </div>
              <div>
                <h3 className="worship__title">{service.title}</h3>
                <p className="worship__note">{service.note}</p>
              </div>
            </li>
          ))}
        </ul>
        <p className="worship__footnote">
          {church.servicesNote} Telefone: {church.phone}.
        </p>
      </div>
    </section>
  );
}
