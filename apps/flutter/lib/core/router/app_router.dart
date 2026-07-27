import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/main_shell.dart';
import 'app_routes.dart';
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
import '../../features/members/presentation/screens/member_form_screen.dart';
import '../../features/worship/presentation/screens/worship_dashboard_screen.dart';
import '../../features/worship/presentation/screens/create_scale_screen.dart';
import '../../features/worship/presentation/screens/scale_detail_screen.dart';
import '../../features/worship/presentation/screens/create_repertorio_screen.dart';
import '../../features/worship/presentation/screens/fetch_song_screen.dart';
import '../../features/worship/presentation/screens/song_detail_screen.dart';
import '../../features/worship/presentation/screens/edit_song_screen.dart';
import '../../features/deacons/presentation/screens/deacon_dashboard_screen.dart';
import '../../features/deacons/presentation/screens/create_deacon_scale_screen.dart';
import '../../features/deacons/presentation/screens/deacon_scale_detail_screen.dart';
import '../../features/finance/presentation/screens/finance_dashboard_screen.dart';
import '../../features/finance/presentation/screens/finance_transactions_screen.dart';
import '../../features/finance/presentation/screens/finance_reports_screen.dart';
import '../../features/finance/presentation/screens/finance_cash_flow_screen.dart';
import '../../features/finance/presentation/screens/create_transaction_screen.dart';
import '../../features/notifications/presentation/screens/notification_list_screen.dart';
import '../../features/settings/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../features/chat/presentation/screens/chat_detail_screen.dart';
import '../../features/users/presentation/screens/user_list_screen.dart';
import '../../features/users/presentation/screens/user_edit_screen.dart';
import '../../features/users/presentation/screens/role_manager_screen.dart';
import '../../features/bible/presentation/screens/bible_home_screen.dart';
import '../../features/bible/presentation/screens/bible_chapter_screen.dart';
import '../../features/bible/presentation/screens/bible_verse_screen.dart';
import '../../features/bible/presentation/screens/bible_verse_reader_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final user = authState.user;
      final location = state.matchedLocation;
      final isAuthRoute = location == AppRoutes.login || location == AppRoutes.splash;

      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.home;
      }
      if (!isAuthenticated && !isAuthRoute && location != AppRoutes.splash) {
        return AppRoutes.login;
      }
      if (isAuthenticated && user != null) {
        if (location.startsWith(AppRoutes.users) && !user.hasPermission('users_read')) {
          return AppRoutes.home;
        }
        if (location.startsWith(AppRoutes.finance) && !user.hasPermission('finance_read')) {
          return AppRoutes.home;
        }
        if (location == AppRoutes.dashboard && !user.hasAnyRole(['ADMINISTRADOR', 'PASTOR', 'FINANCEIRO'])) {
          return AppRoutes.home;
        }
        // Diáconos: view for DIACONO; create/edit for leaders/admins/pastors
        if (location.startsWith(AppRoutes.deacons) &&
            !user.hasAnyRole(['ADMINISTRADOR', 'PASTOR', 'DIACONO', 'LIDER_DIACONOS'])) {
          return AppRoutes.home;
        }
        if (location == AppRoutes.deaconsCreate &&
            !user.hasAnyRole(['ADMINISTRADOR', 'PASTOR', 'LIDER_DIACONOS'])) {
          return AppRoutes.deacons;
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(
          hideNav: state.matchedLocation == AppRoutes.prayersCreate || state.matchedLocation.startsWith(AppRoutes.worship) || state.matchedLocation.startsWith(AppRoutes.deacons) || state.matchedLocation.startsWith(AppRoutes.finance),
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.prayers,
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
            path: AppRoutes.calendar,
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
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.schedules,
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
            path: AppRoutes.members,
            builder: (context, state) => const MemberListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const MemberFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => MemberDetailScreen(
                  id: state.pathParameters['id'] ?? '',
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => MemberFormScreen(
                      memberId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.finance,
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
              GoRoute(
                path: 'create/:type',
                builder: (context, state) => CreateTransactionScreen(
                  initialType: state.pathParameters['type'] ?? 'INCOME',
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.worship,
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
                path: 'repertorio/fetch',
                builder: (context, state) => const FetchSongScreen(),
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
            path: AppRoutes.deacons,
            builder: (context, state) => const DeaconDashboardScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const CreateDeaconScaleScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => DeaconScaleDetailScreen(
                  id: state.pathParameters['id'] ?? '',
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.bible,
            builder: (context, state) => const BibleHomeScreen(),
            routes: [
              GoRoute(
                path: ':book',
                builder: (context, state) => BibleChapterScreen(
                  bookId: state.pathParameters['book'] ?? '',
                ),
                routes: [
                  GoRoute(
                    path: ':chapter',
                    builder: (context, state) => BibleVerseScreen(
                      bookId: state.pathParameters['book'] ?? '',
                      chapter: int.tryParse(state.pathParameters['chapter'] ?? '1') ?? 1,
                    ),
                    routes: [
                      GoRoute(
                        path: ':verse',
                        builder: (context, state) => BibleVerseReaderScreen(
                          bookId: state.pathParameters['book'] ?? '',
                          chapter: int.tryParse(state.pathParameters['chapter'] ?? '1') ?? 1,
                          verse: int.tryParse(state.pathParameters['verse'] ?? '1') ?? 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.notifications,
            builder: (context, state) => const NotificationListScreen(),
          ),
          GoRoute(
            path: AppRoutes.chat,
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
            path: AppRoutes.users,
            builder: (context, state) => const UserListScreen(),
            routes: [
              GoRoute(
                path: 'roles',
                builder: (context, state) => const RoleManagerScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) => UserEditScreen(userId: state.pathParameters['id'] ?? ''),
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
