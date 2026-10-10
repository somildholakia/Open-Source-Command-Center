import 'package:equatable/equatable.dart';

/// Normalized provider-connected developer account (e.g. a GitHub account).
///
/// This is deliberately NOT the application identity (Firebase Auth user).
/// It represents an external developer account linked to the app account.
class ConnectedAccount extends Equatable {
  /// Provider identifier, e.g. `github`.
  final String providerId;

  /// Account login handle on the provider, e.g. `octocat`.
  final String username;

  /// Public avatar URL. Empty when unavailable.
  final String avatarUrl;

  /// Public profile URL. Empty when unavailable.
  final String profileUrl;

  /// When the connection to this account was established.
  final DateTime? connectedAt;

  const ConnectedAccount({
    required this.providerId,
    required this.username,
    required this.avatarUrl,
    required this.profileUrl,
    this.connectedAt,
  });

  @override
  List<Object?> get props => [
    providerId,
    username,
    avatarUrl,
    profileUrl,
    connectedAt,
  ];
}
