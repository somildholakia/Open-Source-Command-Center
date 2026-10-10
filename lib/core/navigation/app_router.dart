import 'package:go_router/go_router.dart';

import '../../features/activity/presentation/pages/activity_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/contributions/presentation/pages/contributions_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/progress/presentation/pages/progress_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import 'main_shell.dart';

/// Centralized routing configuration using go_router.
///
/// Navigation structure:
/// - Auth routes: `/splash`, `/login`, `/signup`
/// - Main app shell wraps the bottom navigation with 5 tabs
/// - Each tab has its own page with persistent state
class AppRouter {
  AppRouter._(); // Private constructor

  static const String splash = '/splash';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/';
  static const String activity = '/activity';
  static const String contributions = '/contributions';
  static const String progress = '/progress';
  static const String profile = '/profile';
  static const String settings = '/settings';

  static GoRouter createRouter() => GoRouter(
    initialLocation: splash,
    routes: [
      // Auth Routes
      GoRoute(path: splash, builder: (context, state) => const SplashPage()),
      GoRoute(path: login, builder: (context, state) => const LoginPage()),
      GoRoute(path: signup, builder: (context, state) => const SignUpPage()),

      // App Shell Routes
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          GoRoute(
            path: home,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardPage()),
          ),
          GoRoute(
            path: activity,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ActivityPage()),
          ),
          GoRoute(
            path: contributions,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ContributionsPage()),
          ),
          GoRoute(
            path: progress,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProgressPage()),
          ),
          GoRoute(
            path: profile,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfilePage()),
          ),
          GoRoute(
            path: settings,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsPage()),
          ),
        ],
      ),
    ],
  );
}
