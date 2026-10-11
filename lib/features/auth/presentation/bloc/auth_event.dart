import 'package:equatable/equatable.dart';

/// Base class for authentication events.
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check the current authentication status (e.g., on app start).
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// User requested a local-only preview session in an unconfigured debug build.
class AuthDemoSessionRequested extends AuthEvent {
  const AuthDemoSessionRequested();
}

/// User requested to sign in with email and password.
class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthSignInRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// User requested to sign up with email and password.
class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String? displayName;

  const AuthSignUpRequested({
    required this.email,
    required this.password,
    this.displayName,
  });

  @override
  List<Object?> get props => [email, password, displayName];
}

/// User requested to sign out.
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// User requested to reset their password.
class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested({required this.email});

  @override
  List<Object?> get props => [email];
}
