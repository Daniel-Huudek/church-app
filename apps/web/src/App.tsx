import { Header } from './components/Header';
import { Hero } from './components/Hero';
import { Worship } from './components/Worship';
import { About } from './components/About';
import { Ministries } from './components/Ministries';
import { Visit } from './components/Visit';
import { Footer } from './components/Footer';

export default function App() {
  return (
    <>
      <a className="skip-link" href="#cultos">
        Ir para o conteúdo
      </a>
      <Header />
      <main>
        <Hero />
        <Worship />
        <About />
        <Ministries />
        <Visit />
      </main>
      <Footer />
    </>
  );
}
