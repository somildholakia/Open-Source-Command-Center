import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opensource_command_center/services/firebase/auth_service.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  late _MockFirebaseAuth firebaseAuth;
  late AuthService authService;

  setUp(() {
    firebaseAuth = _MockFirebaseAuth();
    authService = AuthService.custom(auth: firebaseAuth);
  });

  group('unexpected authentication failures', () {
    test('sign-in errors do not expose internal exception text', () async {
      when(
        () => firebaseAuth.signInWithEmailAndPassword(
          email: 'dev@example.com',
          password: 'password123',
        ),
      ).thenThrow(Exception('private internal details'));

      await expectLater(
        authService.signInWithEmailAndPassword(
          email: 'dev@example.com',
          password: 'password123',
        ),
        throwsA(
          isA<AuthFailure>().having(
            (failure) => failure.message,
            'message',
            'Sign-in failed. Please try again.',
          ),
        ),
      );
    });

    test('sign-up errors do not expose internal exception text', () async {
      when(
        () => firebaseAuth.createUserWithEmailAndPassword(
          email: 'dev@example.com',
          password: 'strongPassword99!',
        ),
      ).thenThrow(Exception('private internal details'));

      await expectLater(
        authService.signUpWithEmailAndPassword(
          email: 'dev@example.com',
          password: 'strongPassword99!',
        ),
        throwsA(
          isA<AuthFailure>().having(
            (failure) => failure.message,
            'message',
            'Sign-up failed. Please try again.',
          ),
        ),
      );
    });

    test('unknown Firebase errors use a generic user-facing message', () async {
      when(
        () => firebaseAuth.signInWithEmailAndPassword(
          email: 'dev@example.com',
          password: 'password123',
        ),
      ).thenThrow(
        FirebaseAuthException(
          code: 'internal-error',
          message: 'private Firebase diagnostic details',
        ),
      );

      await expectLater(
        authService.signInWithEmailAndPassword(
          email: 'dev@example.com',
          password: 'password123',
        ),
        throwsA(
          isA<AuthFailure>().having(
            (failure) => failure.message,
            'message',
            'Authentication failed. Please try again.',
          ),
        ),
      );
    });
  });
}
