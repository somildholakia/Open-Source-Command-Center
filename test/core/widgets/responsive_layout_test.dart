import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opensource_command_center/core/theme/app_theme.dart';
import 'package:opensource_command_center/core/widgets/responsive_layout.dart';

void main() {
  group('ResponsiveBuilder', () {
    testWidgets('passes correct screenType based on constraints', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 600,
              child: ResponsiveBuilder(
                builder: (context, screenType, constraints) {
                  return Text('Type: ${screenType.name}');
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Type: compact'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SizedBox(
              width: 768,
              height: 1024,
              child: ResponsiveBuilder(
                builder: (context, screenType, constraints) {
                  return Text('Type: ${screenType.name}');
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Type: tablet'), findsOneWidget);
    });
  });

  group('ResponsiveLayout', () {
    testWidgets('renders mobile widget by default on narrow screens', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: SizedBox(
              width: 400,
              height: 800,
              child: ResponsiveLayout(
                mobile: Text('Mobile Layout'),
                tablet: Text('Tablet Layout'),
                desktop: Text('Desktop Layout'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Mobile Layout'), findsOneWidget);
      expect(find.text('Tablet Layout'), findsNothing);
      expect(find.text('Desktop Layout'), findsNothing);
    });

    testWidgets('renders tablet widget on tablet-width screens', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: SizedBox(
              width: 700,
              height: 1000,
              child: ResponsiveLayout(
                mobile: Text('Mobile Layout'),
                tablet: Text('Tablet Layout'),
                desktop: Text('Desktop Layout'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Tablet Layout'), findsOneWidget);
      expect(find.text('Mobile Layout'), findsNothing);
    });

    testWidgets('renders desktop widget on wide screens', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(2400, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: ResponsiveLayout(
              mobile: Text('Mobile Layout'),
              tablet: Text('Tablet Layout'),
              desktop: Text('Desktop Layout'),
            ),
          ),
        ),
      );

      expect(find.text('Desktop Layout'), findsOneWidget);
    });

    testWidgets('falls back to mobile when tablet is not provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: SizedBox(
              width: 700,
              height: 1000,
              child: ResponsiveLayout(mobile: Text('Fallback Mobile Layout')),
            ),
          ),
        ),
      );

      expect(find.text('Fallback Mobile Layout'), findsOneWidget);
    });
  });

  group('ResponsiveContainer', () {
    testWidgets('centers content and applies max width constraints', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: ResponsiveContainer(
              maxWidth: 500,
              child: Text('Constrained Content'),
            ),
          ),
        ),
      );

      expect(find.text('Constrained Content'), findsOneWidget);

      final constrainedBox = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(ResponsiveContainer),
          matching: find.byType(ConstrainedBox),
        ),
      );

      expect(constrainedBox.constraints.maxWidth, 500);
    });
  });

  group('ResponsiveRowColumn', () {
    testWidgets('renders Column on mobile widths', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: SizedBox(
              width: 400,
              height: 800,
              child: ResponsiveRowColumn(
                children: [Text('Item 1'), Text('Item 2')],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Column), findsWidgets);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('renders Row on tablet widths', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: ResponsiveRowColumn(
                children: [Text('Item 1'), Text('Item 2')],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Row), findsWidgets);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });
  });

  group('ResponsiveGrid', () {
    testWidgets('renders grid items with appropriate column count', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: ResponsiveGrid(
                mobileColumns: 2,
                tabletColumns: 4,
                children: const [
                  Text('Card 1'),
                  Text('Card 2'),
                  Text('Card 3'),
                  Text('Card 4'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Card 1'), findsOneWidget);
      expect(find.text('Card 4'), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
    });
  });
}
