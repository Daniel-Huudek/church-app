import { Header } from './components/Header';
import { HomeTop } from './components/HomeTop';
import { WeeklyWord } from './components/WeeklyWord';
import { News } from './components/News';
import { Streams } from './components/Streams';
import { Footer } from './components/Footer';

export default function App() {
  return (
    <>
      <Header />
      <main>
        <HomeTop />
        <WeeklyWord />
        <div id="ipi-comunica">
          <News />
          <Streams />
        </div>
      </main>
      <Footer />
    </>
  );
}
