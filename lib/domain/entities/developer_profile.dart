import 'package:equatable/equatable.dart';

/// Normalized developer profile from a connected provider (e.g. GitHub).
///
/// Provider-agnostic: GitHub's user API response is mapped into this model by
/// the provider implementation, so UI code never sees GitHub JSON.
class DeveloperProfile extends Equatable {
  /// Provider-internal account id (GitHub numeric id as string).
  final String id;

  /// Login handle, e.g. `octocat`.
  final String username;

  /// Display name, e.g. `The Octocat`. May be empty when unset upstream.
  final String displayName;

  /// Public avatar URL. May be empty when unavailable.
  final String avatarUrl;

  /// Public profile URL, e.g. `https://github.com/octocat`.
  final String profileUrl;

  /// Public bio. May be empty.
  final String bio;

  /// Count of public repositories. Null when the provider does not expose it.
  final int? publicRepositoryCount;

  /// Count of followers. Null when the provider does not expose it.
  final int? followersCount;

  /// Count of accounts followed. Null when not exposed.
  final int? followingCount;

  /// When the provider account was created. Null when not exposed.
  final DateTime? createdAt;

  const DeveloperProfile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.profileUrl,
    this.bio = '',
    this.publicRepositoryCount,
    this.followersCount,
    this.followingCount,
    this.createdAt,
  });

  /// Best available display name: display name, else username.
  String get effectiveDisplayName =>
      displayName.isNotEmpty ? displayName : username;

  @override
  List<Object?> get props => [
    id,
    username,
    displayName,
    avatarUrl,
    profileUrl,
    bio,
    publicRepositoryCount,
    followersCount,
    followingCount,
    createdAt,
  ];
}
