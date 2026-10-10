import 'package:equatable/equatable.dart';

/// A step in an authorization flow that requires the user to act outside the
/// app (typically: enter a code in a browser).
///
/// Provider-agnostic: GitHub's device flow maps into this; future providers
/// (web-redirect OAuth etc.) can express "open this URL" the same way.
class ConnectionPrompt extends Equatable {
  /// Human-readable instructions, e.g. "Enter this code at github.com/login/device".
  final String instructions;

  /// Short code the user types, e.g. `WDJB-MJHT`. Null for URL-only flows.
  final String? userCode;

  /// URL the user should open in a browser.
  final String verificationUrl;

  /// When the code expires, if known.
  final DateTime? expiresAt;

  const ConnectionPrompt({
    required this.instructions,
    required this.verificationUrl,
    this.userCode,
    this.expiresAt,
  });

  @override
  List<Object?> get props => [
    instructions,
    userCode,
    verificationUrl,
    expiresAt,
  ];
}
