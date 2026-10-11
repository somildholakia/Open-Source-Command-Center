import 'package:flutter_test/flutter_test.dart';
import 'package:opensource_command_center/core/utils/email_validator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opensource_command_center/features/auth/data/models/user_model.dart';
import 'package:opensource_command_center/features/auth/presentation/bloc/auth.dart';
import 'package:opensource_command_center/services/firebase/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  group('shared email validation', () {
    test('accepts modern TLDs longer than four characters', () {
      expect(EmailValidator.isValid('dev@example.technology'), isTrue);
    });

    test('rejects malformed addresses', () {
      expect(EmailValidator.isValid('dev@'), isFalse);
      expect(EmailValidator.isValid('dev @example.com'), isFalse);
    });
  });

  group('AuthBloc', () {
    late MockAuthService mockAuthService;
    late AuthBloc authBloc;

    final testUser = UserModel(
      uid: 'test_uid_123',
      email: 'test@example.com',
      displayName: 'CodeMaster',
      createdAt: DateTime(2026, 1, 1),
    );

    setUp(() {
      mockAuthService = MockAuthService();
      authBloc = AuthBloc(authService: mockAuthService);
    });

    tearDown(() {
      authBloc.close();
    });

    test('initial state is AuthInitial', () {
      expect(authBloc.state, equals(const AuthInitial()));
    });

    group('AuthCheckRequested', () {
      test(
        'emits [AuthLoading, AuthUnauthenticated] when no user is signed in',
        () async {
          when(() => mockAuthService.currentUser).thenReturn(null);

          final expected = [const AuthLoading(), const AuthUnauthenticated()];
          expectLater(authBloc.stream, emitsInOrder(expected));

          authBloc.add(const AuthCheckRequested());
        },
      );

      test('emits [AuthLoading, AuthAuthenticated] when a user is already signed in', () async {
        when(() => mockAuthService.currentUser).thenReturn(testUser);

        final expected = [
          const AuthLoading(),
          AuthAuthenticated(user: testUser),
        ];
        expectLater(authBloc.stream, emitsInOrder(expected));

        authBloc.add(const AuthCheckRequested());
      });
    });

    group('AuthSignInRequested', () {
      test(
        'emits [AuthLoading, AuthAuthenticated] on valid credentials',
        () async {
          when(
            () => mockAuthService.signInWithEmailAndPassword(
              email: 'test@example.com',
              password: 'password123',
            ),
          ).thenAnswer((_) async => testUser);

          expectLater(
            authBloc.stream,
            emitsInOrder([
              const AuthLoading(),
              AuthAuthenticated(user: testUser),
            ]),
          );

          authBloc.add(
            const AuthSignInRequested(
              email: 'test@example.com',
              password: 'password123',
            ),
          );
        },
      );

      test(
        'emits [AuthError] immediately on empty email without calling service',
        () async {
          expectLater(
            authBloc.stream,
            emitsInOrder([
              isA<AuthError>().having(
                (e) => e.type,
                'type',
                AuthErrorType.invalidEmail,
              ),
            ]),
          );

          authBloc.add(
            const AuthSignInRequested(email: '', password: 'password123'),
          );
          verifyNever(
            () => mockAuthService.signInWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          );
        },
      );

      test('emits [AuthError] on invalid email format', () async {
        expectLater(
          authBloc.stream,
          emitsInOrder([
            isA<AuthError>().having(
              (e) => e.type,
              'type',
              AuthErrorType.invalidEmail,
            ),
          ]),
        );

        authBloc.add(
          const AuthSignInRequested(
            email: 'invalid-email',
            password: 'password123',
          ),
        );
      });

      test('emits [AuthError] on password shorter than 6 chars', () async {
        expectLater(
          authBloc.stream,
          emitsInOrder([
            isA<AuthError>().having(
              (e) => e.type,
              'type',
              AuthErrorType.weakPassword,
            ),
          ]),
        );

        authBloc.add(
          const AuthSignInRequested(email: 'test@example.com', password: '123'),
        );
      });

      test(
        'emits [AuthLoading, AuthError] when service throws AuthFailure',
        () async {
          when(
            () => mockAuthService.signInWithEmailAndPassword(
              email: 'wrong@example.com',
              password: 'password123',
            ),
          ).thenThrow(
            const AuthFailure(
              type: AuthErrorType.wrongPassword,
              message: 'Invalid email or password.',
            ),
          );

          expectLater(
            authBloc.stream,
            emitsInOrder([
              const AuthLoading(),
              const AuthError(
                message: 'Invalid email or password.',
                type: AuthErrorType.wrongPassword,
              ),
            ]),
          );

          authBloc.add(
            const AuthSignInRequested(
              email: 'wrong@example.com',
              password: 'password123',
            ),
          );
        },
      );
    });

    group('AuthSignUpRequested', () {
      test(
        'emits [AuthLoading, AuthAuthenticated] on valid registration',
        () async {
          when(
            () => mockAuthService.signUpWithEmailAndPassword(
              email: 'newdev@example.com',
              password: 'strongPassword99!',
              displayName: 'CodeMaster',
            ),
          ).thenAnswer((_) async => testUser);

          expectLater(
            authBloc.stream,
            emitsInOrder([
              const AuthLoading(),
              AuthAuthenticated(user: testUser),
            ]),
          );

          authBloc.add(
            const AuthSignUpRequested(
              email: 'newdev@example.com',
              password: 'strongPassword99!',
              displayName: 'CodeMaster',
            ),
          );
        },
      );

      test('emits [AuthError] on password shorter than 8 chars', () async {
        expectLater(
          authBloc.stream,
          emitsInOrder([
            isA<AuthError>().having(
              (e) => e.type,
              'type',
              AuthErrorType.weakPassword,
            ),
          ]),
        );

        authBloc.add(
          const AuthSignUpRequested(
            email: 'newdev@example.com',
            password: 'short',
          ),
        );
      });

      test('emits [AuthError] on common weak password', () async {
        expectLater(
          authBloc.stream,
          emitsInOrder([
            isA<AuthError>().having(
              (e) => e.type,
              'type',
              AuthErrorType.weakPassword,
            ),
          ]),
        );

        authBloc.add(
          const AuthSignUpRequested(
            email: 'newdev@example.com',
            password: 'password123',
          ),
        );
      });

      test(
        'emits [AuthLoading, AuthError] when email is already in use',
        () async {
          when(
            () => mockAuthService.signUpWithEmailAndPassword(
              email: 'existing@example.com',
              password: 'strongPassword99!',
              displayName: any(named: 'displayName'),
            ),
          ).thenThrow(
            const AuthFailure(
              type: AuthErrorType.emailAlreadyInUse,
              message: 'An account already exists for this email address.',
            ),
          );

          expectLater(
            authBloc.stream,
            emitsInOrder([
              const AuthLoading(),
              const AuthError(
                message: 'An account already exists for this email address.',
                type: AuthErrorType.emailAlreadyInUse,
              ),
            ]),
          );

          authBloc.add(
            const AuthSignUpRequested(
              email: 'existing@example.com',
              password: 'strongPassword99!',
            ),
          );
        },
      );
    });

    group('AuthSignOutRequested', () {
      test('emits [AuthLoading, AuthUnauthenticated] on sign out', () async {
        when(() => mockAuthService.signOut()).thenAnswer((_) async {});

        expectLater(
          authBloc.stream,
          emitsInOrder([const AuthLoading(), const AuthUnauthenticated()]),
        );

        authBloc.add(const AuthSignOutRequested());
      });
    });

    group('AuthPasswordResetRequested', () {
      test('reports success only after the reset service succeeds', () async {
        when(() => mockAuthService.sendPasswordResetEmail('dev@example.com'))
            .thenAnswer((_) async => true);

        authBloc.add(
          const AuthPasswordResetRequested(email: 'dev@example.com'),
        );
        await pumpEventQueue();

        verify(() => mockAuthService.sendPasswordResetEmail('dev@example.com'))
            .called(1);
        expect(
          authBloc.state,
          isA<AuthPasswordResetResult>().having(
            (state) => state.success,
            'success',
            isTrue,
          ),
        );
      });

      test(
        'reports failure when the reset service cannot send email',
        () async {
          when(() => mockAuthService.sendPasswordResetEmail('dev@example.com'))
              .thenAnswer((_) async => false);

          authBloc.add(
            const AuthPasswordResetRequested(email: 'dev@example.com'),
          );
          await pumpEventQueue();

          expect(
            authBloc.state,
            isA<AuthPasswordResetResult>().having(
              (state) => state.success,
              'success',
              isFalse,
            ),
          );
        },
      );

      test('emits AuthError when email is invalid', () async {
        expectLater(
          authBloc.stream,
          emitsInOrder([
            isA<AuthError>().having(
              (e) => e.type,
              'type',
              AuthErrorType.invalidEmail,
            ),
          ]),
        );

        authBloc.add(const AuthPasswordResetRequested(email: 'notanemail'));
      });
    });
  });
}
