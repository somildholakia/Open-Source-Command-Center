import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opensource_command_center/core/theme/app_theme.dart';
import 'package:opensource_command_center/features/profile/presentation/widgets/profile_section_card.dart';

void main() {
  group('ProfileSectionCard', () {
    testWidgets('renders icon, title, subtitle, and chevron', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ProfileSectionCard(
            icon: Icons.link_rounded,
            title: 'Connected Accounts',
            subtitle: 'No accounts connected',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Connected Accounts'), findsOneWidget);
      expect(find.text('No accounts connected'), findsOneWidget);
      expect(find.byIcon(Icons.link_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });

    testWidgets('onTap does not navigate (presentation-only)', (
      WidgetTester tester,
    ) async {
      // Tap the card — it should not throw or navigate.
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ProfileSectionCard(
            icon: Icons.settings_rounded,
            title: 'Settings',
            subtitle: 'Preferences and configuration',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pump();

      // Still on the same page — no navigation occurred.
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
