import { defaultChurchContent, type ChurchContent } from '../data/church';

declare global {
  interface Window {
    __ENV__?: {
      API_URL?: string;
    };
  }
}

const API_URL =
  (typeof window !== 'undefined' ? window.__ENV__?.API_URL : undefined)?.replace(/\/$/, '') ||
  (import.meta.env.VITE_API_URL as string | undefined)?.replace(/\/$/, '') ||
  'http://localhost:3030';

function isChurchContent(value: unknown): value is ChurchContent {
  if (!value || typeof value !== 'object') return false;
  const data = value as Record<string, unknown>;
  return typeof data.brand === 'string' && typeof data.fullName === 'string' && !!data.series;
}

export async function fetchChurchContent(): Promise<ChurchContent> {
  try {
    const response = await fetch(`${API_URL}/website`, {
      headers: { Accept: 'application/json' },
    });
    if (!response.ok) {
      return defaultChurchContent;
    }
    const json = (await response.json()) as {
      success?: boolean;
      data?: { content?: unknown };
    };
    const content = json.data?.content;
    if (isChurchContent(content)) {
      const data = content as ChurchContent;
      return {
        ...defaultChurchContent,
        ...data,
        ourChurch: data.ourChurch ?? defaultChurchContent.ourChurch,
        faith: data.faith ?? defaultChurchContent.faith,
        leadership: data.leadership ?? defaultChurchContent.leadership,
      };
    }
    return defaultChurchContent;
  } catch {
    return defaultChurchContent;
  }
}

export { API_URL };
