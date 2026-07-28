import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { Layout } from './pages/Layout';
import { HomePage } from './pages/HomePage';
import { FaithPage } from './pages/FaithPage';
import { LeadershipPage } from './pages/LeadershipPage';

export default function App() {
  return (
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
  );
}
