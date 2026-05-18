import { create } from 'zustand';

export interface AppNotification {
  id: string;
  title: string;
  body: string;
  type: 'info' | 'warning' | 'error' | 'success';
  read: boolean;
  createdAt: string;
  data?: Record<string, unknown>;
}

interface NotificationsState {
  notifications: AppNotification[];
  unreadCount: number;
  isLoaded: boolean;
  addNotification: (notification: AppNotification) => void;
  markAsRead: (id: string) => void;
  markAllAsRead: () => void;
  setNotifications: (notifications: AppNotification[]) => void;
  clearNotifications: () => void;
}

export const useNotificationsStore = create<NotificationsState>()((set, get) => ({
  notifications: [],
  unreadCount: 0,
  isLoaded: false,

  addNotification: (notification) => {
    set((state) => ({
      notifications: [notification, ...state.notifications],
      unreadCount: notification.read ? state.unreadCount : state.unreadCount + 1,
    }));
  },

  markAsRead: (id) => {
    const { notifications, unreadCount } = get();
    const notification = notifications.find((n) => n.id === id);
    if (!notification || notification.read) return;
    set({
      notifications: notifications.map((n) =>
        n.id === id ? { ...n, read: true } : n
      ),
      unreadCount: Math.max(0, unreadCount - 1),
    });
  },

  markAllAsRead: () => {
    set((state) => ({
      notifications: state.notifications.map((n) => ({ ...n, read: true })),
      unreadCount: 0,
    }));
  },

  setNotifications: (notifications) => {
    set({
      notifications,
      unreadCount: notifications.filter((n) => !n.read).length,
      isLoaded: true,
    });
  },

  clearNotifications: () => {
    set({
      notifications: [],
      unreadCount: 0,
      isLoaded: false,
    });
  },
}));
