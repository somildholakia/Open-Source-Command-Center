import 'package:equatable/equatable.dart';

import '../../../../services/firebase/auth_error.dart';
import '../../data/models/user_model.dart';

/// Represents the current authentication state.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state while app is loading.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Authentication state is being checked (e.g., checking cached session).
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User is not authenticated (logged out).
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// User is authenticated with their profile data.
class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

/// Authentication encountered an error.
class AuthError extends AuthState {
  final String message;
  final AuthErrorType type;

  const AuthError({required this.message, required this.type});

  @override
  List<Object?> get props => [message, type];
}
