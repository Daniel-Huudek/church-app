import { createContext, useContext, type ReactNode } from 'react';
import type { ChurchContent } from './data/church';
import { defaultChurchContent } from './data/church';

type ChurchContextValue = {
  content: ChurchContent;
  loading: boolean;
};

const ChurchContext = createContext<ChurchContextValue>({
  content: defaultChurchContent,
  loading: true,
});

export function ChurchProvider({
  value,
  loading = false,
  children,
}: {
  value: ChurchContent;
  loading?: boolean;
  children: ReactNode;
}) {
  return (
    <ChurchContext.Provider value={{ content: value, loading }}>{children}</ChurchContext.Provider>
  );
}

export function useChurch(): ChurchContent {
  return useContext(ChurchContext).content;
}

export function useContentLoading(): boolean {
  return useContext(ChurchContext).loading;
}
