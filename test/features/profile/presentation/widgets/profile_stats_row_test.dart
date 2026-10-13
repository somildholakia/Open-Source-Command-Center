import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opensource_command_center/core/theme/app_theme.dart';
import 'package:opensource_command_center/domain/domain.dart';
import 'package:opensource_command_center/features/profile/presentation/widgets/profile_stats_row.dart';
import 'package:opensource_command_center/features/progress/presentation/bloc/intelligence_bloc.dart';
import 'package:opensource_command_center/services/progression/progression_store.dart';

void main() {
  // Thursday 2026-10-08.
  final now = DateTime(2026, 10, 8, 12);

  /// Pumps [ProfileStatsRow] with a fresh [IntelligenceBloc] and returns it
  /// (closed automatically at teardown).
  Future<IntelligenceBloc> pumpRow(
    WidgetTester tester, {
    ProgressionStore? store,
  }) async {
    final bloc = IntelligenceBloc(
      store ?? InMemoryProgressionStore(),
      clock: () => now,
    );
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: BlocProvider<IntelligenceBloc>.value(
          value: bloc,
          child: const ProfileStatsRow(),
        ),
      ),
    );
    return bloc;
  }

  /// Pumps a few frames so bloc event handlers settle.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  group('ProfileStatsRow', () {
    testWidgets('shows placeholders before any provider data exists', (
      tester,
    ) async {
      await pumpRow(tester);
      await settle(tester);

      expect(find.text('Level'), findsOneWidget);
      expect(find.text('XP'), findsOneWidget);
      expect(find.text('Streak'), findsOneWidget);
      expect(find.text('—'), findsNWidgets(3));
    });

    testWidgets('shows real progression values derived from provider data', (
      tester,
    ) async {
      final bloc = await pumpRow(tester);

      // A merge (+50 XP) plus calendar contributions over 3 consecutive days.
      bloc.add(
        IntelligenceSourceChanged(
          accountId: 'github:octocat',
          activities: [
            DeveloperActivity(
              id: 'e1',
              type: DeveloperActivityType.pullRequestMerged,
              repository: 'octocat/x',
              title: 'merge',
              timestamp: DateTime(2026, 10, 8, 9),
            ),
          ],
          contributions: const ContributionSummary(
            dailyCounts: {'2026-10-06': 1, '2026-10-07': 1, '2026-10-08': 1},
          ),
          status: IntelligenceSourceStatus.connected,
        ),
      );
      await settle(tester);

      expect(find.text('Level'), findsOneWidget);
      expect(find.text('XP'), findsOneWidget);
      expect(find.text('Streak'), findsOneWidget);
      expect(find.text('3'), findsNWidgets(2)); // level and streak days
      expect(find.text('days'), findsOneWidget);
      expect(find.text('CONTRIBUTOR'), findsOneWidget);
      expect(find.text('—'), findsNothing);
    });

    testWidgets('hides subtexts instead of showing zero values', (
      tester,
    ) async {
      await pumpRow(tester);
      await settle(tester);

      expect(find.text('total earned'), findsNothing);
      expect(find.text('RISING DEVELOPER'), findsNothing);
    });
  });
}
