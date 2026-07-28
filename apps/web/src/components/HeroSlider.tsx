import { useCallback, useEffect, useMemo, useState } from 'react';
import { useChurch } from '../church-context';
import type { HomeSlide } from '../data/church';

function resolveSlides(series: {
  title: string;
  subtitle: string;
  caption: string;
  image?: string;
}, slides?: HomeSlide[]): HomeSlide[] {
  if (slides && slides.length > 0) {
    return slides;
  }
  return [
    {
      id: 'series',
      title: series.title,
      subtitle: series.subtitle,
      caption: series.caption,
      image: series.image,
    },
  ];
}

export function HeroSlider() {
  const church = useChurch();
  const slides = useMemo(
    () => resolveSlides(church.series, church.slides),
    [church.series, church.slides],
  );
  const [index, setIndex] = useState(0);
  const [paused, setPaused] = useState(false);
  const count = slides.length;

  const goTo = useCallback(
    (next: number) => {
      setIndex(((next % count) + count) % count);
    },
    [count],
  );

  useEffect(() => {
    if (count <= 1 || paused) return;
    const id = window.setInterval(() => {
      setIndex((current) => (current + 1) % count);
    }, 5500);
    return () => window.clearInterval(id);
  }, [count, paused]);

  const active = slides[index] ?? slides[0];
  const image = active?.image?.trim();

  return (
    <article
      className={`hero-slider${image ? ' hero-slider--photo' : ''}`}
      aria-roledescription="carousel"
      aria-label="Destaques"
      onMouseEnter={() => setPaused(true)}
      onMouseLeave={() => setPaused(false)}
      onFocusCapture={() => setPaused(true)}
      onBlurCapture={(event) => {
        if (!event.currentTarget.contains(event.relatedTarget as Node | null)) {
          setPaused(false);
        }
      }}
    >
      <div className="hero-slider__viewport">
        {slides.map((slide, slideIndex) => {
          const photo = slide.image?.trim();
          const isActive = slideIndex === index;
          return (
            <div
              key={slide.id}
              className={`hero-slider__slide${isActive ? ' is-active' : ''}${photo ? ' has-photo' : ''}`}
              role="group"
              aria-roledescription="slide"
              aria-label={`${slideIndex + 1} de ${count}`}
              aria-hidden={!isActive}
              style={
                photo
                  ? { ['--slide-photo' as string]: `url(${photo})` }
                  : undefined
              }
            >
              <div
                className={`hero-slider__figure${photo ? '' : ' media-skeleton media-skeleton--hero'}`}
                aria-hidden="true"
              />
              <div className="hero-slider__content">
                {slide.subtitle ? <p className="hero-slider__subtitle">{slide.subtitle}</p> : null}
                <h1 className="hero-slider__title">{slide.title || 'IPI Avaré'}</h1>
                {slide.caption ? <p className="hero-slider__caption">{slide.caption}</p> : null}
              </div>
            </div>
          );
        })}
      </div>

      {count > 1 ? (
        <>
          <div className="hero-slider__controls">
            <button
              type="button"
              className="hero-slider__nav"
              aria-label="Slide anterior"
              onClick={() => goTo(index - 1)}
            >
              ‹
            </button>
            <button
              type="button"
              className="hero-slider__nav"
              aria-label="Próximo slide"
              onClick={() => goTo(index + 1)}
            >
              ›
            </button>
          </div>
          <div className="hero-slider__dots" role="tablist" aria-label="Selecionar slide">
            {slides.map((slide, slideIndex) => (
              <button
                key={slide.id}
                type="button"
                role="tab"
                aria-selected={slideIndex === index}
                aria-label={`Ir para slide ${slideIndex + 1}`}
                className={`hero-slider__dot${slideIndex === index ? ' is-active' : ''}`}
                onClick={() => goTo(slideIndex)}
              />
            ))}
          </div>
        </>
      ) : null}
    </article>
  );
}
