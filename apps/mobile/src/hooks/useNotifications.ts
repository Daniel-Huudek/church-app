import { useCallback } from 'react';
import { useNotificationsStore } from '../store';
import { api } from '../services';

interface NotificationResponse {
  id: string;
  title: string;
  body: string;
  type: 'info' | 'warning' | 'error' | 'success';
  read: boolean;
  createdAt: string;
  data?: Record<string, unknown>;
}

interface ApiResponse<T> {
  success: boolean;
  data: T;
}

export function useNotifications() {
  const notifications = useNotificationsStore((s) => s.notifications);
  const unreadCount = useNotificationsStore((s) => s.unreadCount);
  const isLoaded = useNotificationsStore((s) => s.isLoaded);

  const addNotification = useNotificationsStore((s) => s.addNotification);
  const markAsRead = useNotificationsStore((s) => s.markAsRead);
  const markAllAsRead = useNotificationsStore((s) => s.markAllAsRead);
  const setNotifications = useNotificationsStore((s) => s.setNotifications);
  const clearNotifications = useNotificationsStore((s) => s.clearNotifications);

  const fetchNotifications = useCallback(async () => {
    const response = await api.get<ApiResponse<NotificationResponse[]>>('/notifications');
    setNotifications(response.data.data);
  }, [setNotifications]);

  const fetchUnreadCount = useCallback(async (): Promise<number> => {
    const response = await api.get<ApiResponse<{ count: number }>>('/notifications/unread-count');
    return response.data.data.count;
  }, []);

  const markAsReadOnServer = useCallback(
    async (id: string) => {
      await api.patch(`/notifications/${id}/read`);
      markAsRead(id);
    },
    [markAsRead]
  );

  const markAllAsReadOnServer = useCallback(async () => {
    await api.patch('/notifications/read-all');
    markAllAsRead();
  }, [markAllAsRead]);

  return {
    notifications,
    unreadCount,
    isLoaded,
    addNotification,
    markAsRead: markAsReadOnServer,
    markAllAsRead: markAllAsReadOnServer,
    fetchNotifications,
    fetchUnreadCount,
    clearNotifications,
    badgeCount: unreadCount,
  };
}
