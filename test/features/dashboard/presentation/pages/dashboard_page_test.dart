import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opensource_command_center/core/theme/app_theme.dart';
import 'package:opensource_command_center/domain/domain.dart';
import 'package:opensource_command_center/features/auth/data/models/user_model.dart';
import 'package:opensource_command_center/features/auth/presentation/bloc/auth.dart';
import 'package:opensource_command_center/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:opensource_command_center/features/dashboard/presentation/widgets/attention_feed_placeholder.dart';
import 'package:opensource_command_center/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:opensource_command_center/features/dashboard/presentation/widgets/github_connect_hero_card.dart';
import 'package:opensource_command_center/features/dashboard/presentation/widgets/stats_overview_grid.dart';
import 'package:opensource_command_center/features/dashboard/presentation/widgets/streak_and_quest_cards.dart';
import 'package:opensource_command_center/features/integrations/presentation/bloc/integration_bloc.dart';
import 'package:opensource_command_center/features/progress/presentation/bloc/intelligence_bloc.dart';
import 'package:opensource_command_center/services/firebase/auth_service.dart';
import 'package:opensource_command_center/services/progression/progression_store.dart';

import '../../../../support/fake_developer_provider.dart';
import '../../../../support/in_memory_connection_store.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuthService;

  final testUser = UserModel(
    uid: 'dev_123',
    email: 'alex@example.com',
    displayName: 'Alex Rivers',
    createdAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    mockAuthService = MockAuthService();
    when(() => mockAuthService.currentUser).thenReturn(null);
  });

  Widget createTestWidget({
    UserModel? user,
    FakeDeveloperProvider? provider,
    InMemoryConnectionStore? store,
    Future<void> Function()? holdConnect,
  }) {
    when(() => mockAuthService.currentUser).thenReturn(user);

    final fakeProvider = provider ?? FakeDeveloperProvider();
    if (holdConnect != null) {
      fakeProvider.onConnect = holdConnect;
    }

    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) {
              final bloc = AuthBloc(authService: mockAuthService);
              if (user != null) {
                bloc.emit(AuthAuthenticated(user: user));
              }
              return bloc;
            },
          ),
          BlocProvider<IntegrationBloc>(
            create: (context) {
              final bloc = IntegrationBloc(
                provider: fakeProvider,
                storeFactory: () async => store ?? InMemoryConnectionStore(),
              );
              bloc.add(const IntegrationStarted());
              return bloc;
            },
          ),
          BlocProvider<IntelligenceBloc>(
            create: (_) => IntelligenceBloc(InMemoryProgressionStore()),
          ),
        ],
        child: const DashboardPage(),
      ),
    );
  }

  /// Pumps enough frames for the integration bloc's async work to settle.
  Future<void> settleIntegration(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  group('DashboardPage', () {
    testWidgets('renders all major sections and components', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await settleIntegration(tester);

      // Header & Navigation title
      expect(find.text('Home'), findsOneWidget);
      expect(find.byType(DashboardHeader), findsOneWidget);
      expect(find.text('COMMAND CENTER v0.1'), findsOneWidget);
      expect(find.text('LVL 1 • NOVICE'), findsOneWidget);
      expect(find.text('Hello, Developer!'), findsOneWidget);

      // Connection hero (disconnected -> connect CTA). 'CONNECT GITHUB'
      // appears on the hero title and as the stats caption.
      expect(find.byType(GithubConnectHeroCard), findsOneWidget);
      expect(find.text('CONNECT GITHUB'), findsNWidgets(2));
      expect(find.text('Connect GitHub Account'), findsOneWidget);

      // Streaks & Quests
      expect(find.byType(StreakAndQuestCards), findsOneWidget);
      expect(find.text('CURRENT STREAK'), findsOneWidget);
      expect(find.text('DAILY QUEST #1'), findsOneWidget);
      expect(find.text('Daily Contribution'), findsOneWidget);
      expect(find.text('+25 XP'), findsOneWidget);

      // Stats Grid (placeholder values while disconnected)
      expect(find.byType(StatsOverviewGrid), findsOneWidget);
      expect(find.text('TELEMETRY SNAPSHOT'), findsOneWidget);
      expect(find.text('Pull Requests'), findsOneWidget);
      expect(find.text('Issues Solved'), findsOneWidget);
      expect(find.text('Commits'), findsOneWidget);
      expect(find.text('Code Reviews'), findsOneWidget);
      expect(find.text('CONNECT GITHUB'), findsWidgets);

      // Repositories section stays hidden while disconnected
      expect(find.text('REPOSITORIES'), findsNothing);

      // Attention Feed Placeholder
      expect(find.byType(AttentionFeedPlaceholder), findsOneWidget);
      expect(find.text('NEEDS ATTENTION'), findsOneWidget);
      expect(find.text('All queues clear'), findsOneWidget);
    });

    testWidgets('displays dynamic authenticated user displayName in header', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(user: testUser));
      await settleIntegration(tester);

      expect(find.text('Hello, Alex Rivers!'), findsOneWidget);
    });

    testWidgets('tapping the CTA starts GitHub authorization and shows the '
        'device-flow prompt', (WidgetTester tester) async {
      final gate = Completer<void>();
      final provider = FakeDeveloperProvider();
      await tester.pumpWidget(
        createTestWidget(provider: provider, holdConnect: () => gate.future),
      );
      await settleIntegration(tester);

      final button = find.text('Connect GitHub Account');
      expect(button, findsOneWidget);

      await tester.ensureVisible(button);
      await tester.tap(button);
      await settleIntegration(tester);

      // Device-flow user code + cancel action are visible; no API calls were
      // made from the UI layer.
      expect(provider.connectCalls, 1);
      expect(find.text('ABCD-1234'), findsOneWidget);
      expect(find.text('Open GitHub'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Finishing authorization completes the connection.
      gate.complete();
      await settleIntegration(tester);
      expect(find.text('@octocat'), findsOneWidget);
    });

    testWidgets('shows live telemetry and repositories when connected', (
      WidgetTester tester,
    ) async {
      final provider = FakeDeveloperProvider(
        connected: true,
        profile: sampleProfile(),
        repositories: [sampleRepository()],
        activities: [
          sampleActivity(id: '1'),
          sampleActivity(
            id: '2',
            type: DeveloperActivityType.pullRequestOpened,
          ),
          sampleActivity(
            id: '3',
            type: DeveloperActivityType.pullRequestMerged,
          ),
          sampleActivity(id: '4', type: DeveloperActivityType.issueClosed),
          sampleActivity(
            id: '5',
            type: DeveloperActivityType.pullRequestReviewed,
          ),
        ],
      );

      await tester.pumpWidget(
        createTestWidget(
          provider: provider,
          store: InMemoryConnectionStore(
            ProviderConnectionRecord.connected(
              providerId: 'github',
              account: const ConnectedAccount(
                providerId: 'github',
                username: 'octocat',
                avatarUrl: '',
                profileUrl: '',
              ),
            ),
          ),
        ),
      );
      await settleIntegration(tester);
      await settleIntegration(tester);

      // Connected banner replaces the connect CTA.
      expect(find.text('@octocat'), findsOneWidget);
      expect(find.text('Connect GitHub Account'), findsNothing);

      // Live telemetry counted from normalized activity.
      expect(find.text('LAST 5 EVENTS'), findsOneWidget);
      expect(find.text('2'), findsWidgets); // pull requests opened + merged
      expect(find.text('1'), findsWidgets); // issues solved / reviews

      // Repositories section renders real normalized repositories.
      expect(find.text('REPOSITORIES'), findsOneWidget);
      expect(find.text('MOST RECENT'), findsOneWidget);
      expect(find.text('command-center'), findsOneWidget);
      expect(find.text('Dart'), findsOneWidget);

      // Integration fetched through the provider (not the UI).
      expect(provider.fetchProfileCalls, greaterThan(0));
      expect(provider.fetchRepositoriesCalls, greaterThan(0));
      expect(provider.fetchActivityCalls, greaterThan(0));
    });

    testWidgets('shows typed failure copy when a connected sync fails', (
      WidgetTester tester,
    ) async {
      final provider = FakeDeveloperProvider(
        connected: true,
        profile: sampleProfile(),
        dataFailure: const NetworkUnavailable(),
      );

      await tester.pumpWidget(
        createTestWidget(
          provider: provider,
          store: InMemoryConnectionStore(
            ProviderConnectionRecord.connected(
              providerId: 'github',
              account: const ConnectedAccount(
                providerId: 'github',
                username: 'octocat',
                avatarUrl: '',
                profileUrl: '',
              ),
            ),
          ),
        ),
      );
      await settleIntegration(tester);
      await settleIntegration(tester);

      expect(
        find.text('No network connection. Check your internet and try again.'),
        findsWidgets,
      );
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders properly on tablet resolution', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(2048, 1536);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await settleIntegration(tester);

      expect(find.text('COMMAND CENTER v0.1'), findsOneWidget);
      expect(find.text('TELEMETRY SNAPSHOT'), findsOneWidget);
    });
  });
}
