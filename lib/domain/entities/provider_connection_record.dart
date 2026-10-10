import 'package:equatable/equatable.dart';

import 'connected_account.dart';

/// Snapshot of a provider connection owned by the app user.
///
/// Persisted locally so the app can restore the connected state across
/// restarts. Contains NO access tokens — tokens live only in secure storage.
class ProviderConnectionRecord extends Equatable {
  /// Provider identifier, e.g. `github`.
  final String providerId;

  /// The connected account, when known.
  final ConnectedAccount? account;

  /// When the connection was established.
  final DateTime? connectedAt;

  /// Last successful data sync from this provider.
  final DateTime? lastSyncedAt;

  const ProviderConnectionRecord({
    required this.providerId,
    this.account,
    this.connectedAt,
    this.lastSyncedAt,
  });

  /// A record for a connected provider with the given account.
  factory ProviderConnectionRecord.connected({
    required String providerId,
    required ConnectedAccount account,
    DateTime? connectedAt,
    DateTime? lastSyncedAt,
  }) {
    return ProviderConnectionRecord(
      providerId: providerId,
      account: account,
      connectedAt: connectedAt ?? DateTime.now(),
      lastSyncedAt: lastSyncedAt,
    );
  }

  ProviderConnectionRecord copyWith({
    ConnectedAccount? account,
    DateTime? connectedAt,
    DateTime? lastSyncedAt,
  }) {
    return ProviderConnectionRecord(
      providerId: providerId,
      account: account ?? this.account,
      connectedAt: connectedAt ?? this.connectedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  @override
  List<Object?> get props => [providerId, account, connectedAt, lastSyncedAt];
}
