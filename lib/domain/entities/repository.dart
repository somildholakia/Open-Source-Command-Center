import 'package:equatable/equatable.dart';

/// Normalized repository entity.
///
/// Contains only application-level information; GitHub-specific fields are
/// mapped (and dropped) by the provider implementation.
class Repository extends Equatable {
  /// Provider-internal repository id.
  final String id;

  /// Short name, e.g. `command-center`.
  final String name;

  /// Fully qualified name, e.g. `octocat/command-center`.
  final String fullName;

  /// Owner login, e.g. `octocat`.
  final String owner;

  /// Short description. May be empty.
  final String description;

  /// Whether the repository is private.
  final bool isPrivate;

  /// Whether this repository is a fork.
  final bool isFork;

  /// Web URL of the repository.
  final String url;

  /// Default branch name, e.g. `main`. Empty when unavailable.
  final String defaultBranch;

  /// Primary language, e.g. `Dart`. Empty when unavailable.
  final String language;

  /// Star count. Null when unavailable.
  final int? stars;

  /// Fork count. Null when unavailable.
  final int? forks;

  /// Open issue count. Null when unavailable.
  final int? openIssues;

  /// Last updated timestamp. Null when unavailable.
  final DateTime? updatedAt;

  const Repository({
    required this.id,
    required this.name,
    required this.fullName,
    required this.owner,
    required this.url,
    this.description = '',
    this.isPrivate = false,
    this.isFork = false,
    this.defaultBranch = '',
    this.language = '',
    this.stars,
    this.forks,
    this.openIssues,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    fullName,
    owner,
    url,
    description,
    isPrivate,
    isFork,
    defaultBranch,
    language,
    stars,
    forks,
    openIssues,
    updatedAt,
  ];
}
