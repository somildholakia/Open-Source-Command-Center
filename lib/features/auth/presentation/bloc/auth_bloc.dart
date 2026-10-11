import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/email_validator.dart';
import '../../../../services/firebase/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC for managing authentication state.
///
/// Handles authentication events and emits appropriate states.
/// Backed by [AuthService] for real Firebase Authentication.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc({AuthService? authService})
    : _authService = authService ?? AuthService.instance,
      super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignInRequested>(_onAuthSignInRequested);
    on<AuthSignUpRequested>(_onAuthSignUpRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
    on<AuthPasswordResetRequested>(_onAuthPasswordResetRequested);
  }

  /// Check for existing authenticated session via [AuthService.currentUser].
  ///
  /// Firebase Auth natively persists the signed-in user across app launches.
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final user = _authService.currentUser;
    if (user != null && user.isAuthenticated) {
      emit(AuthAuthenticated(user: user));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  /// Handle sign in request with email/password.
  Future<void> _onAuthSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    // 1. Client-side validations
    if (event.email.isEmpty || event.password.isEmpty) {
      emit(
        const AuthError(
          message: 'Please enter both email and password',
          type: AuthErrorType.invalidEmail,
        ),
      );
      return;
    }

    if (!EmailValidator.isValid(event.email)) {
      emit(
        const AuthError(
          message: 'Please enter a valid email address',
          type: AuthErrorType.invalidEmail,
        ),
      );
      return;
    }

    if (event.password.length < 6) {
      emit(
        const AuthError(
          message: 'Password must be at least 6 characters',
          type: AuthErrorType.weakPassword,
        ),
      );
      return;
    }

    emit(const AuthLoading());

    // 2. Real Firebase Auth call
    try {
      final user = await _authService.signInWithEmailAndPassword(
        email: event.email.trim(),
        password: event.password,
      );
      emit(AuthAuthenticated(user: user));
    } on AuthFailure catch (f) {
      emit(AuthError(message: f.message, type: f.type));
    } catch (_) {
      emit(
        const AuthError(
          message: 'Sign-in failed. Please try again.',
          type: AuthErrorType.unknown,
        ),
      );
    }
  }

  /// Handle sign up request with email/password.
  Future<void> _onAuthSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    // 1. Client-side validations
    if (event.email.isEmpty || !EmailValidator.isValid(event.email)) {
      emit(
        const AuthError(
          message: 'Please enter a valid email address',
          type: AuthErrorType.invalidEmail,
        ),
      );
      return;
    }

    if (event.password.length < 8) {
      emit(
        const AuthError(
          message: 'Password must be at least 8 characters',
          type: AuthErrorType.weakPassword,
        ),
      );
      return;
    }

    if (_isCommonPassword(event.password)) {
      emit(
        const AuthError(
          message: 'Password is too common. Choose a stronger password.',
          type: AuthErrorType.weakPassword,
        ),
      );
      return;
    }

    emit(const AuthLoading());

    // 2. Real Firebase Auth call
    try {
      final user = await _authService.signUpWithEmailAndPassword(
        email: event.email.trim(),
        password: event.password,
        displayName: event.displayName?.trim(),
      );
      emit(AuthAuthenticated(user: user));
    } on AuthFailure catch (f) {
      emit(AuthError(message: f.message, type: f.type));
    } catch (_) {
      emit(
        const AuthError(
          message: 'Sign-up failed. Please try again.',
          type: AuthErrorType.unknown,
        ),
      );
    }
  }

  /// Handle sign out request.
  Future<void> _onAuthSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    final previousUser = _authService.currentUser;
    emit(const AuthLoading());

    try {
      await _authService.signOut();
      emit(const AuthUnauthenticated());
    } on AuthFailure catch (failure) {
      final user = _authService.currentUser ?? previousUser;
      if (user == null) {
        emit(const AuthUnauthenticated());
      } else {
        emit(AuthSignOutFailed(user: user, message: failure.message));
      }
    } catch (_) {
      // Keep the authenticated screen and its actions available for retry.
      final user = _authService.currentUser ?? previousUser;
      if (user == null) {
        emit(const AuthUnauthenticated());
      } else {
        emit(
          AuthSignOutFailed(
            user: user,
            message: 'Could not sign out. Please try again.',
          ),
        );
      }
    }
  }

  /// Handle password reset request.
  Future<void> _onAuthPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (event.email.isEmpty || !EmailValidator.isValid(event.email)) {
      emit(
        const AuthError(
          message: 'Please enter a valid email address',
          type: AuthErrorType.invalidEmail,
        ),
      );
      return;
    }

    final sent = await _authService.sendPasswordResetEmail(event.email.trim());
    emit(
      AuthPasswordResetResult(
        success: sent,
        message: sent
            ? 'If an account exists for that email, a reset link has been sent.'
            : 'Could not send a reset email. Check your connection and try again.',
      ),
    );
  }

  /// Check for common weak passwords.
  bool _isCommonPassword(String password) {
    const commonPasswords = [
      'password',
      '12345678',
      'qwerty',
      'abc123',
      'password123',
      'letmein',
      'welcome',
    ];
    return commonPasswords.contains(password.toLowerCase());
  }
}
