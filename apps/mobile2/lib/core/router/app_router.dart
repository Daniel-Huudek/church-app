import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/prayers/presentation/screens/prayer_feed_screen.dart';
import '../../features/prayers/presentation/screens/prayer_detail_screen.dart';
import '../../features/events/presentation/screens/calendar_screen.dart';
import '../../features/events/presentation/screens/event_detail_screen.dart';
import '../../features/schedules/presentation/screens/schedule_list_screen.dart';
import '../../features/members/presentation/screens/member_list_screen.dart';
import '../../features/members/presentation/screens/member_detail_screen.dart';
import '../../features/finance/presentation/screens/finance_dashboard_screen.dart';
import '../../features/notifications/presentation/screens/notification_list_screen.dart';
import '../../features/settings/presentation/screens/profile_screen.dart';
import '../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../features/chat/presentation/screens/chat_detail_screen.dart';
import '../../features/users/presentation/screens/user_list_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/splash';

      if (isAuthenticated && isAuthRoute) {
        return '/';
      }
      if (!isAuthenticated &&
          !isAuthRoute &&
          state.matchedLocation != '/splash') {
        return '/login';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/prayers',
        builder: (context, state) => const PrayerFeedScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => PrayerDetailScreen(
              id: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const CalendarScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => EventDetailScreen(
              id: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/schedules',
        builder: (context, state) => const ScheduleListScreen(),
      ),
      GoRoute(
        path: '/members',
        builder: (context, state) => const MemberListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => MemberDetailScreen(
              id: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/finance',
        builder: (context, state) => const FinanceDashboardScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationListScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => ChatDetailScreen(
              id: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/users',
        builder: (context, state) => const UserListScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Erro: ${state.error}'),
      ),
    ),
  );
});
