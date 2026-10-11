import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../features/auth/data/models/user_model.dart';
import 'auth_error.dart';
import 'firebase_service.dart';

export 'auth_error.dart';

/// Wrapper around [FirebaseAuth] that keeps Firebase SDK types below
/// this boundary. Returns domain [UserModel]s and maps all
/// [FirebaseAuthException] errors to typed [AuthFailure]s.
class AuthService {
  final FirebaseAuth? _injectedAuth;

  /// Default constructor for production (uses [FirebaseAuth.instance]
  /// when [FirebaseService] is initialized).
  AuthService() : _injectedAuth = null;

  /// Test/custom constructor allowing an explicit [FirebaseAuth] instance.
  AuthService.custom({FirebaseAuth? auth}) : _injectedAuth = auth;

  /// Singleton instance used across the app.
  static final AuthService instance = AuthService();

  /// The underlying [FirebaseAuth] instance, or `null` when uninitialized.
  FirebaseAuth? get auth =>
      _injectedAuth ??
      (FirebaseService.instance.isInitialized ? FirebaseAuth.instance : null);

  /// Stream of authentication-state changes emitting domain [UserModel]s.
  ///
  /// Emits `UserModel` when signed in, `null` when signed out.
  /// When Firebase Auth is unavailable, emits `null` once so listeners can
  /// fall back to the unauthenticated state gracefully.
  Stream<UserModel?> get authStateChanges {
    final currentAuth = auth;
    if (currentAuth == null) {
      return Stream<UserModel?>.value(null);
    }
    return currentAuth.authStateChanges().map(
      (user) => user == null ? null : UserModel.fromFirebaseUser(user),
    );
  }

  /// Checks whether a user is currently signed in.
  Future<bool> isSignedIn() async {
    return currentUser != null;
  }

  /// Returns the currently signed-in user as a [UserModel], or `null`.
  UserModel? get currentUser {
    final user = auth?.currentUser;
    return user == null ? null : UserModel.fromFirebaseUser(user);
  }

  /// Signs in with email and password, returning the authenticated [UserModel].
  ///
  /// Throws an [AuthFailure] on any authentication error (with user-friendly
  /// message and mapped [AuthErrorType]).
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final currentAuth = auth;
    if (currentAuth == null) {
      throw const AuthFailure(
        type: AuthErrorType.unknown,
        message: 'Authentication service is unavailable.',
      );
    }

    try {
      final credential = await currentAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthFailure(
          type: AuthErrorType.unknown,
          message: 'Failed to retrieve user profile after sign-in.',
        );
      }
      return UserModel.fromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      // Do not surface arbitrary SDK/platform exception text to users.
      debugPrint(
        '[AuthService] Unexpected sign-in failure: ${e.runtimeType}',
      );
      throw const AuthFailure(
        type: AuthErrorType.unknown,
        message: 'Sign-in failed. Please try again.',
      );
    }
  }

  /// Creates a new user with email and password, optionally updating
  /// their display name, and returns the authenticated [UserModel].
  ///
  /// Throws an [AuthFailure] on error.
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final currentAuth = auth;
    if (currentAuth == null) {
      throw const AuthFailure(
        type: AuthErrorType.unknown,
        message: 'Authentication service is unavailable.',
      );
    }

    try {
      final credential = await currentAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthFailure(
          type: AuthErrorType.unknown,
          message: 'Failed to create user account.',
        );
      }

      if (displayName != null && displayName.isNotEmpty) {
        try {
          await user.updateDisplayName(displayName);
          await user.reload();
        } catch (e) {
          debugPrint('[AuthService] Failed to set display name: $e');
        }
      }

      // Re-fetch current user after any profile updates
      final updatedUser = currentAuth.currentUser ?? user;
      return UserModel.fromFirebaseUser(updatedUser);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      // Do not surface arbitrary SDK/platform exception text to users.
      debugPrint(
        '[AuthService] Unexpected sign-up failure: ${e.runtimeType}',
      );
      throw const AuthFailure(
        type: AuthErrorType.unknown,
        message: 'Sign-up failed. Please try again.',
      );
    }
  }

  /// Signs out the current user. Safe to call even when no user is signed in.
  Future<void> signOut() async {
    final currentAuth = auth;
    if (currentAuth == null) {
      debugPrint('[AuthService] signOut skipped: Firebase Auth unavailable');
      return;
    }
    await currentAuth.signOut();
  }

  /// Sends a password-reset email to [email].
  ///
  /// Returns `true` on success, `false` on failure.
  Future<bool> sendPasswordResetEmail(String email) async {
    final currentAuth = auth;
    if (currentAuth == null) {
      debugPrint(
        '[AuthService] sendPasswordResetEmail skipped: Firebase Auth unavailable',
      );
      return false;
    }
    try {
      await currentAuth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      debugPrint('[AuthService] Password reset failed: $e');
      return false;
    }
  }

  /// Maps [FirebaseAuthException] error codes to [AuthFailure] with friendly messages.
  AuthFailure _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return const AuthFailure(
          type: AuthErrorType.invalidEmail,
          message: 'Please enter a valid email address.',
        );
      case 'user-disabled':
        return const AuthFailure(
          type: AuthErrorType.unknown,
          message: 'This account has been disabled. Contact support.',
        );
      case 'user-not-found':
        return const AuthFailure(
          type: AuthErrorType.userNotFound,
          message: 'No account found with this email.',
        );
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthFailure(
          type: AuthErrorType.wrongPassword,
          message: 'Invalid email or password.',
        );
      case 'email-already-in-use':
        return const AuthFailure(
          type: AuthErrorType.emailAlreadyInUse,
          message: 'An account already exists for this email address.',
        );
      case 'operation-not-allowed':
        return const AuthFailure(
          type: AuthErrorType.unknown,
          message:
              'Email/password sign-in is not enabled in the Firebase Console.',
        );
      case 'weak-password':
        return const AuthFailure(
          type: AuthErrorType.weakPassword,
          message: 'Password is too weak. Choose a stronger password.',
        );
      case 'network-request-failed':
        return const AuthFailure(
          type: AuthErrorType.networkError,
          message: 'Network error. Check your internet connection.',
        );
      case 'too-many-requests':
        return const AuthFailure(
          type: AuthErrorType.unknown,
          message: 'Too many attempts. Please try again later.',
        );
      default:
        // Firebase's raw message may contain implementation details. The
        // known user-actionable codes above already have specific messages.
        debugPrint('[AuthService] Unmapped Firebase auth code: ${e.code}');
        return const AuthFailure(
          type: AuthErrorType.unknown,
          message: 'Authentication failed. Please try again.',
        );
    }
  }
}
