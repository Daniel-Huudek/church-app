import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/main_shell.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/admin_dashboard_screen.dart';
import '../../features/prayers/presentation/screens/prayer_feed_screen.dart';
import '../../features/prayers/presentation/screens/prayer_detail_screen.dart';
import '../../features/prayers/presentation/screens/create_prayer_screen.dart';
import '../../features/events/presentation/screens/calendar_screen.dart';
import '../../features/events/presentation/screens/event_detail_screen.dart';
import '../../features/events/presentation/screens/create_event_screen.dart';
import '../../features/events/presentation/screens/edit_event_screen.dart';
import '../../features/schedules/presentation/screens/schedule_list_screen.dart';
import '../../features/schedules/presentation/screens/schedule_detail_screen.dart';
import '../../features/schedules/presentation/screens/create_schedule_screen.dart';
import '../../features/members/presentation/screens/member_list_screen.dart';
import '../../features/members/presentation/screens/member_detail_screen.dart';
import '../../features/worship/presentation/screens/worship_dashboard_screen.dart';
import '../../features/worship/presentation/screens/create_scale_screen.dart';
import '../../features/worship/presentation/screens/scale_detail_screen.dart';
import '../../features/worship/presentation/screens/create_repertorio_screen.dart';
import '../../features/worship/presentation/screens/song_detail_screen.dart';
import '../../features/worship/presentation/screens/edit_song_screen.dart';
import '../../features/finance/presentation/screens/finance_dashboard_screen.dart';
import '../../features/finance/presentation/screens/finance_transactions_screen.dart';
import '../../features/finance/presentation/screens/finance_reports_screen.dart';
import '../../features/finance/presentation/screens/finance_cash_flow_screen.dart';
import '../../features/notifications/presentation/screens/notification_list_screen.dart';
import '../../features/settings/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../features/chat/presentation/screens/chat_detail_screen.dart';
import '../../features/users/presentation/screens/user_list_screen.dart';
import '../../features/users/presentation/screens/user_edit_screen.dart';
import '../../features/users/presentation/screens/role_manager_screen.dart';


final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final user = authState.user;
      final location = state.matchedLocation;
      final isAuthRoute = location == '/login' || location == '/splash';

      if (isAuthenticated && isAuthRoute) {
        return '/';
      }
      if (!isAuthenticated && !isAuthRoute && location != '/splash') {
        return '/login';
      }
      if (isAuthenticated && user != null) {
        final adminRoles = ['ADMINISTRADOR', 'PASTOR', 'FINANCEIRO'];
        if ((location == '/dashboard' || location.startsWith('/users')) && !user.hasAnyRole(adminRoles)) {
          return '/';
        }
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
      ShellRoute(
        builder: (context, state, child) => MainShell(
          hideNav: state.matchedLocation == '/prayers/create' || state.matchedLocation.startsWith('/worship'),
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/prayers',
            builder: (context, state) => const PrayerFeedScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const CreatePrayerScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => PrayerDetailScreen(
                  id: state.pathParameters['id'] ?? '',
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
                  id: state.pathParameters['id'] ?? '',
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => EditEventScreen(
                      id: state.pathParameters['id'] ?? '',
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'create',
                builder: (context, state) => const CreateEventScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/schedules',
            builder: (context, state) => const ScheduleListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => ScheduleDetailScreen(
                  id: state.pathParameters['id'] ?? '',
                ),
              ),
              GoRoute(
                path: 'create',
                builder: (context, state) => const CreateScheduleScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/members',
            builder: (context, state) => const MemberListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => MemberDetailScreen(
                  id: state.pathParameters['id'] ?? '',
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/finance',
            builder: (context, state) => const FinanceDashboardScreen(),
            routes: [
              GoRoute(
                path: 'transactions',
                builder: (context, state) => const FinanceTransactionsScreen(),
              ),
              GoRoute(
                path: 'reports',
                builder: (context, state) => const FinanceReportsScreen(),
              ),
              GoRoute(
                path: 'cash-flow',
                builder: (context, state) => const FinanceCashFlowScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/worship',
            builder: (context, state) => const WorshipDashboardScreen(),
            routes: [
              GoRoute(
                path: 'scale/create',
                builder: (context, state) => const CreateScaleScreen(),
              ),
              GoRoute(
                path: 'scale/:id/edit',
                builder: (context, state) => CreateScaleScreen(scaleId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'scale/:id',
                builder: (context, state) => ScaleDetailScreen(id: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'repertorio/create',
                builder: (context, state) => const CreateRepertorioScreen(),
              ),
              GoRoute(
                path: 'songs/:id',
                builder: (context, state) => SongDetailScreen(songId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => EditSongScreen(songId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
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
                  id: state.pathParameters['id'] ?? '',
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/users',
            builder: (context, state) => const UserListScreen(),
            routes: [
              GoRoute(
                path: 'roles',
                builder: (context, state) => const RoleManagerScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) => UserEditScreen(userId: state.pathParameters['id']!),
              ),
            ],
          ),

        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Erro: ${state.error}'),
      ),
    ),
  );
});
