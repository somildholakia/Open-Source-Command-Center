import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opensource_command_center/core/theme/app_colors.dart';
import 'package:opensource_command_center/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    testWidgets('dark theme uses the dark navy scaffold background', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.darkTheme, home: const Scaffold()),
      );

      expect(
        AppTheme.darkTheme.scaffoldBackgroundColor,
        AppColors.backgroundDark,
      );
      expect(AppTheme.darkTheme.colorScheme.brightness, Brightness.dark);
    });

    testWidgets('light theme uses the light scaffold background', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const Scaffold()),
      );

      expect(
        AppTheme.lightTheme.scaffoldBackgroundColor,
        AppColors.backgroundLight,
      );
      expect(AppTheme.lightTheme.colorScheme.brightness, Brightness.light);
    });

    testWidgets('dark theme keeps the original surface and outline values', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.darkTheme, home: const Scaffold()),
      );
      final scheme = AppTheme.darkTheme.colorScheme;

      expect(scheme.surface, AppColors.surfaceDark);
      expect(scheme.outline, AppColors.borderDark);
      expect(scheme.outlineVariant, AppColors.borderStrongDark);
      expect(scheme.primary, AppColors.primary);
      expect(scheme.secondary, AppColors.secondary);
      expect(scheme.tertiary, AppColors.accent);
      expect(scheme.error, AppColors.error);
    });

    testWidgets('light theme deepens primary, secondary and error', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const Scaffold()),
      );
      final scheme = AppTheme.lightTheme.colorScheme;

      expect(scheme.primary, AppColors.primaryDeep);
      expect(scheme.secondary, AppColors.secondaryDark);
      expect(scheme.tertiary, AppColors.accentDark);
      expect(scheme.error, AppColors.errorDark);
      expect(scheme.surface, AppColors.surfaceLight);
      expect(scheme.onSurface, AppColors.textOnLight);
    });

    test('resolved color tokens follow the configured brightness', () {
      // Pure token-resolution check: no ThemeData (and therefore no
      // google_fonts network loading) is involved.
      AppColors.configureForBrightness(Brightness.dark);
      expect(AppColors.brightness, Brightness.dark);
      expect(AppColors.surface, AppColors.surfaceDark);

      AppColors.configureForBrightness(Brightness.light);
      expect(AppColors.brightness, Brightness.light);
      expect(AppColors.surface, AppColors.surfaceLight);

      // Restore dark so unrelated tests start from the app default.
      AppColors.configureForBrightness(Brightness.dark);
      expect(AppColors.brightness, Brightness.dark);
    });

    testWidgets('light theme renders widgets with readable onSurface text', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const Scaffold()),
      );
      final context = tester.element(find.byType(Scaffold));

      final style = Theme.of(context).textTheme.titleLarge!;
      expect(style.color, AppColors.textOnLight);
    });

    testWidgets('component themes stay readable in light mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const Scaffold()),
      );
      final context = tester.element(find.byType(Scaffold));
      final theme = Theme.of(context);

      // Inputs are filled and readable on light surfaces
      expect(theme.inputDecorationTheme.fillColor, isNotNull);
      // Divider and outline exist for light borders
      expect(theme.dividerTheme.color, isNotNull);
      // Snackbars invert against the light scaffold
      expect(
        theme.snackBarTheme.backgroundColor,
        theme.colorScheme.inverseSurface,
      );
    });
  });
}
