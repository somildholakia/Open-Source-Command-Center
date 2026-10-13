import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opensource_command_center/core/theme/app_colors.dart';
import 'package:opensource_command_center/core/theme/app_theme.dart';
import 'package:opensource_command_center/domain/domain.dart';
import 'package:opensource_command_center/features/integrations/presentation/bloc/integration_bloc.dart';
import 'package:opensource_command_center/features/progress/presentation/bloc/intelligence_bloc.dart';
import 'package:opensource_command_center/features/progress/presentation/pages/progress_page.dart';
import 'package:opensource_command_center/features/progress/presentation/utils/progress_share_text.dart';
import 'package:opensource_command_center/features/progress/presentation/widgets/intelligence_visuals.dart';
import 'package:opensource_command_center/features/progress/presentation/widgets/progress_achievement_card.dart';
import 'package:opensource_command_center/features/progress/presentation/widgets/progress_level_card.dart';
import 'package:opensource_command_center/features/progress/presentation/widgets/progress_quest_card.dart';
import 'package:opensource_command_center/features/progress/presentation/widgets/progress_xp_breakdown_card.dart';
import 'package:opensource_command_center/services/progression/progression_store.dart';

import '../../../../support/fake_developer_provider.dart';

void main() {
  // Thursday 2026-10-08; the current week started Monday 2026-10-05.
  final now = DateTime(2026, 10, 8, 12);

  final mergeActivity = DeveloperActivity(
    id: 'e1',
    type: DeveloperActivityType.pullRequestMerged,
    repository: 'octocat/x',
    title: 'merge',
    timestamp: DateTime(2026, 10, 8, 9),
  );
  final pushActivity = DeveloperActivity(
    id: 'e2',
    type: DeveloperActivityType.commitPushed,
    repository: 'octocat/x',
    title: 'push',
    timestamp: DateTime(2026, 10, 7, 9),
    commitCount: 2,
  );
  const calendar = ContributionSummary(
    dailyCounts: {
      '2026-10-05': 1,
      '2026-10-06': 1,
      '2026-10-07': 2,
      '2026-10-08': 1,
    },
  );

  /// The connected snapshot the page tests run against.
  ///
  /// Expected engine output: activity XP 60, consistency XP 40, achievement XP
  /// 115, and quest XP 165 (daily contribution 25 + weekly contributions 60 +
  /// weekly consistency 80) = 380 XP -> level 3, 80/300 into level 3.
  IntelligenceSourceChanged connectedSource({ProviderFailure? failure}) {
    return IntelligenceSourceChanged(
      accountId: 'github:octocat',
      activities: [mergeActivity, pushActivity],
      contributions: calendar,
      status: failure == null
          ? IntelligenceSourceStatus.connected
          : IntelligenceSourceStatus.failed,
      failure: failure,
    );
  }

  IntelligenceBloc blocWithSource({ProviderFailure? failure}) {
    final bloc = IntelligenceBloc(InMemoryProgressionStore(), clock: () => now);
    bloc.add(connectedSource(failure: failure));
    return bloc;
  }

  Future<void> pumpPage(
    WidgetTester tester,
    IntelligenceBloc bloc, {
    IntegrationBloc? integration,
  }) async {
    final integrationBloc =
        integration ?? IntegrationBloc(provider: FakeDeveloperProvider());
    addTearDown(integrationBloc.close);

    // Fixed frame budget: the TweenAnimationBuilder reveal is finite, so the
    // page settles (no indeterminate spinners anywhere in this screen).
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<IntegrationBloc>.value(value: integrationBloc),
            BlocProvider<IntelligenceBloc>.value(value: bloc),
          ],
          child: const ProgressPage(),
        ),
      ),
    );
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  group('ProgressPage', () {
    testWidgets('shows the connect CTA while disconnected — never fake XP', (
      tester,
    ) async {
      final bloc = IntelligenceBloc(
        InMemoryProgressionStore(),
        clock: () => now,
      );
      addTearDown(bloc.close);

      await pumpPage(tester, bloc);

      expect(find.text('CONNECT GITHUB'), findsOneWidget);
      expect(find.byType(ProgressLevelCard), findsNothing);
      expect(find.text('Daily Quests'), findsNothing);
    });

    testWidgets('shows a typed error state with retry when the sync fails', (
      tester,
    ) async {
      final bloc = IntelligenceBloc(
        InMemoryProgressionStore(),
        clock: () => now,
      );
      addTearDown(bloc.close);
      bloc.add(
        const IntelligenceSourceChanged(
          accountId: 'github:octocat',
          status: IntelligenceSourceStatus.failed,
          failure: NetworkUnavailable(),
        ),
      );

      await pumpPage(tester, bloc);

      expect(
        find.text('No network connection. Check your internet and try again.'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byType(ProgressLevelCard), findsNothing);
    });

    testWidgets('renders the full progression from real derived data', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final bloc = blocWithSource();
      addTearDown(bloc.close);

      await pumpPage(tester, bloc);

      // Pin the engine output the UI is rendering.
      final level = bloc.state.intelligence.level;
      expect(level.level, 3);
      expect(level.totalXp, 380);
      expect(level.xpIntoLevel, 80);
      expect(level.xpForNextLevel, 300);

      // Level hero bound to the engine's output.
      expect(find.byType(ProgressLevelCard), findsOneWidget);
      expect(find.text('LEVEL 3'), findsOneWidget);
      expect(find.text('CONTRIBUTOR'), findsOneWidget);
      expect(find.text('27%'), findsOneWidget); // 80/300 rounds to 27%.
      expect(find.text('220 XP TO LEVEL 4'), findsOneWidget);
      expect(find.text('380 TOTAL XP'), findsOneWidget);

      // Stats row: streak, XP and badge count.
      expect(find.text('4'), findsOneWidget); // streak days
      expect(find.text('380'), findsOneWidget); // total XP

      // XP sources explain where the XP came from. 'Achievements' appears
      // twice: once as an XP source row, once as the section header. Reward
      // chips on quest/achievement cards legitimately repeat some amounts.
      expect(find.text('XP SOURCES'), findsOneWidget);
      expect(find.text('Achievements'), findsNWidgets(2));
      expect(find.text('Quests'), findsOneWidget);
      expect(find.text('+60 XP'), findsWidgets); // century club + week quest
      expect(find.text('+40 XP'), findsWidgets);
      expect(find.text('+115 XP'), findsOneWidget); // breakdown row only

      // Achievements: unlocked ones are labeled, locked ones show progress.
      expect(find.text('3 / 15 UNLOCKED'), findsOneWidget);
      expect(find.text('UNLOCKED'), findsWidgets);
      expect(find.text('LOCKED'), findsWidgets);
      expect(find.byType(ProgressAchievementCard), findsNWidgets(15));

      // Quest sections split by period with real window progress:
      // completed today: daily contribution; completed this week:
      // contributions + consistency.
      expect(find.text('Daily Quests'), findsOneWidget);
      expect(find.text('Weekly Quests'), findsOneWidget);
      expect(find.byType(ProgressQuestCard), findsNWidgets(7));
      // '1 / 1' shows on the completed daily contribution quest and on the
      // first-contribution / first-merge achievement cards.
      expect(find.text('1 / 1'), findsNWidgets(3));
      expect(find.text('COMPLETED'), findsNWidgets(3));

      semantics.dispose();
    });

    testWidgets('shows a stale-data notice when a refresh fails on top of '
        'loaded data', (tester) async {
      final bloc = blocWithSource();
      addTearDown(bloc.close);

      await pumpPage(tester, bloc);
      expect(find.byType(ProgressLevelCard), findsOneWidget);

      // A later snapshot keeps the data but reports a failed refresh.
      bloc.add(connectedSource(failure: const ApiUnavailable(statusCode: 503)));
      await pumpPage(tester, bloc);

      expect(bloc.state.isStale, isTrue);
      expect(find.textContaining('last data that synced'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byType(ProgressLevelCard), findsOneWidget);
    });
  });

  group('ProgressLevelCard', () {
    testWidgets('renders the level curve values it is handed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: ProgressLevelCard(level: LevelSystem.compute(250)),
          ),
        ),
      );

      expect(find.text('LEVEL 2'), findsOneWidget);
      expect(find.text('150 / 200 XP'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('50 XP TO LEVEL 3'), findsOneWidget);
      expect(find.text('250 TOTAL XP'), findsOneWidget);
    });

    testWidgets('announces level progress for screen readers', (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: ProgressLevelCard(level: LevelSystem.compute(150)),
          ),
        ),
      );
      // Let the finite XP-bar reveal finish so the announced percentage is
      // the final one (25% of level 2 at 150 XP).
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(
        find.bySemanticsLabel(RegExp('Level 2 progress 25 percent')),
        findsOneWidget,
      );

      semantics.dispose();
    });
  });

  group('ProgressAchievementCard', () {
    testWidgets('shows progress toward a locked achievement', (tester) async {
      final definition = AchievementCatalog.all.firstWhere(
        (a) => a.id == 'week_storm',
      );
      final status = AchievementStatus(
        definition: definition,
        unlocked: false,
        progress: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: ProgressAchievementCard(status: status, now: now),
          ),
        ),
      );

      expect(find.text('Storm Week'), findsOneWidget);
      expect(find.text('Stay active for 7 days in a row.'), findsOneWidget);
      expect(find.text('3 / 7'), findsOneWidget);
      expect(find.text('LOCKED'), findsOneWidget);
      expect(find.text('+70 XP'), findsOneWidget);
    });

    testWidgets('shows the unlock time for a recorded unlock', (tester) async {
      final definition = AchievementCatalog.all.firstWhere(
        (a) => a.id == 'first_merge',
      );
      final status = AchievementStatus(
        definition: definition,
        unlocked: true,
        progress: 2,
        unlockedAt: now.toUtc().subtract(const Duration(hours: 2)),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: ProgressAchievementCard(status: status, now: now),
          ),
        ),
      );

      expect(find.text('First Merge'), findsOneWidget);
      expect(find.text('UNLOCKED'), findsOneWidget);
      expect(find.text('unlocked 2 hours ago'), findsOneWidget);
    });
  });

  group('ProgressQuestCard', () {
    QuestProgress questOf(String id, {bool completed = false}) {
      final definition = QuestCatalog.all.firstWhere((q) => q.id == id);
      return QuestProgress(
        definition: definition,
        state: completed ? QuestState.completed : QuestState.available,
        progress: completed ? definition.target : definition.target - 1,
        periodKey: definition.periodKey(now),
        periodEndsAt: definition.periodEndsAt(now),
      );
    }

    testWidgets('a completed quest is labeled and fully filled', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: ProgressQuestCard(
              quest: questOf('daily_commit', completed: true),
              now: now,
            ),
          ),
        ),
      );

      expect(find.text('DAILY'), findsOneWidget);
      expect(find.text('Daily Commit'), findsOneWidget);
      expect(find.text('1 / 1'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('+20 XP'), findsOneWidget);
    });

    testWidgets('an active quest counts down to the reset', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: ProgressQuestCard(
              quest: questOf('weekly_pull_requests'),
              now: now,
            ),
          ),
        ),
      );

      expect(find.text('WEEKLY'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);
      expect(find.text('RESETS IN 3D 12H'), findsOneWidget);
    });
  });

  group('ProgressXpBreakdownCard', () {
    testWidgets(
      'breaks XP into activity, consistency, achievements and quests',
      (tester) async {
       await tester.pumpWidget(
         MaterialApp(
           theme: AppTheme.darkTheme,
           home: Scaffold(
             body: ProgressXpBreakdownCard(
               xp: const XpBreakdown(
                 byActivityType: {
                   DeveloperActivityType.pullRequestMerged: 50,
                   DeveloperActivityType.commitPushed: 10,
                 },
                 activityXp: 60,
                 activeDayXp: 40,
                 achievementXp: 75,
                 questXp: 25,
                 totalXp: 200,
                 eventsCounted: 2,
               ),
             ),
           ),
         ),
       );
 
       expect(find.text('Activity'), findsOneWidget);
       expect(find.text('Consistency'), findsOneWidget);
       expect(find.text('Achievements'), findsOneWidget);
       expect(find.text('Quests'), findsOneWidget);
       expect(find.text('+25 XP'), findsOneWidget);
       expect(find.text('+60 XP'), findsOneWidget);
       expect(find.text('+40 XP'), findsOneWidget);
       expect(find.text('+75 XP'), findsOneWidget);
       // Top sources list the busiest activity types first.
       expect(find.text('Pull requests merged +50'), findsOneWidget);
       expect(find.text('Commits +10'), findsOneWidget);
      },
    );
  });

  group('buildProgressShareText', () {
    test('summarizes level, streak, achievements and quests locally', () {
      final intelligence = DeveloperIntelligenceEngine.compute(
        activities: [mergeActivity],
        contributions: const ContributionSummary(
          dailyCounts: {'2026-10-08': 1},
        ),
        now: now,
      );

      final text = buildProgressShareText(intelligence);

      expect(text, contains('LEVEL 2'));
      expect(text, contains('RISING DEVELOPER'));
      expect(text, contains('Current streak: 1 day'));
      expect(text, contains('Achievements: 2 / 15'));
      expect(text, contains('Quests completed: 1'));
      expect(text, isNot(contains('octocat')));
    });
  });

  group('colors', () {
    test('achievement accents stay theme-readable', () {
      // The mapping only returns theme-resolved accent getters.
      AppColors.configureForBrightness(Brightness.dark);
      final darkAccent = achievementAccent(AchievementCategory.consistency);
      AppColors.configureForBrightness(Brightness.light);
      final lightAccent = achievementAccent(AchievementCategory.consistency);

      expect(darkAccent, isNot(lightAccent));
    });
  });
}
