import { createContext, useContext, type ReactNode } from 'react';
import type { ChurchContent } from './data/church';
import { defaultChurchContent } from './data/church';

const ChurchContext = createContext<ChurchContent>(defaultChurchContent);

export function ChurchProvider({
  value,
  children,
}: {
  value: ChurchContent;
  children: ReactNode;
}) {
  return <ChurchContext.Provider value={value}>{children}</ChurchContext.Provider>;
}

export function useChurch(): ChurchContent {
  return useContext(ChurchContext);
}
