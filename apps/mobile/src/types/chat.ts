export interface Chat {
  id: string;
  type: ChatType;
  name?: string;
  avatar?: string;
  participants: ChatParticipant[];
  lastMessage?: ChatMessage;
  unreadCount: number;
  isArchived: boolean;
  isPinned: boolean;
  ministryId?: string;
  eventId?: string;
  createdAt: string;
  updatedAt: string;
}

export type ChatType = 'PRIVADO' | 'GRUPO' | 'MINISTERIO' | 'EVENTO';

export interface ChatMessage {
  id: string;
  chatId: string;
  senderId: string;
  senderName: string;
  senderAvatar?: string;
  content: string;
  type: MessageType;
  metadata?: MessageMetadata;
  replyTo?: ReplyInfo;
  isEdited: boolean;
  isDeleted: boolean;
  readBy: string[];
  deliveredAt?: string;
  readAt?: string;
  createdAt: string;
  updatedAt: string;
}

export type MessageType = 'TEXTO' | 'IMAGEM' | 'AUDIO' | 'VIDEO' | 'DOCUMENTO' | 'LOCALIZACAO' | 'SISTEMA';

export interface MessageMetadata {
  fileName?: string;
  fileSize?: number;
  mimeType?: string;
  fileUrl?: string;
  thumbnailUrl?: string;
  duration?: number;
  latitude?: number;
  longitude?: number;
  width?: number;
  height?: number;
}

export interface ReplyInfo {
  messageId: string;
  senderName: string;
  content: string;
}

export interface ChatParticipant {
  id: string;
  chatId: string;
  memberId: string;
  memberName: string;
  memberAvatar?: string;
  role: 'ADMIN' | 'MODERADOR' | 'MEMBRO';
  lastReadAt?: string;
  isMuted: boolean;
  joinedAt: string;
}

export interface ChatFilter {
  page?: number;
  limit?: number;
  type?: ChatType;
  search?: string;
  includeArchived?: boolean;
}

export interface MessageFilter {
  page?: number;
  limit?: number;
  before?: string;
  after?: string;
  type?: MessageType;
  search?: string;
}

export interface TypingIndicator {
  chatId: string;
  memberId: string;
  memberName: string;
  isTyping: boolean;
}

export type { PaginatedResponse } from './member';
