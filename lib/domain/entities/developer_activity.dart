import 'package:equatable/equatable.dart';

/// Normalized developer activity types.
///
/// Provider implementations map their native events (GitHub events API,
/// GitLab events, etc.) onto these variants; unknown upstream events are
/// dropped by the mapper rather than forced into a wrong category.
enum DeveloperActivityType {
  commitPushed,
  pullRequestOpened,
  pullRequestClosed,
  pullRequestMerged,
  pullRequestReviewed,
  issueOpened,
  issueClosed,
  issueCommented,
  repositoryCreated,
  repositoryForked,
  releasePublished,
  starred,
}

/// A single normalized activity event for the timeline.
///
/// `timestamp` is a real [DateTime]; UI layers format it for display.
class DeveloperActivity extends Equatable {
  /// Stable unique id for the event (provider-specific, e.g. GitHub event id).
  final String id;

  final DeveloperActivityType type;

  /// Repository full name the event occurred in, e.g. `octocat/hello-world`.
  final String repository;

  /// Short title, e.g. `refactor: migrate to latest bloc version`.
  final String title;

  /// Optional secondary line, e.g. `3 files changed, +245 additions`.
  final String? subtitle;

  /// Optional identifier: PR/issue number (`#123`) or commit sha.
  final String? identifier;

  /// Provider-internal event type label (e.g. `PushEvent`).
  final String? rawType;

  /// When the event happened.
  final DateTime timestamp;

  /// Number of underlying items this event represents, when the provider
  /// exposes it (e.g. commits contained in a push). Null when unknown —
  /// callers must not invent a value.
  final int? commitCount;

  const DeveloperActivity({
    required this.id,
    required this.type,
    required this.repository,
    required this.title,
    required this.timestamp,
    this.subtitle,
    this.identifier,
    this.rawType,
    this.commitCount,
  });

  @override
  List<Object?> get props => [
    id,
    type,
    repository,
    title,
    subtitle,
    identifier,
    rawType,
    timestamp,
    commitCount,
  ];
}
