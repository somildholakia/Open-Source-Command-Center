import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:opensource_command_center/domain/domain.dart';
import 'package:opensource_command_center/features/activity/presentation/pages/activity_page.dart';
import 'package:opensource_command_center/features/activity/presentation/widgets/activity_header.dart';
import 'package:opensource_command_center/features/activity/presentation/widgets/activity_timeline.dart';
import 'package:opensource_command_center/features/activity/presentation/widgets/activity_timeline_placeholder.dart';
import 'package:opensource_command_center/features/integrations/presentation/bloc/integration_bloc.dart';
import 'package:opensource_command_center/features/progress/presentation/bloc/intelligence_bloc.dart';
import 'package:opensource_command_center/services/progression/progression_store.dart';

import '../../../../support/fake_developer_provider.dart';
import '../../../../support/in_memory_connection_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget({
    FakeDeveloperProvider? provider,
    InMemoryConnectionStore? store,
    Future<void> Function()? holdConnect,
  }) {
    final fakeProvider = provider ?? FakeDeveloperProvider();
    if (holdConnect != null) {
      fakeProvider.onConnect = holdConnect;
    }
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
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
        child: const ActivityPage(),
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  InMemoryConnectionStore connectedStore() {
    return InMemoryConnectionStore(
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
  }

  group('ActivityPage', () {
    testWidgets('renders AppBar with Activity title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await settle(tester);

      expect(find.text('Activity'), findsOneWidget);
    });

    testWidgets('renders ActivityHeader', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await settle(tester);

      expect(find.byType(ActivityHeader), findsOneWidget);
    });

    testWidgets('disconnected: shows connect callout and clearly-labeled '
        'sample timeline', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await settle(tester);

      expect(find.text('Connect GitHub'), findsOneWidget);
      // Sample data is explicitly disclosed, never presented as real.
      expect(
        find.text(
          'Sample data shown for preview. Connect GitHub to see your own.',
        ),
        findsOneWidget,
      );
      expect(find.byType(ActivityTimelinePlaceholder), findsOneWidget);
    });

    testWidgets('connected: renders real normalized activity', (tester) async {
      final provider = FakeDeveloperProvider(
        connected: true,
        profile: sampleProfile(),
        activities: [
          sampleActivity(
            id: 'e1',
            type: DeveloperActivityType.commitPushed,
            title: 'Pushed 3 commits to main',
            commitCount: 3,
          ),
          sampleActivity(
            id: 'e2',
            type: DeveloperActivityType.pullRequestOpened,
            title: 'Add provider abstraction',
            identifier: '#42',
          ),
        ],
      );

      await tester.pumpWidget(
        createTestWidget(provider: provider, store: connectedStore()),
      );
      await settle(tester);
      await settle(tester);

      expect(find.byType(ActivityTimeline), findsOneWidget);
      expect(find.text('Add provider abstraction'), findsOneWidget);
      expect(find.text('Pushed 3 commits to main'), findsOneWidget);
      expect(find.text('Commit'), findsOneWidget);
      expect(find.text('PR Opened'), findsOneWidget);
      expect(find.text('#42'), findsOneWidget);
      expect(find.byType(ActivityTimelinePlaceholder), findsNothing);
    });

    testWidgets('filters are functional over real activity', (tester) async {
      final provider = FakeDeveloperProvider(
        connected: true,
        profile: sampleProfile(),
        activities: [
          sampleActivity(
            id: 'e1',
            type: DeveloperActivityType.commitPushed,
            title: 'Pushed 3 commits to main',
            commitCount: 3,
          ),
          sampleActivity(
            id: 'e2',
            type: DeveloperActivityType.pullRequestOpened,
            title: 'Add provider abstraction',
            identifier: '#42',
          ),
        ],
      );

      await tester.pumpWidget(
        createTestWidget(provider: provider, store: connectedStore()),
      );
      await settle(tester);
      await settle(tester);

      expect(find.text('Add provider abstraction'), findsOneWidget);

      // Filter to commits only.
      await tester.tap(find.text('Commits'));
      await tester.pump();

      expect(find.text('Pushed 3 commits to main'), findsOneWidget);
      expect(find.text('Add provider abstraction'), findsNothing);

      // Filter with no matches shows an explicit empty message.
      await tester.tap(find.text('Issues'));
      await tester.pump();

      expect(
        find.textContaining('No Issues activity in your recent events'),
        findsOneWidget,
      );
    });

    testWidgets('connected with no activity shows an explicit empty state', (
      tester,
    ) async {
      final provider = FakeDeveloperProvider(
        connected: true,
        profile: sampleProfile(),
        activities: const [],
      );

      await tester.pumpWidget(
        createTestWidget(provider: provider, store: connectedStore()),
      );
      await settle(tester);
      await settle(tester);

      expect(
        find.textContaining('No recent public activity found'),
        findsOneWidget,
      );
      expect(find.byType(ActivityTimeline), findsNothing);
    });

    testWidgets('connected sync failure shows typed copy and retry', (
      tester,
    ) async {
      final provider = FakeDeveloperProvider(
        connected: true,
        profile: sampleProfile(),
        dataFailure: const RateLimited(),
      );

      await tester.pumpWidget(
        createTestWidget(provider: provider, store: connectedStore()),
      );
      await settle(tester);
      await settle(tester);

      expect(find.textContaining('GitHub rate limit reached'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders within ResponsiveContainer', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await settle(tester);

      expect(find.byType(ActivityPage), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('tap Connect GitHub starts authorization', (tester) async {
      final provider = FakeDeveloperProvider();
      final gate = Completer<void>();

      await tester.pumpWidget(
        createTestWidget(provider: provider, holdConnect: () => gate.future),
      );
      await settle(tester);

      await tester.tap(find.text('Connect GitHub'));
      await settle(tester);

      expect(provider.connectCalls, 1);
      // Device-flow prompt replaces the callout while connecting.
      expect(find.text('ABCD-1234'), findsOneWidget);

      gate.complete();
    });
  });
}
