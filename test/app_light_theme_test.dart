import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opensource_command_center/app.dart';
import 'package:opensource_command_center/core/theme/app_colors.dart';
import 'package:opensource_command_center/core/theme/theme_preference.dart';
import 'package:opensource_command_center/features/auth/data/models/user_model.dart';
import 'package:opensource_command_center/services/firebase/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

void main() {
  late MockAuthService mockAuthService;

  final testUser = UserModel(
    uid: 'light_mode_uid',
    email: 'light@example.com',
    displayName: 'Light Dev',
  );

  setUp(() {
    // ThemePreference persists via shared_preferences; mock the platform
    // channel so getInstance() resolves in the test environment.
    SharedPreferences.setMockInitialValues({});
    mockAuthService = MockAuthService();
    // Start unauthenticated so the app shows the login screen; the mocked
    // sign-in then returns the test user (mirrors widget_test.dart).
    when(() => mockAuthService.currentUser).thenReturn(null);
    when(
      () => mockAuthService.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => testUser);
    when(() => mockAuthService.signOut()).thenAnswer((_) async {});
  });

  Future<void> pumpAuthenticatedAppInLightMode(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(App(authService: mockAuthService));
    await pumpUntilLoginPage(tester);

    // Log in through the real auth flow
    await tester.enterText(
      find.byType(TextFormField).first,
      'light@example.com',
    );
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.pump();
    await tester.ensureVisible(find.text('Initialize Session'));
    await tester.tap(find.text('Initialize Session'));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('Hello, Light Dev!').evaluate().isNotEmpty) break;
    }

    // Switch the whole app to light mode (same path the settings UI uses)
    await ThemePreference.setThemeMode(ThemeMode.light);
    await tester.pumpAndSettle();
  }

  testWidgets('light theme renders key screens with light backgrounds', (
    tester,
  ) async {
    await pumpAuthenticatedAppInLightMode(tester);

    // App is now in light mode: scaffold and card surfaces are light
    final context = tester.element(find.byType(Navigator).first);
    final theme = Theme.of(context);
    expect(theme.brightness, Brightness.light);
    expect(AppColors.background, AppColors.backgroundLight);

    // Dashboard renders with theme-resolved text
    expect(find.text('Hello, Light Dev!'), findsOneWidget);
    expect(find.text('TELEMETRY SNAPSHOT'), findsOneWidget);

    // Navigate through the main tabs in light mode
    await tester.tap(find.text('Activity').last);
    await tester.pumpAndSettle();
    expect(find.text('Activity Timeline'), findsOneWidget);

    await tester.tap(find.text('Contributions').last);
    await tester.pumpAndSettle();
    expect(find.text('Contribution Analytics'), findsOneWidget);
    expect(find.text('SAMPLE DATA'), findsWidgets);

    await tester.tap(find.text('Progress').last);
    await tester.pumpAndSettle();
    // No GitHub connection: the Progress screen shows the connect CTA
    // instead of any (possibly fake) progression.
    expect(find.text('CONNECT GITHUB'), findsOneWidget);

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.text('light@example.com'), findsOneWidget);
  });

  testWidgets('settings renders and signs out to login in light mode', (
    tester,
  ) async {
    await pumpAuthenticatedAppInLightMode(tester);

    // Open Settings from Profile
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);

    // Theme dropdown still shows Light
    expect(find.text('Light'), findsWidgets);

    // Sign out from Settings returns to the login route
    await tester.ensureVisible(find.text('Sign Out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();

    expect(find.text('Login to Terminal'), findsOneWidget);
  });
}
