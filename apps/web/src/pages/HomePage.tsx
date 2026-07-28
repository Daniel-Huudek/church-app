import { HomeTop } from '../components/HomeTop';
import { EventsPanel } from '../components/EventsPanel';
import { WeeklyWord } from '../components/WeeklyWord';
import { News } from '../components/News';
import { Streams } from '../components/Streams';

export function HomePage() {
  return (
    <>
      <HomeTop />
      <EventsPanel />
      <WeeklyWord />
      <div id="ipi-comunica">
        <News />
        <Streams />
      </div>
    </>
  );
}
