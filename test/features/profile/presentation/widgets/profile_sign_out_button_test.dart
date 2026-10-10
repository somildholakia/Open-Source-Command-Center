import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opensource_command_center/core/theme/app_theme.dart';
import 'package:opensource_command_center/features/auth/presentation/bloc/auth.dart';
import 'package:opensource_command_center/features/profile/presentation/widgets/profile_sign_out_button.dart';
import 'package:opensource_command_center/services/firebase/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  group('ProfileSignOutButton', () {
    testWidgets('dispatches AuthSignOutRequested on tap', (
      WidgetTester tester,
    ) async {
      final mockAuthService = MockAuthService();
      when(() => mockAuthService.signOut()).thenAnswer((_) async {});

      final authBloc = AuthBloc(authService: mockAuthService);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: const Scaffold(body: ProfileSignOutButton()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign Out'));
      await tester.pump();

      verify(() => mockAuthService.signOut()).called(1);

      authBloc.close();
    });
  });
}
