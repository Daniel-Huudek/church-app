import { useEffect, useState } from 'react';
import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { ChurchProvider } from './church-context';
import { fetchChurchContent } from './data/api';
import { defaultChurchContent, type ChurchContent } from './data/church';
import { Layout } from './pages/Layout';
import { HomePage } from './pages/HomePage';
import { FaithPage } from './pages/FaithPage';
import { LeadershipPage } from './pages/LeadershipPage';
import { OurChurchPage } from './pages/OurChurchPage';

export default function App() {
  const [content, setContent] = useState<ChurchContent>(defaultChurchContent);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let active = true;
    fetchChurchContent().then((data) => {
      if (!active) return;
      setContent(data);
      setLoading(false);
    });
    return () => {
      active = false;
    };
  }, []);

  return (
    <ChurchProvider value={content} loading={loading}>
      <BrowserRouter>
        <Routes>
          <Route element={<Layout />}>
            <Route index element={<HomePage />} />
            <Route path="nossa-igreja" element={<OurChurchPage />} />
            <Route path="afirmacao-de-fe" element={<FaithPage />} />
            <Route path="lideranca" element={<LeadershipPage />} />
            <Route path="*" element={<Navigate to="/" replace />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </ChurchProvider>
  );
}
