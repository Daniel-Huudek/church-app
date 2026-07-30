class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3030',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';
  static const String googleLogin = '/auth/google';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String me = '/auth/me';
  static const String changePassword = '/auth/password';

  // Notifications
  static const String notifications = '/notifications';
  static const String unreadCount = '/notifications/unread-count';
  static const String notificationsRead = '/notifications/read-all';

  // Events
  static const String events = '/events';
  static const String eventTypes = '/events/types';

  // Schedules
  static const String schedules = '/schedules';
  static const String scheduleRange = '/schedules/range';
  static const String scheduleConflicts = '/schedules/conflicts';

  // Members
  static const String members = '/members';
  static const String membersMe = '/members/me';
  static const String membersSearch = '/members/search';
  static const String membersBirthdays = '/members/birthdays';
  static const String ministries = '/members/ministries';

  // Prayers
  static const String prayers = '/prayers';
  static const String prayersMy = '/prayers/my';
  static const String prayersUrgent = '/prayers/urgent';
  static const String prayersFavorites = '/prayers/favorites';
  static const String prayersCategories = '/prayers/categories';

  // Finance
  static const String transactions = '/finance/transactions';
  static const String financeDashboard = '/finance/dashboard';
  static const String financeBalance = '/finance/dashboard/balance';
  static const String financeCashFlow = '/finance/dashboard/cash-flow';
  static const String financeReportsMonthly = '/finance/reports/monthly';
  static const String financeCategories = '/finance/categories';
  static const String financeCostCenters = '/finance/cost-centers';
  static const String financeMonthlyClose = '/finance/monthly-close';
  static const String financeAudit = '/finance/audit';

  // Chat
  static const String chats = '/chats';
  static const String chatUnread = '/chats/unread';

  // Worship
  static const String worshipSongs = '/worship/songs';
  static const String worshipSongsSearch = '/worship/songs/search';
  static const String worshipPlaylists = '/worship/playlists';
  static const String worshipEvents = '/worship/worship-events';
  static const String worshipFavorites = '/worship/favorites';

  // Users
  static const String users = '/users';

  // Website CMS
  static const String website = '/website';

  // Backup
  static const String backup = '/backup';
  static const String backupRestore = '/backup/restore';
}
