import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opensource_command_center/app.dart';
import 'package:opensource_command_center/features/auth/data/models/user_model.dart';
import 'package:opensource_command_center/services/firebase/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

/// Waits for the Login page to appear by pumping frames incrementally.
Future<void> pumpUntilLoginPage(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.text('Login to Terminal').evaluate().isNotEmpty) {
      break;
    }
  }
}

/// Waits for the Home/Dashboard page to appear after login.
Future<void> pumpUntilHomePage(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.text('Hello, Developer!').evaluate().isNotEmpty) {
      break;
    }
  }
}

void main() {
  late MockAuthService mockAuthService;

  final testUser = UserModel(
    uid: 'test_dev_uid',
    email: 'developer@example.com',
    displayName: 'Developer',
    createdAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    mockAuthService = MockAuthService();
    // Default to unauthenticated on startup
    when(() => mockAuthService.currentUser).thenReturn(null);
    when(
      () => mockAuthService.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => testUser);
    when(() => mockAuthService.signOut()).thenAnswer((_) async {});
  });

  testWidgets('App launches on Splash and transitions to Login screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(App(authService: mockAuthService));
    await pumpUntilLoginPage(tester);

    // Verify Login screen is shown after splash
    expect(find.text('Login to Terminal'), findsOneWidget);
    expect(find.text('Initialize Session'), findsOneWidget);
  });

  testWidgets('App logs in and renders Home on phone screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(App(authService: mockAuthService));
    await pumpUntilLoginPage(tester);

    // Enter login credentials (first TextFormField = email, last = password)
    await tester.enterText(
      find.byType(TextFormField).first,
      'developer@example.com',
    );
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.pump();

    // Tap Login button
    await tester.tap(find.text('Initialize Session'));
    await pumpUntilHomePage(tester);

    // Verify home screen greeting
    expect(find.text('Hello, Developer!'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Contributions'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('App navigates across tabs seamlessly on mobile after login', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(App(authService: mockAuthService));
    await pumpUntilLoginPage(tester);

    // Log in first
    await tester.enterText(
      find.byType(TextFormField).first,
      'developer@example.com',
    );
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.pump();

    // ensure visible before tap
    await tester.ensureVisible(find.text('Initialize Session'));
    await tester.tap(find.text('Initialize Session'));
    await pumpUntilHomePage(tester);

    // Tap Activity tab
    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();
    expect(find.text('Activity Timeline'), findsOneWidget);

    // Tap Contributions tab
    await tester.tap(find.text('Contributions'));
    await tester.pumpAndSettle();
    expect(find.text('Contribution Analytics'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);

    // Tap Progress tab
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    // No GitHub connection: the Progress screen shows the connect CTA
    // instead of any (possibly fake) progression.
    expect(find.text('CONNECT GITHUB'), findsOneWidget);
    expect(find.text('Level 2'), findsNothing);

    // Tap Profile tab
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Developer'), findsOneWidget);
    expect(find.text('developer@example.com'), findsOneWidget);

    // Tap Home tab back
    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    expect(find.text('Hello, Developer!'), findsOneWidget);
  });

  testWidgets('App remains usable at a compact 320dp phone width', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(640, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(App(authService: mockAuthService));
    await pumpUntilLoginPage(tester);

    await tester.enterText(
      find.byType(TextFormField).first,
      'developer@example.com',
    );
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.pump();
    await tester.ensureVisible(find.text('Initialize Session'));
    await tester.tap(find.text('Initialize Session'));
    await pumpUntilHomePage(tester);

    expect(find.text('Hello, Developer!'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'compact login and home');

    for (final tab in ['Activity', 'Contributions', 'Progress', 'Profile', 'Home']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'compact $tab layout');
    }
  });

  testWidgets(
    'App renders side navigation rail on tablet / desktop screen after login',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2048, 1536);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(App(authService: mockAuthService));
      await pumpUntilLoginPage(tester);

      // Log in
      await tester.enterText(
        find.byType(TextFormField).first,
        'developer@example.com',
      );
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.pump();
      await tester.ensureVisible(find.text('Initialize Session'));
      await tester.tap(find.text('Initialize Session'));
      await pumpUntilHomePage(tester);

      // Verify Home screen on tablet
      expect(find.text('Hello, Developer!'), findsOneWidget);
      // SideNavRail renders a mini brand terminal icon on tablet/desktop.
      expect(find.byIcon(Icons.terminal_rounded), findsWidgets);

      // Navigate to Contributions tab via SideNavRail
      await tester.tap(find.text('Contributions'));
      await tester.pumpAndSettle();
      expect(find.text('Contribution Analytics'), findsOneWidget);
      expect(find.text('Pull Requests'), findsOneWidget);
    },
  );
}
