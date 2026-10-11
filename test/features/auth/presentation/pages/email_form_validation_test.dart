import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opensource_command_center/features/auth/presentation/bloc/auth.dart';
import 'package:opensource_command_center/features/auth/presentation/pages/login_page.dart';
import 'package:opensource_command_center/features/auth/presentation/pages/signup_page.dart';
import 'package:opensource_command_center/services/firebase/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late AuthBloc authBloc;

  setUp(() {
    authBloc = AuthBloc(authService: MockAuthService());
  });

  tearDown(() async {
    await authBloc.close();
  });

  testWidgets('login accepts modern long top-level domains', (tester) async {
    await tester.pumpWidget(
      BlocProvider.value(
        value: authBloc,
        child: const MaterialApp(home: LoginPage()),
      ),
    );

    await tester.enterText(
      find.byType(TextFormField).first,
      'developer@example.technology',
    );
    await tester.tap(find.text('Initialize Session'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a valid email address'), findsNothing);
    expect(find.text('Please enter your password'), findsOneWidget);
  });

  testWidgets('sign-up accepts modern long top-level domains', (tester) async {
    await tester.pumpWidget(
      BlocProvider.value(
        value: authBloc,
        child: const MaterialApp(home: SignUpPage()),
      ),
    );

    await tester.enterText(
      find.byType(TextFormField).at(1),
      'developer@example.technology',
    );
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Initialize New Agent'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a valid email address'), findsNothing);
    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
  });
}
