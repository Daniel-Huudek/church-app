import { useEffect, useState } from 'react';
import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { ChurchProvider } from './church-context';
import { fetchChurchContent } from './data/api';
import { defaultChurchContent, type ChurchContent } from './data/church';
import { Layout } from './pages/Layout';
import { HomePage } from './pages/HomePage';
import { FaithPage } from './pages/FaithPage';
import { LeadershipPage } from './pages/LeadershipPage';

export default function App() {
  const [content, setContent] = useState<ChurchContent>(defaultChurchContent);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    let active = true;
    fetchChurchContent().then((data) => {
      if (!active) return;
      setContent(data);
      setReady(true);
    });
    return () => {
      active = false;
    };
  }, []);

  if (!ready) {
    return (
      <div
        style={{
          minHeight: '100vh',
          display: 'grid',
          placeItems: 'center',
          fontFamily: 'Outfit, system-ui, sans-serif',
          color: '#5b6b7f',
        }}
      >
        Carregando…
      </div>
    );
  }

  return (
    <ChurchProvider value={content}>
      <BrowserRouter>
        <Routes>
          <Route element={<Layout />}>
            <Route index element={<HomePage />} />
            <Route path="afirmacao-de-fe" element={<FaithPage />} />
            <Route path="lideranca" element={<LeadershipPage />} />
            <Route path="*" element={<Navigate to="/" replace />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </ChurchProvider>
  );
}
