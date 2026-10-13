import '../../../../domain/domain.dart';

/// Maps typed [ProviderFailure]s to user-facing copy.
///
/// Keeps presentation strings out of the data layer and guarantees every
/// failure type has intentional UX (no raw HTTP text in the UI).
String failureMessage(ProviderFailure failure) {
  switch (failure) {
    case ProviderNotConnected():
      return 'Connect a developer platform to see your data here.';
    case AuthenticationFailed(:final detail):
      return detail ?? 'Authorization failed. Please try again.';
    case AuthorizationExpired():
      return 'GitHub access expired or was revoked. Reconnect to continue.';
    case RateLimited(:final resetAt):
      final when = resetAt == null
          ? 'in a little while'
          : 'after ${formatClock(resetAt)}';
      return 'GitHub rate limit reached. Try again $when.';
    case NetworkUnavailable(:final stage):
      if (stage != null) {
        return 'Could not reach GitHub while $stage. Check your connection and try again.';
      }
      return 'No network connection. Check your internet and try again.';
    case ApiUnavailable():
      return 'GitHub is temporarily unavailable. Try again shortly.';
    case PermissionDenied():
      return 'The connected GitHub account cannot access this data.';
    case UnknownProviderError():
      // Deliberately generic: internal error details (stack traces, payload
      // fragments) stay out of the UI and are available for logging only.
      return 'Something went wrong. Please try again.';
  }
}

String formatClock(DateTime time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
