export interface Prayer {
  id: string;
  title: string;
  description: string;
  category: PrayerCategory;
  isUrgent: boolean;
  isAnswered: boolean;
  isAnonymous: boolean;
  isFavorite?: boolean;
  intercessionCount: number;
  authorId: string;
  authorName: string;
  authorAvatar?: string;
  comments: PrayerComment[];
  reactions: PrayerReaction[];
  intercessors: PrayerIntercessor[];
  createdAt: string;
  updatedAt: string;
  answeredAt?: string;
  answerDescription?: string;
}

export interface PrayerCategory {
  id: string;
  name: string;
  description?: string;
  icon?: string;
  color?: string;
  order: number;
}

export interface PrayerComment {
  id: string;
  prayerId: string;
  authorId: string;
  authorName: string;
  authorAvatar?: string;
  content: string;
  createdAt: string;
  updatedAt: string;
}

export interface PrayerReaction {
  id: string;
  prayerId: string;
  memberId: string;
  memberName: string;
  type: PrayerReactionType;
  createdAt: string;
}

export type PrayerReactionType = 'ORANDO' | 'AMEM' | 'GRATO' | 'FORCA' | 'FE' | 'PAZ';

export interface PrayerIntercessor {
  id: string;
  prayerId: string;
  memberId: string;
  memberName: string;
  memberAvatar?: string;
  createdAt: string;
}

export interface PrayerFilter {
  page?: number;
  limit?: number;
  categoryId?: string;
  isUrgent?: boolean;
  isAnswered?: boolean;
  search?: string;
  authorId?: string;
  sortBy?: 'recent' | 'popular' | 'urgent';
}

export type { PaginatedResponse } from './member';
