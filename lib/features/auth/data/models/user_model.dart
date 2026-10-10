import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// User model representing authenticated user data.
///
/// This model is used throughout the app to access user information.
class UserModel extends Equatable {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final DateTime? createdAt;

  const UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.createdAt,
  });

  /// Create a [UserModel] from a Firebase [User].
  ///
  /// This is the mapper that keeps the `firebase_auth` SDK type below the
  /// [AuthService] boundary so the rest of the app only ever sees [UserModel].
  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      createdAt: user.metadata.creationTime,
    );
  }

  /// Create an empty/mock user model for development.
  factory UserModel.empty() {
    return const UserModel(uid: '');
  }

  /// Whether the user is authenticated (non-empty uid).
  bool get isAuthenticated => uid.isNotEmpty;

  /// Get the user's display name or a default value.
  String get displayNameOrDefault => displayName ?? 'Developer';

  /// Get the user's initials for avatar display.
  String get initials {
    if (displayName == null || displayName!.isEmpty) {
      return '?';
    }
    final parts = displayName!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return displayName![0].toUpperCase();
  }

  @override
  List<Object?> get props => [uid, email, displayName, photoUrl, createdAt];
}
