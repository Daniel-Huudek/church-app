import { useEffect, useRef, useState } from 'react';
import { Link, NavLink } from 'react-router-dom';
import { useChurch } from '../church-context';
import { BrandLogo } from './BrandLogo';
import '../styles/header.css';

function SocialIcon({ icon }: { icon: 'facebook' | 'instagram' | 'youtube' }) {
  if (icon === 'facebook') {
    return (
      <svg viewBox="0 0 24 24" width="16" height="16" aria-hidden="true">
        <path
          fill="currentColor"
          d="M14 8h3V5h-3c-2.2 0-4 1.8-4 4v2H8v3h2v7h3v-7h3l1-3h-4V9c0-.6.4-1 1-1z"
        />
      </svg>
    );
  }
  if (icon === 'instagram') {
    return (
      <svg viewBox="0 0 24 24" width="16" height="16" aria-hidden="true">
        <path
          fill="currentColor"
          d="M7 3h10a4 4 0 0 1 4 4v10a4 4 0 0 1-4 4H7a4 4 0 0 1-4-4V7a4 4 0 0 1 4-4zm5 4.5A4.5 4.5 0 1 0 16.5 12 4.5 4.5 0 0 0 12 7.5zm6.2-.9a1.1 1.1 0 1 0 1.1 1.1 1.1 1.1 0 0 0-1.1-1.1zM12 9.5A2.5 2.5 0 1 1 9.5 12 2.5 2.5 0 0 1 12 9.5z"
        />
      </svg>
    );
  }
  return (
    <svg viewBox="0 0 24 24" width="16" height="16" aria-hidden="true">
      <path
        fill="currentColor"
        d="M23 7.5a3.5 3.5 0 0 0-2.5-2.5C18.7 4.5 12 4.5 12 4.5s-6.7 0-8.5.5A3.5 3.5 0 0 0 1 7.5 36.4 36.4 0 0 0 1 12a36.4 36.4 0 0 0 .5 4.5 3.5 3.5 0 0 0 2.5 2.5c1.8.5 8.5.5 8.5.5s6.7 0 8.5-.5a3.5 3.5 0 0 0 2.5-2.5A36.4 36.4 0 0 0 23 12a36.4 36.4 0 0 0 0-4.5zM10 15.2V8.8L15.5 12z"
      />
    </svg>
  );
}

function isHashLink(href: string) {
  return href.includes('#');
}

export function Header() {
  const church = useChurch();
  const [open, setOpen] = useState(false);
  const navRef = useRef<HTMLElement>(null);

  useEffect(() => {
    const onPointerDown = (event: MouseEvent) => {
      if (!navRef.current?.contains(event.target as Node)) {
        navRef.current?.querySelectorAll('details[open]').forEach((el) => {
          el.removeAttribute('open');
        });
      }
    };
    document.addEventListener('click', onPointerDown);
    return () => document.removeEventListener('click', onPointerDown);
  }, []);

  return (
    <header className="site-header">
      <div className="container site-header__inner">
        <Link className="site-header__brand" to="/" aria-label={church.brand}>
          <BrandLogo src={church.logoUrl} alt={church.logoLabel || church.brand} width={168} height={64} />
        </Link>

        <nav className="site-header__nav" aria-label="Principal" ref={navRef}>
          {church.nav.map((item) =>
            item.children ? (
              <details className="site-header__dropdown" key={item.label}>
                <summary>{item.label}</summary>
                <ul className="site-header__menu">
                  {item.children.map((child) => (
                    <li key={child.label}>
                      {isHashLink(child.href) ? (
                        <a href={child.href}>{child.label}</a>
                      ) : (
                        <Link to={child.href}>{child.label}</Link>
                      )}
                    </li>
                  ))}
                </ul>
              </details>
            ) : isHashLink(item.href) ? (
              <a key={item.label} href={item.href}>
                {item.label}
              </a>
            ) : (
              <NavLink key={item.label} to={item.href}>
                {item.label}
              </NavLink>
            ),
          )}
        </nav>

        <div className="site-header__actions">
          <div className="site-header__social" aria-label="Redes sociais">
            {church.social.map((item) => (
              <a key={item.label} href={item.href} aria-label={item.label}>
                <SocialIcon icon={item.icon} />
              </a>
            ))}
          </div>
          <button
            className="site-header__toggle"
            type="button"
            aria-expanded={open}
            aria-controls="mobile-nav"
            onClick={() => setOpen((value) => !value)}
          >
            <span className="sr-only">Menu</span>
            ☰
          </button>
        </div>
      </div>

      <div
        id="mobile-nav"
        className={`site-header__mobile container${open ? ' is-open' : ''}`}
      >
        <nav aria-label="Mobile">
          {church.nav.flatMap((item) =>
            item.children
              ? item.children.map((child) =>
                  isHashLink(child.href) ? (
                    <a key={child.label} href={child.href} onClick={() => setOpen(false)}>
                      {child.label}
                    </a>
                  ) : (
                    <Link key={child.label} to={child.href} onClick={() => setOpen(false)}>
                      {child.label}
                    </Link>
                  ),
                )
              : [
                  isHashLink(item.href) ? (
                    <a key={item.label} href={item.href} onClick={() => setOpen(false)}>
                      {item.label}
                    </a>
                  ) : (
                    <Link key={item.label} to={item.href} onClick={() => setOpen(false)}>
                      {item.label}
                    </Link>
                  ),
                ],
          )}
        </nav>
      </div>
    </header>
  );
}
