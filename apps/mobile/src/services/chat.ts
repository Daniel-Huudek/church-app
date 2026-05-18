import type { Chat, ChatMessage, ChatFilter, MessageFilter, PaginatedResponse } from '../types/chat';
import { api } from './api';

interface ApiResponse<T> {
  success: boolean;
  data: T;
}

export const chatKeys = {
  all: ['chats'] as const,
  lists: () => [...chatKeys.all, 'list'] as const,
  list: (filters: ChatFilter) => [...chatKeys.lists(), filters] as const,
  details: () => [...chatKeys.all, 'detail'] as const,
  detail: (id: string) => [...chatKeys.details(), id] as const,
  messages: (chatId: string) => [...chatKeys.all, 'messages', chatId] as const,
  messageList: (chatId: string, filters: MessageFilter) =>
    [...chatKeys.messages(chatId), 'list', filters] as const,
};

export const chatService = {
  getConversations: async (filters?: ChatFilter): Promise<PaginatedResponse<Chat>> => {
    const response = await api.get<ApiResponse<PaginatedResponse<Chat>>>('/chats', {
      params: filters,
    });
    return response.data.data;
  },

  getConversation: async (id: string): Promise<Chat> => {
    const response = await api.get<ApiResponse<Chat>>(`/chats/${id}`);
    return response.data.data;
  },

  createConversation: async (data: {
    type: string;
    name?: string;
    participantIds: string[];
  }): Promise<Chat> => {
    const response = await api.post<ApiResponse<Chat>>('/chats', data);
    return response.data.data;
  },

  deleteConversation: async (id: string): Promise<void> => {
    await api.delete(`/chats/${id}`);
  },

  archiveConversation: async (id: string): Promise<Chat> => {
    const response = await api.put<ApiResponse<Chat>>(`/chats/${id}/archive`);
    return response.data.data;
  },

  unarchiveConversation: async (id: string): Promise<Chat> => {
    const response = await api.put<ApiResponse<Chat>>(`/chats/${id}/unarchive`);
    return response.data.data;
  },

  pinConversation: async (id: string): Promise<Chat> => {
    const response = await api.put<ApiResponse<Chat>>(`/chats/${id}/pin`);
    return response.data.data;
  },

  unpinConversation: async (id: string): Promise<Chat> => {
    const response = await api.put<ApiResponse<Chat>>(`/chats/${id}/unpin`);
    return response.data.data;
  },

  markAsRead: async (chatId: string): Promise<void> => {
    await api.post(`/chats/${chatId}/read`);
  },

  getMessages: async (chatId: string, filters?: MessageFilter): Promise<PaginatedResponse<ChatMessage>> => {
    const response = await api.get<ApiResponse<PaginatedResponse<ChatMessage>>>(
      `/chats/${chatId}/messages`,
      { params: filters }
    );
    return response.data.data;
  },

  sendMessage: async (
    chatId: string,
    data: {
      content: string;
      type?: string;
      replyTo?: string;
    }
  ): Promise<ChatMessage> => {
    const response = await api.post<ApiResponse<ChatMessage>>(`/chats/${chatId}/messages`, data);
    return response.data.data;
  },

  sendFileMessage: async (
    chatId: string,
    data: FormData
  ): Promise<ChatMessage> => {
    const response = await api.post<ApiResponse<ChatMessage>>(
      `/chats/${chatId}/messages/file`,
      data,
      { headers: { 'Content-Type': 'multipart/form-data' } }
    );
    return response.data.data;
  },

  editMessage: async (
    chatId: string,
    messageId: string,
    content: string
  ): Promise<ChatMessage> => {
    const response = await api.put<ApiResponse<ChatMessage>>(
      `/chats/${chatId}/messages/${messageId}`,
      { content }
    );
    return response.data.data;
  },

  deleteMessage: async (chatId: string, messageId: string): Promise<void> => {
    await api.delete(`/chats/${chatId}/messages/${messageId}`);
  },

  getUnreadCount: async (): Promise<{ total: number; byChat: Record<string, number> }> => {
    const response = await api.get<ApiResponse<{ total: number; byChat: Record<string, number> }>>(
      '/chats/unread'
    );
    return response.data.data;
  },

  addParticipants: async (chatId: string, memberIds: string[]): Promise<Chat> => {
    const response = await api.post<ApiResponse<Chat>>(`/chats/${chatId}/participants`, {
      memberIds,
    });
    return response.data.data;
  },

  removeParticipant: async (chatId: string, participantId: string): Promise<void> => {
    await api.delete(`/chats/${chatId}/participants/${participantId}`);
  },

  updateParticipantRole: async (
    chatId: string,
    participantId: string,
    role: string
  ): Promise<void> => {
    await api.put(`/chats/${chatId}/participants/${participantId}`, { role });
  },

  toggleMute: async (chatId: string): Promise<void> => {
    await api.post(`/chats/${chatId}/mute`);
  },
};
