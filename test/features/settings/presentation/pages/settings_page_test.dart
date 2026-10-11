import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:opensource_command_center/core/theme/app_theme.dart';
import 'package:opensource_command_center/core/theme/theme_preference.dart';
import 'package:opensource_command_center/features/auth/data/models/user_model.dart';
import 'package:opensource_command_center/features/auth/presentation/bloc/auth.dart';
import 'package:opensource_command_center/features/progress/presentation/bloc/intelligence_bloc.dart';
import 'package:opensource_command_center/features/settings/presentation/pages/settings_page.dart';
import 'package:opensource_command_center/features/settings/presentation/widgets/settings_section_card.dart';
import 'package:opensource_command_center/features/settings/presentation/widgets/theme_toggle.dart';
import 'package:opensource_command_center/services/firebase/auth_service.dart';
import 'package:opensource_command_center/services/progression/progression_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthService extends Mock implements AuthService {}

/// Pumps [SettingsPage] inside a real [GoRouter] so sign-out navigation
/// (`context.go('/login')`) resolves exactly like it does in the app.
GoRouter _testRouter(AuthBloc bloc) => GoRouter(
  initialLocation: '/settings',
  routes: [
    GoRoute(
      path: '/settings',
      builder: (_, _) => MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: bloc),
          BlocProvider<IntelligenceBloc>(
            create: (_) => IntelligenceBloc(InMemoryProgressionStore()),
          ),
        ],
        child: const SettingsPage(),
      ),
    ),
    GoRoute(
      path: '/login',
      builder: (_, _) => const Scaffold(body: Center(child: Text('Login'))),
    ),
  ],
);

Widget _wrap(AuthBloc bloc) => MaterialApp.router(
  theme: AppTheme.darkTheme,
  routerConfig: _testRouter(bloc),
);

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
    SharedPreferences.setMockInitialValues({});
    ThemePreference.notifier.value = ThemeMode.dark;
  });

  AuthBloc authenticatedBloc(UserModel user) {
    when(() => mockAuthService.currentUser).thenReturn(user);
    when(() => mockAuthService.signOut()).thenAnswer((_) async {});
    final bloc = AuthBloc(authService: mockAuthService);
    bloc.add(const AuthCheckRequested());
    return bloc;
  }

  group('SettingsPage rendering', () {
    testWidgets('renders all settings sections for an authenticated user', (
      tester,
    ) async {
      final bloc = authenticatedBloc(
        const UserModel(
          uid: 'u1',
          email: 'dev@example.com',
          displayName: 'Dev One',
        ),
      );

      await tester.pumpWidget(_wrap(bloc));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.byType(ThemeToggle), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Privacy'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
      expect(find.text('Progression'), findsOneWidget);
      expect(find.byType(SettingsSectionCard), findsNWidgets(6));

      bloc.close();
    });

    testWidgets('shows authenticated account information', (tester) async {
      final bloc = authenticatedBloc(
        UserModel(
          uid: 'u2',
          email: 'alex@example.com',
          displayName: 'Alex Rivers',
          createdAt: DateTime(2026, 1, 15),
        ),
      );

      await tester.pumpWidget(_wrap(bloc));
      await tester.pumpAndSettle();

      // Email appears twice: Account section subtitle and its info row.
      expect(find.text('alex@example.com'), findsNWidgets(2));
      expect(find.text('Alex Rivers'), findsOneWidget);
      expect(find.text('01/2026'), findsOneWidget);

      bloc.close();
    });

    testWidgets('About section shows version and environment', (tester) async {
      final bloc = authenticatedBloc(
        const UserModel(uid: 'u3', email: 'dev@example.com'),
      );

      await tester.pumpWidget(_wrap(bloc));
      await tester.pumpAndSettle();

      expect(find.text('Version'), findsOneWidget);
      expect(find.text('1.0.0'), findsOneWidget);
      expect(find.text('Environment'), findsOneWidget);

      bloc.close();
    });

    testWidgets('Notifications and Privacy are marked as not yet functional', (
      tester,
    ) async {
      final bloc = authenticatedBloc(
        const UserModel(uid: 'u4', email: 'dev@example.com'),
      );

      await tester.pumpWidget(_wrap(bloc));
      await tester.pumpAndSettle();

      // Presentation-only sections clearly marked
      expect(
        find.text('Notification delivery arrives with GitHub sync in Phase 2.'),
        findsOneWidget,
      );
      expect(find.text('Secure authorization'), findsOneWidget);
      expect(find.text('Disconnect integrations'), findsOneWidget);
      expect(find.textContaining('device-secure storage'), findsOneWidget);
      expect(find.textContaining('local snapshots'), findsOneWidget);

      // Their switches are disabled (onChanged: null)
      final switches = find.byType(Switch);
      expect(switches, findsWidgets);
      for (final widget in tester.widgetList<Switch>(switches)) {
        expect(widget.onChanged, isNull);
      }

      bloc.close();
    });

    testWidgets('renders sign-in prompt state when unauthenticated', (
      tester,
    ) async {
      when(() => mockAuthService.currentUser).thenReturn(null);
      final bloc = AuthBloc(authService: mockAuthService);
      bloc.add(const AuthCheckRequested());

      await tester.pumpWidget(_wrap(bloc));
      await tester.pumpAndSettle();

      expect(find.text('No Settings'), findsOneWidget);
      expect(
        find.text('Sign in to configure your preferences.'),
        findsOneWidget,
      );

      bloc.close();
    });
  });

  group('SettingsPage navigation & sign out', () {
    testWidgets('sign out calls service and navigates to login', (
      tester,
    ) async {
      final bloc = authenticatedBloc(
        const UserModel(uid: 'u5', email: 'dev@example.com'),
      );

      await tester.pumpWidget(_wrap(bloc));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Sign Out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      verify(() => mockAuthService.signOut()).called(1);
      expect(find.text('Login'), findsOneWidget);

      bloc.close();
    });

    testWidgets('unauthenticated state after sign out shows prompt state', (
      tester,
    ) async {
      final bloc = authenticatedBloc(
        const UserModel(uid: 'u6', email: 'dev@example.com'),
      );

      await tester.pumpWidget(_wrap(bloc));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Sign Out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      // Navigated to the login route (auth flow re-entry point)
      expect(find.text('Login'), findsOneWidget);

      bloc.close();
    });
  });

  group('SettingsPage theme persistence', () {
    testWidgets('changing theme from settings persists and applies', (
      tester,
    ) async {
      final bloc = authenticatedBloc(
        const UserModel(uid: 'u7', email: 'dev@example.com'),
      );

      await tester.pumpWidget(_wrap(bloc));
      await tester.pumpAndSettle();

      // Open the theme dropdown and pick Light
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Light').last);
      await tester.pumpAndSettle();

      expect(ThemePreference.notifier.value, ThemeMode.light);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'light');

      bloc.close();
    });
  });
}
