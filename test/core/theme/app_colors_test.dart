import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opensource_command_center/core/theme/app_colors.dart';

void main() {
  group('AppColors resolved tokens', () {
    test('dark tokens match the original dark palette', () {
      AppColors.configureForBrightness(Brightness.dark);

      expect(AppColors.background, AppColors.backgroundDark);
      expect(AppColors.surface, AppColors.surfaceDark);
      expect(AppColors.surfaceElevated, AppColors.surfaceElevatedDark);
      expect(AppColors.border, AppColors.borderDark);
      expect(AppColors.borderStrong, AppColors.borderStrongDark);
      expect(AppColors.textPrimary, AppColors.textOnDark);
      expect(AppColors.textSecondary, AppColors.textSecondaryOnDark);
      expect(AppColors.textTertiary, AppColors.textSubtleOnDark);
      // Accents stay vibrant on dark backgrounds
      expect(AppColors.primaryAccent, AppColors.primary);
      expect(AppColors.secondaryAccent, AppColors.secondary);
      expect(AppColors.accentPink, AppColors.accent);
      expect(AppColors.streakAccent, AppColors.streak);
      expect(AppColors.achievementAccent, AppColors.achievement);
      expect(AppColors.successAccent, AppColors.success);
      expect(AppColors.warningAccent, AppColors.warning);
      expect(AppColors.errorAccent, AppColors.error);
      expect(AppColors.infoAccent, AppColors.info);
      expect(AppColors.pullRequestAccent, AppColors.pullRequest);
      expect(AppColors.issueAccent, AppColors.issue);
      expect(AppColors.commitAccent, AppColors.commit);
      expect(AppColors.reviewAccent, AppColors.review);
      expect(AppColors.mergedAccent, AppColors.merged);
      expect(AppColors.closedAccent, AppColors.closed);
    });

    test('light tokens resolve to the light palette', () {
      AppColors.configureForBrightness(Brightness.light);

      expect(AppColors.background, AppColors.backgroundLight);
      expect(AppColors.surface, AppColors.surfaceLight);
      expect(AppColors.surfaceElevated, AppColors.surfaceElevatedLight);
      expect(AppColors.border, AppColors.borderLight);
      expect(AppColors.borderStrong, AppColors.borderStrongLight);
      expect(AppColors.textPrimary, AppColors.textOnLight);
      expect(AppColors.textTertiary, AppColors.textSubtleOnLight);
    });

    test('light accent tokens are deepened for readability', () {
      AppColors.configureForBrightness(Brightness.light);

      // Text/icon accents must differ from their vibrant dark variants.
      expect(AppColors.primaryAccent, isNot(AppColors.primary));
      expect(AppColors.primaryAccent, AppColors.primaryDeep);
      expect(AppColors.secondaryAccent, AppColors.secondaryDark);
      expect(AppColors.accentPink, AppColors.accentDark);
      expect(AppColors.accentGreenAccent, AppColors.accentGreenDark);
      expect(AppColors.accentOrangeAccent, AppColors.accentOrangeDark);
      expect(AppColors.successAccent, AppColors.successDark);
      expect(AppColors.warningAccent, AppColors.warningDark);
      expect(AppColors.errorAccent, AppColors.errorDark);
      expect(AppColors.infoAccent, AppColors.infoDark);
      expect(AppColors.streakAccent, AppColors.streakDark);
      expect(AppColors.achievementAccent, AppColors.achievementDark);
      expect(AppColors.questAccent, AppColors.primaryDeep);
      expect(AppColors.pullRequestAccent, AppColors.pullRequestDark);
      expect(AppColors.issueAccent, AppColors.issueDark);
      expect(AppColors.commitAccent, AppColors.commitDark);
      expect(AppColors.reviewAccent, AppColors.reviewDark);
      expect(AppColors.mergedAccent, AppColors.mergedDark);
      expect(AppColors.closedAccent, AppColors.closedDark);
    });

    test('light accents meet 4.5:1 contrast on light surfaces', () {
      AppColors.configureForBrightness(Brightness.light);

      for (final accent in [
        AppColors.primaryAccent,
        AppColors.secondaryAccent,
        AppColors.accentPink,
        AppColors.accentGreenAccent,
        AppColors.accentOrangeAccent,
        AppColors.successAccent,
        AppColors.warningAccent,
        AppColors.errorAccent,
        AppColors.infoAccent,
        AppColors.streakAccent,
        AppColors.achievementAccent,
        AppColors.pullRequestAccent,
        AppColors.issueAccent,
        AppColors.commitAccent,
        AppColors.reviewAccent,
        AppColors.mergedAccent,
        AppColors.closedAccent,
      ]) {
        expect(
          AppColors.hasSufficientContrast(accent, AppColors.surfaceLight),
          isTrue,
          reason:
              '${accent.toARGB32().toRadixString(16)} fails contrast '
              'on light surface',
        );
      }
    });

    test('explicit-Brightness resolvers match resolved tokens', () {
      AppColors.configureForBrightness(Brightness.dark);

      expect(
        AppColors.backgroundFor(Brightness.light),
        AppColors.backgroundLight,
      );
      expect(
        AppColors.backgroundFor(Brightness.dark),
        AppColors.backgroundDark,
      );
      expect(AppColors.surfaceFor(Brightness.light), AppColors.surfaceLight);
      expect(
        AppColors.surfaceElevatedFor(Brightness.dark),
        AppColors.surfaceElevatedDark,
      );
      expect(
        AppColors.textSubtleFor(Brightness.light),
        AppColors.textSubtleOnLight,
      );
    });
  });
}
