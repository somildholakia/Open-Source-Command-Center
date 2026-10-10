import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:opensource_command_center/core/theme/app_theme.dart';
import 'package:opensource_command_center/domain/domain.dart';
import 'package:opensource_command_center/features/auth/data/models/user_model.dart';
import 'package:opensource_command_center/features/auth/presentation/bloc/auth.dart';
import 'package:opensource_command_center/features/integrations/presentation/bloc/integration_bloc.dart';
import 'package:opensource_command_center/features/progress/presentation/bloc/intelligence_bloc.dart';
import 'package:opensource_command_center/features/profile/presentation/pages/profile_page.dart';
import 'package:opensource_command_center/features/profile/presentation/widgets/profile_empty_state.dart';
import 'package:opensource_command_center/features/profile/presentation/widgets/profile_header.dart';
import 'package:opensource_command_center/features/profile/presentation/widgets/profile_loading_state.dart';
import 'package:opensource_command_center/features/profile/presentation/widgets/profile_stats_row.dart';
import 'package:opensource_command_center/features/profile/presentation/widgets/profile_sign_out_button.dart';
import 'package:opensource_command_center/services/firebase/auth_service.dart';
import 'package:opensource_command_center/services/progression/progression_store.dart';

import '../../../../support/fake_developer_provider.dart';
import '../../../../support/in_memory_connection_store.dart';

class MockAuthService extends Mock implements AuthService {}

class MockAuthBloc extends Mock implements AuthBloc {}

/// Pumps [ProfilePage] inside a real [GoRouter] so sign-out navigation
/// (`context.go('/login')`) resolves exactly like it does in the app.
///
/// Profile now also renders the GitHub connection card, so a real
/// [IntegrationBloc] (fake provider, in-memory store) is provided too.
GoRouter _testRouter(
  AuthBloc bloc, {
  FakeDeveloperProvider? integrationProvider,
  InMemoryConnectionStore? connectionStore,
}) => GoRouter(
  initialLocation: '/profile',
  routes: [
    GoRoute(
      path: '/profile',
      builder: (_, _) => MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: bloc),
          BlocProvider<IntegrationBloc>(
            create: (_) {
              final integrationBloc = IntegrationBloc(
                provider: integrationProvider ?? FakeDeveloperProvider(),
                storeFactory: () async =>
                    connectionStore ?? InMemoryConnectionStore(),
              );
              integrationBloc.add(const IntegrationStarted());
              return integrationBloc;
            },
          ),
          BlocProvider<IntelligenceBloc>(
            create: (_) => IntelligenceBloc(InMemoryProgressionStore()),
          ),
        ],
        child: const ProfilePage(),
      ),
    ),
    GoRoute(
      path: '/login',
      builder: (_, _) => const Scaffold(body: Center(child: Text('Login'))),
    ),
  ],
);

void main() {
  late MockAuthService mockAuthService;
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthService = MockAuthService();
    mockAuthBloc = MockAuthBloc();
  });

  group('ProfilePage', () {
    testWidgets('renders ProfileLoadingState when AuthLoading', (
      WidgetTester tester,
    ) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthLoading());
      when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockAuthBloc.isClosed).thenReturn(false);

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: _testRouter(mockAuthBloc),
        ),
      );

      expect(find.byType(ProfileLoadingState), findsOneWidget);
    });

    testWidgets('renders ProfileHeader with user data when authenticated', (
      WidgetTester tester,
    ) async {
      // Need to handle image loading for tests.
      await tester.runAsync(() async {
        // Run as async to allow image loading attempts to not interfere.
      });

      final testUser = UserModel(
        uid: 'test_uid',
        email: 'tester@example.com',
        displayName: 'Code Master',
        createdAt: DateTime(2026, 1, 1),
      );
      when(() => mockAuthService.currentUser).thenReturn(testUser);

      final authBloc = AuthBloc(authService: mockAuthService);
      authBloc.add(const AuthCheckRequested());
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: _testRouter(authBloc),
        ),
      );

      // Wait for the async AuthCheckRequested completion to reach AuthAuthenticated.
      await tester.pumpAndSettle();

      expect(find.text('Code Master'), findsOneWidget);
      expect(find.text('tester@example.com'), findsOneWidget);
      expect(find.text('Member since 01/2026'), findsOneWidget);
      expect(find.byType(ProfileHeader), findsOneWidget);
      expect(find.byType(ProfileStatsRow), findsOneWidget);

      authBloc.close();
    });

    testWidgets('renders ProfileEmptyState when unauthenticated', (
      WidgetTester tester,
    ) async {
      when(() => mockAuthService.currentUser).thenReturn(null);

      final authBloc = AuthBloc(authService: mockAuthService);
      authBloc.add(const AuthCheckRequested());
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: _testRouter(authBloc),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Profile Data'), findsOneWidget);
      expect(find.byType(ProfileEmptyState), findsOneWidget);

      authBloc.close();
    });

    testWidgets('dispatches AuthSignOutRequested on sign out tap', (
      WidgetTester tester,
    ) async {
      final testUser = UserModel(
        uid: 'test_uid',
        email: 'tester@example.com',
        displayName: 'Code Master',
      );

      when(() => mockAuthService.currentUser).thenReturn(testUser);
      when(() => mockAuthService.signOut()).thenAnswer((_) async {});

      final authBloc = AuthBloc(authService: mockAuthService);
      authBloc.add(const AuthCheckRequested());
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: _testRouter(authBloc),
        ),
      );
      await tester.pumpAndSettle();

      final signOutButton = find.byType(ProfileSignOutButton);
      await tester.ensureVisible(signOutButton);
      await tester.pumpAndSettle();

      await tester.tap(signOutButton);
      await tester.pump();
      // The BLoC handles AuthSignOutRequested: emits AuthLoading, then calls
      // authService.signOut(), then the page navigates to /login.
      await tester.pumpAndSettle();

      verify(() => mockAuthService.signOut()).called(1);
      // Sign-out navigates back to the login route via go_router.
      expect(find.text('Login'), findsOneWidget);

      authBloc.close();
    });
  });

  group('ProfilePage GitHub connection card', () {
    UserModel buildUser() => UserModel(
      uid: 'test_uid',
      email: 'tester@example.com',
      displayName: 'Code Master',
    );

    testWidgets('shows a real connect CTA when no GitHub account is linked', (
      WidgetTester tester,
    ) async {
      when(() => mockAuthService.currentUser).thenReturn(buildUser());

      final authBloc = AuthBloc(authService: mockAuthService);
      authBloc.add(const AuthCheckRequested());
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: _testRouter(authBloc),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('Not connected'), findsOneWidget);
      expect(find.text('Connect GitHub'), findsOneWidget);

      authBloc.close();
    });

    testWidgets('shows the connected GitHub account and disconnect action', (
      WidgetTester tester,
    ) async {
      when(() => mockAuthService.currentUser).thenReturn(buildUser());

      final provider = FakeDeveloperProvider(connected: true);
      final store = InMemoryConnectionStore(
        ProviderConnectionRecord.connected(
          providerId: 'github',
          account: const ConnectedAccount(
            providerId: 'github',
            username: 'octocat',
            avatarUrl: '',
            profileUrl: '',
          ),
        ),
      );

      final authBloc = AuthBloc(authService: mockAuthService);
      authBloc.add(const AuthCheckRequested());
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: _testRouter(
            authBloc,
            integrationProvider: provider,
            connectionStore: store,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('@octocat'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);

      // Disconnect is confirm-gated, then clears through the provider.
      await tester.ensureVisible(find.text('Disconnect'));
      await tester.tap(find.text('Disconnect'));
      await tester.pumpAndSettle();
      expect(find.text('Disconnect GitHub?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Disconnect'));
      await tester.pumpAndSettle();

      expect(provider.disconnectCalls, 1);
      expect(find.text('Not connected'), findsOneWidget);

      authBloc.close();
    });
  });

  group('ProfilePage responsive', () {
    testWidgets('renders correctly on mobile width', (
      WidgetTester tester,
    ) async {
      // physicalSize is in physical pixels: 1080x2400 @ 3.0 is a 360x800
      // logical phone. (The previous 375x812 @ 3.0 implied a 125px-wide
      // viewport, which is not a real phone size.)
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final testUser = UserModel(
        uid: 'test_uid',
        email: 'tester@example.com',
        displayName: 'Code Master',
      );
      when(() => mockAuthService.currentUser).thenReturn(testUser);

      final authBloc = AuthBloc(authService: mockAuthService);
      authBloc.add(const AuthCheckRequested());

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: _testRouter(authBloc),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProfilePage), findsOneWidget);
      expect(find.text('Code Master'), findsOneWidget);

      authBloc.close();
    });

    testWidgets('renders correctly on tablet width', (
      WidgetTester tester,
    ) async {
      // 1668x2224 @ 2.0 = 834x1112 logical (tablet).
      tester.view.physicalSize = const Size(1668, 2224);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final testUser = UserModel(
        uid: 'test_uid',
        email: 'tester@example.com',
        displayName: 'Code Master',
      );
      when(() => mockAuthService.currentUser).thenReturn(testUser);

      final authBloc = AuthBloc(authService: mockAuthService);
      authBloc.add(const AuthCheckRequested());

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: _testRouter(authBloc),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProfilePage), findsOneWidget);
      expect(find.text('Code Master'), findsOneWidget);

      authBloc.close();
    });
  });
}
