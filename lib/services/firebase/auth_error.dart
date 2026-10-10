/// Types of authentication errors for better user feedback.
enum AuthErrorType {
  invalidEmail,
  weakPassword,
  userNotFound,
  wrongPassword,
  emailAlreadyInUse,
  networkError,
  unknown,
}

/// Typed authentication failure thrown by [AuthService].
///
/// Carries the mapped [AuthErrorType] plus a user-facing message so the
/// presentation layer can render feedback without knowing about
/// `FirebaseAuthException` codes.
class AuthFailure implements Exception {
  final AuthErrorType type;
  final String message;

  const AuthFailure({required this.type, required this.message});

  @override
  String toString() => 'AuthFailure($type): $message';
}
