import 'package:equatable/equatable.dart';

/// Typed, provider-agnostic failures surfaced to the UI.
///
/// Provider implementations map their native errors (HTTP status codes,
/// GraphQL errors, socket failures) onto these inside the data layer; widgets
/// never inspect raw HTTP responses.
sealed class ProviderFailure extends Equatable {
  const ProviderFailure();

  @override
  List<Object?> get props => [];
}

/// No provider connection is established (or the stored one is unusable).
class ProviderNotConnected extends ProviderFailure {
  const ProviderNotConnected();
}

/// The authorization attempt failed or was rejected by the user.
class AuthenticationFailed extends ProviderFailure {
  final String? detail;

  const AuthenticationFailed({this.detail});

  @override
  List<Object?> get props => [detail];
}

/// The stored token is no longer accepted (revoked/expired/bad credentials).
class AuthorizationExpired extends ProviderFailure {
  const AuthorizationExpired();
}

/// The provider is rate limiting requests; [resetAt] when known upstream.
class RateLimited extends ProviderFailure {
  /// When the rate limit window resets, if the provider reported it.
  final DateTime? resetAt;

  const RateLimited({this.resetAt});

  @override
  List<Object?> get props => [resetAt];
}

/// No usable network connection to the provider.
class NetworkUnavailable extends ProviderFailure {
  const NetworkUnavailable();
}

/// The provider API answered but is unavailable/misbehaving (5xx, bad body).
class ApiUnavailable extends ProviderFailure {
  final int? statusCode;

  const ApiUnavailable({this.statusCode});

  @override
  List<Object?> get props => [statusCode];
}

/// The token lacks the scopes required for the requested data.
class PermissionDenied extends ProviderFailure {
  const PermissionDenied();
}

/// Anything else.
class UnknownProviderError extends ProviderFailure {
  final String? detail;

  const UnknownProviderError({this.detail});

  @override
  List<Object?> get props => [detail];
}
