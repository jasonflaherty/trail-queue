import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers.dart';
import 'screens/admin_screen.dart';
import 'screens/crew_detail_screen.dart';
import 'screens/crews_screen.dart';
import 'screens/home_screen.dart';
import 'screens/issue_detail_screen.dart';
import 'screens/kanban_screen.dart';
import 'screens/login_screen.dart';
import 'screens/map_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/offline_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/organization_detail_screen.dart';
import 'screens/organizations_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/queue_screen.dart';
import 'screens/report_issue_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/trail_detail_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(servicesProvider).auth;
  final refresh = GoRouterRefreshStream(auth.authStateChanges);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final user = ref.read(authUserProvider).valueOrNull ??
          ref.read(servicesProvider).auth.currentUser;
      final loc = state.matchedLocation;
      final isLoggingIn = loc == '/login';
      final isOnboarding = loc == '/onboarding';

      if (user == null && !isLoggingIn) return '/login';
      if (user != null && isLoggingIn) {
        return user.hasCompletedOnboarding ? '/home' : '/onboarding';
      }
      if (user != null &&
          !user.hasCompletedOnboarding &&
          !isOnboarding) {
        return '/onboarding';
      }
      if (user != null && user.hasCompletedOnboarding && isOnboarding) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: MapScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/queue',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: QueueScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/crews',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: CrewsScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/issues/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return IssueDetailScreen(issueId: id);
        },
      ),
      GoRoute(
        path: '/report',
        builder: (context, state) => const ReportIssueScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/trails/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TrailDetailScreen(trailId: id);
        },
      ),
      GoRoute(
        path: '/crews/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CrewDetailScreen(crewId: id);
        },
      ),
      GoRoute(
        path: '/kanban',
        builder: (context, state) => const KanbanScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminScreen(),
      ),
      GoRoute(
        path: '/offline',
        builder: (context, state) => const OfflineScreen(),
      ),
      GoRoute(
        path: '/organizations',
        builder: (context, state) => const OrganizationsScreen(),
      ),
      GoRoute(
        path: '/organizations/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return OrganizationDetailScreen(organizationId: id);
        },
      ),
    ],
  );
});
