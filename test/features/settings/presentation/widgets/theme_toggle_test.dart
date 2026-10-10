import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opensource_command_center/core/theme/app_theme.dart';
import 'package:opensource_command_center/core/theme/theme_preference.dart';
import 'package:opensource_command_center/features/settings/presentation/widgets/theme_toggle.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ThemePreference.notifier.value = ThemeMode.dark;
  });

  testWidgets('ThemeToggle renders with default Dark mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(body: ThemeToggle()),
      ),
    );
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Dark'), findsAtLeastNWidgets(1));
  });

  testWidgets('ThemeToggle shows popup menu on tap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(body: ThemeToggle()),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the dropdown trigger (the Container with Dark label)
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();

    // Verify all three options appear in the popup
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
  });

  testWidgets('Selecting Light updates notifier and persists', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(body: ThemeToggle()),
      ),
    );
    await tester.pumpAndSettle();

    // Open popup
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();

    // Select Light
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();

    // Verify notifier updated
    expect(ThemePreference.notifier.value, ThemeMode.light);

    // Verify persistence
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'light');
  });

  testWidgets('Selecting System updates notifier and persists', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(body: ThemeToggle()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();

    expect(ThemePreference.notifier.value, ThemeMode.system);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'system');
  });

  testWidgets('Selecting Dark updates notifier and persists', (tester) async {
    // Start with Light
    ThemePreference.notifier.value = ThemeMode.light;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(body: ThemeToggle()),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the PopupMenuButton icon (the dropdown arrow)
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pumpAndSettle();

    // Tap "Dark" inside the popup menu (the last one in the tree)
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();

    expect(ThemePreference.notifier.value, ThemeMode.dark);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'dark');
  });
}
