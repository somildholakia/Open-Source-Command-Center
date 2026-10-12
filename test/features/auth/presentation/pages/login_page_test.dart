import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opensource_command_center/core/theme/app_theme.dart';
import 'package:opensource_command_center/features/auth/presentation/bloc/auth.dart';
import 'package:opensource_command_center/features/auth/presentation/pages/login_page.dart';
import 'package:opensource_command_center/services/firebase/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
    when(() => mockAuthService.currentUser).thenReturn(null);
  });

  Widget createWidgetUnderTest({AuthBloc? authBloc}) {
    final bloc = authBloc ?? AuthBloc(authService: mockAuthService);
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: BlocProvider<AuthBloc>.value(value: bloc, child: const LoginPage()),
    );
  }

  group('LoginPage UI Tests', () {
    testWidgets('offers a local preview when Firebase is not configured', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Preview app (local demo)'), findsOneWidget);
      expect(find.textContaining('Debug preview only'), findsOneWidget);
    });

    testWidgets('renders all essential login elements', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Login to Terminal'), findsOneWidget);
      expect(find.text('Connect to continue your journey'), findsOneWidget);

      // Form fields
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      // Buttons & Links
      expect(find.text('Initialize Session'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('shows validation error when fields are empty on submit', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pumpAndSettle();

      // Tap submit without typing
      await tester.tap(find.text('Initialize Session'));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid email format', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pumpAndSettle();

      // Enter invalid email
      await tester.enterText(find.byType(TextFormField).first, 'notanemail');
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).last, 'validpass123');
      await tester.pump();

      await tester.tap(find.text('Initialize Session'));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('toggles password visibility on eye icon tap', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pumpAndSettle();

      // There should be one visibility_off icon (the password suffix icon)
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });
  });
}
