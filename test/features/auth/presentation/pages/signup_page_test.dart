import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opensource_command_center/core/theme/app_theme.dart';
import 'package:opensource_command_center/features/auth/presentation/bloc/auth.dart';
import 'package:opensource_command_center/features/auth/presentation/pages/signup_page.dart';
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
      home: BlocProvider<AuthBloc>.value(
        value: bloc,
        child: const SignUpPage(),
      ),
    );
  }

  group('SignUpPage UI Tests', () {
    testWidgets('renders all essential signup elements', (
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
      expect(find.text('Create New Agent'), findsOneWidget);
      expect(
        find.text('Join the ranks of open source contributors'),
        findsOneWidget,
      );

      // Form fields
      expect(find.text('Developer Handle'), findsOneWidget);
      expect(find.text('Email Address *'), findsOneWidget);
      expect(find.text('Password *'), findsOneWidget);
      expect(find.text('Confirm Password *'), findsOneWidget);

      // Checkbox and buttons
      expect(
        find.text('I accept the Terms of Service & Privacy Policy'),
        findsOneWidget,
      );
      expect(find.text('Initialize New Agent'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('requires terms acceptance before form validation', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pumpAndSettle();

      // Tap submit without checking terms
      await tester.tap(find.text('Initialize New Agent'));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Please accept the Terms of Service to continue'),
        findsOneWidget,
      );
    });

    testWidgets('shows password mismatch error', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pumpAndSettle();

      // Accept terms by tapping the Checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.pump();

      // Fill in fields — name at 0, email at 1, password at 2, confirm at 3
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'test@example.com',
      );
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.pump();
      await tester.enterText(
        find.byType(TextFormField).at(3),
        'differentpassword',
      );
      await tester.pump();

      await tester.tap(find.text('Initialize New Agent'));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });
}
