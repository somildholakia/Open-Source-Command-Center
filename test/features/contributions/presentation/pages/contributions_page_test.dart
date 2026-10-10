import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opensource_command_center/domain/domain.dart';
import 'package:opensource_command_center/features/contributions/presentation/pages/contributions_page.dart';
import 'package:opensource_command_center/features/contributions/presentation/widgets/contributions_header.dart';
import 'package:opensource_command_center/features/contributions/presentation/widgets/contributions_overview.dart';
import 'package:opensource_command_center/features/integrations/presentation/bloc/integration_bloc.dart';
import 'package:opensource_command_center/features/progress/presentation/bloc/intelligence_bloc.dart';
import 'package:opensource_command_center/services/progression/progression_store.dart';

import '../../../../support/fake_developer_provider.dart';
import '../../../../support/in_memory_connection_store.dart';

void main() {
  Widget createTestWidget({
    FakeDeveloperProvider? provider,
    InMemoryConnectionStore? store,
  }) {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<IntegrationBloc>(
            create: (context) {
              final bloc = IntegrationBloc(
                provider: provider ?? FakeDeveloperProvider(),
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
        child: const ContributionsPage(),
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

  ContributionSummary sampleSummary() {
    final now = DateTime.now();
    final counts = <String, int>{};
    // 3 days with contributions inside the visible 4-week window.
    for (var i = 1; i <= 3; i++) {
      final date = now.subtract(Duration(days: i));
      counts['${date.year}-${date.month.toString().padLeft(2, '0')}-'
              '${date.day.toString().padLeft(2, '0')}'] =
          i * 2;
    }
    return ContributionSummary(dailyCounts: counts, fetchedAt: now);
  }

  group('ContributionsPage', () {
    testWidgets('renders AppBar with Contributions title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await settle(tester);

      expect(find.text('Contributions'), findsOneWidget);
    });

    testWidgets('renders ContributionsHeader', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await settle(tester);

      expect(find.byType(ContributionsHeader), findsOneWidget);
    });

    testWidgets('disconnected: renders connect callout and sample preview', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await settle(tester);

      expect(find.text('Connect GitHub'), findsOneWidget);
      // Sample data remains visible but clearly disclosed: header + overview.
      expect(find.text('SAMPLE DATA'), findsNWidgets(2));
      expect(find.byType(ContributionsOverview), findsOneWidget);
      expect(find.text('ANALYTICS'), findsOneWidget);
    });

    testWidgets('connected: renders live stats and heatmap', (tester) async {
      final provider = FakeDeveloperProvider(
        connected: true,
        profile: sampleProfile(),
        contributions: sampleSummary(),
      );

      await tester.pumpWidget(
        createTestWidget(provider: provider, store: connectedStore()),
      );
      await settle(tester);
      await settle(tester);

      // Live badges replace sample disclosures (header + heatmap).
      expect(find.text('SAMPLE DATA'), findsNothing);
      expect(find.text('LIVE'), findsNWidgets(2));
      expect(find.text('LAST 12 MONTHS'), findsOneWidget);

      // Stats derived from the real summary: 2+4+6 = 12 contributions over
      // 3 active days. ('Contributions' also appears in the AppBar title, so
      // scope to the overview.)
      expect(
        find.descendant(
          of: find.byType(ContributionsOverview),
          matching: find.text('Contributions'),
        ),
        findsOneWidget,
      );
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Active Days'), findsOneWidget);
      expect(find.text('3'), findsWidgets);

      // Heatmap is live (no SAMPLE badge inside the calendar).
      expect(find.text('SAMPLE'), findsNothing);
    });

    testWidgets('connected with empty calendar shows explicit empty state', (
      tester,
    ) async {
      final provider = FakeDeveloperProvider(
        connected: true,
        profile: sampleProfile(),
        contributions: ContributionSummary(
          dailyCounts: const {},
          fetchedAt: DateTime(2026, 10, 1),
        ),
      );

      await tester.pumpWidget(
        createTestWidget(provider: provider, store: connectedStore()),
      );
      await settle(tester);
      await settle(tester);

      expect(
        find.textContaining('No contributions recorded in the last year'),
        findsOneWidget,
      );
    });

    testWidgets('connected sync failure shows typed copy with retry', (
      tester,
    ) async {
      final provider = FakeDeveloperProvider(
        connected: true,
        profile: sampleProfile(),
        dataFailure: const NetworkUnavailable(),
      );

      await tester.pumpWidget(
        createTestWidget(provider: provider, store: connectedStore()),
      );
      await settle(tester);
      await settle(tester);

      expect(
        find.text('No network connection. Check your internet and try again.'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders scrollable body', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await settle(tester);

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
