import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/domain.dart';
import '../../../../services/progression/progression_store.dart';

/// How the intelligence's data source is doing, so screens can tell
/// "nothing connected yet" apart from "connection expired" and "last sync
/// failed" without reading the integration bloc.
enum IntelligenceSourceStatus {
  /// No provider connection (or signed out).
  disconnected,

  /// A provider connection exists; data may be loading, present or partial.
  connected,

  /// The stored authorization was rejected — the user must reconnect.
  expired,

  /// The last provider request failed; previously loaded data may still exist.
  failed,
}

/// Events driving the derived developer intelligence.
sealed class IntelligenceEvent {
  const IntelligenceEvent();
}

/// Provider data changed (or its connection state did): recompute.
class IntelligenceSourceChanged extends IntelligenceEvent {
  /// Connected account key (`<providerId>:<username>`), or null when
  /// disconnected.
  ///
  /// Progression history is scoped by account, so this decides whose record is
  /// loaded.
  final String? accountId;

  final List<DeveloperActivity> activities;
  final ContributionSummary? contributions;
  final List<Repository> repositories;
  final IntelligenceSourceStatus status;

  /// True while the source is loading or refreshing.
  final bool busy;

  /// Last source failure, when any.
  final ProviderFailure? failure;

  /// When the connection last synced successfully, when known.
  final DateTime? lastSyncedAt;

  const IntelligenceSourceChanged({
    this.accountId,
    this.activities = const [],
    this.contributions,
    this.repositories = const [],
    this.status = IntelligenceSourceStatus.disconnected,
    this.busy = false,
    this.failure,
    this.lastSyncedAt,
  });
}

/// The developer asked to forget persisted progression history for the
/// connected account.
///
/// Achievements that the current data still satisfies legitimately remain
/// unlocked (they are derived, not stored); what is dropped is the recorded
/// history the data window can no longer recreate.
class IntelligenceProgressionResetRequested extends IntelligenceEvent {
  const IntelligenceProgressionResetRequested();
}

/// The provider account was disconnected or replaced by another account.
///
/// Persisted progression history is account-scoped and should not remain on a
/// shared device after the user disconnects that account.
class IntelligenceAccountDisconnected extends IntelligenceEvent {
  final String accountId;

  const IntelligenceAccountDisconnected(this.accountId);
}

/// Developer progression resolved from the source data.
class IntelligenceState extends Equatable {
  /// Deterministic intelligence; never null. Zeroed while there is no data.
  final DeveloperIntelligence intelligence;

  /// Persisted progression history for [accountId].
  final ProgressionRecord progression;

  final IntelligenceSourceStatus status;

  /// True while the source is loading or refreshing.
  final bool busy;

  /// Account whose progression is loaded, or null when disconnected.
  final String? accountId;

  /// Last source failure, when any.
  final ProviderFailure? failure;

  /// When the connection last synced successfully, when known.
  final DateTime? lastSyncedAt;

  /// When the intelligence was last recomputed.
  final DateTime? computedAt;

  const IntelligenceState({
    required this.intelligence,
    this.progression = ProgressionRecord.empty,
    this.status = IntelligenceSourceStatus.disconnected,
    this.busy = false,
    this.accountId,
    this.failure,
    this.lastSyncedAt,
    this.computedAt,
  });

  /// State before any provider data was seen: zeroed, no connection.
  factory IntelligenceState.empty() => IntelligenceState(
    intelligence: DeveloperIntelligenceEngine.compute(activities: const []),
  );

  /// Whether real provider data backs the current intelligence.
  bool get hasData => intelligence.hasData;

  /// Whether a usable connection exists (data may still be loading).
  bool get connected =>
      status == IntelligenceSourceStatus.connected ||
      status == IntelligenceSourceStatus.failed;

  /// Whether progress is blocked on connecting (or reconnecting) a provider.
  bool get needsConnection =>
      status == IntelligenceSourceStatus.disconnected ||
      status == IntelligenceSourceStatus.expired;

  /// Whether the data on screen is stale because the last sync failed after
  /// data had already been loaded.
  bool get isStale => failure != null && intelligence.hasData;

  IntelligenceState copyWith({
    DeveloperIntelligence? intelligence,
    ProgressionRecord? progression,
    IntelligenceSourceStatus? status,
    bool? busy,
    String? accountId,
    bool clearAccountId = false,
    ProviderFailure? failure,
    bool clearFailure = false,
    DateTime? lastSyncedAt,
    DateTime? computedAt,
  }) {
    return IntelligenceState(
      intelligence: intelligence ?? this.intelligence,
      progression: progression ?? this.progression,
      status: status ?? this.status,
      busy: busy ?? this.busy,
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
      failure: clearFailure ? null : (failure ?? this.failure),
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      computedAt: computedAt ?? this.computedAt,
    );
  }

  @override
  List<Object?> get props => [
    intelligence,
    progression,
    status,
    busy,
    accountId,
    failure,
    lastSyncedAt,
    computedAt,
  ];
}

/// Derives and publishes developer intelligence from normalized provider data.
///
/// This bloc owns no provider/network concerns: it receives an
/// [IntelligenceSourceChanged] snapshot, recomputes the pure-Dart engine, and
/// persists only the non-derivable progression history. Screens therefore read
/// one state for XP, level, streak, achievements and quests.
class IntelligenceBloc extends Bloc<IntelligenceEvent, IntelligenceState> {
  final ProgressionStore _store;
  final DateTime Function() _clock;
  final Map<String, ProgressionRecord> _progressionByAccount = {};
  IntelligenceSourceChanged? _lastSource;
  int _sourceGeneration = 0;

  IntelligenceBloc(this._store, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      super(IntelligenceState.empty()) {
    on<IntelligenceSourceChanged>(_onSourceChanged);
    on<IntelligenceProgressionResetRequested>(_onProgressionResetRequested);
    on<IntelligenceAccountDisconnected>(_onAccountDisconnected);
  }

  ProgressionRecord _progressionFor(String accountId) {
    return _progressionByAccount.putIfAbsent(
      accountId,
      () => _store.load(accountId),
    );
  }

  Future<void> _onSourceChanged(
    IntelligenceSourceChanged event,
    Emitter<IntelligenceState> emit,
  ) async {
    final generation = ++_sourceGeneration;
    _lastSource = event;

    final accountId = event.accountId;
    var progression = accountId == null
        ? ProgressionRecord.empty
        : _progressionFor(accountId);

    final now = _clock();
    var intelligence = DeveloperIntelligenceEngine.compute(
      activities: event.activities,
      contributions: event.contributions,
      repositories: event.repositories,
      progression: progression,
      now: now,
    );

    if (accountId != null && _hasNewProgression(intelligence)) {
      for (final id in intelligence.newlyUnlockedAchievementIds) {
        progression = progression.withAchievement(id, now);
      }
      for (final key in intelligence.newlyCompletedQuestKeys) {
        progression = progression.withQuestCompleted(key);
      }
      _progressionByAccount[accountId] = progression;
      try {
        await _store.save(accountId, progression);
      } catch (_) {
        // Persistence is best-effort: progression still works this session.
      }
      if (isClosed || generation != _sourceGeneration) return;

      // Recompute so recorded unlocks carry their timestamps and nothing is
      // reported as new twice.
      intelligence = DeveloperIntelligenceEngine.compute(
        activities: event.activities,
        contributions: event.contributions,
        repositories: event.repositories,
        progression: progression,
        now: now,
      );
    }

    if (isClosed || generation != _sourceGeneration) return;
    emit(
      IntelligenceState(
        intelligence: intelligence,
        progression: progression,
        status: event.status,
        busy: event.busy,
        accountId: accountId,
        failure: event.failure,
        lastSyncedAt: event.lastSyncedAt,
        computedAt: now,
      ),
    );
  }

  bool _hasNewProgression(DeveloperIntelligence intelligence) =>
      intelligence.newlyUnlockedAchievementIds.isNotEmpty ||
      intelligence.newlyCompletedQuestKeys.isNotEmpty;

  Future<void> _onAccountDisconnected(
    IntelligenceAccountDisconnected event,
    Emitter<IntelligenceState> _,
  ) async {
    // Invalidate a refresh/source event still writing the disconnected
    // account's history. This event intentionally does not recompute derived
    // achievements, because the account is no longer connected.
    ++_sourceGeneration;
    _progressionByAccount.remove(event.accountId);
    try {
      await _store.clear(event.accountId);
    } catch (_) {
      // Best-effort cleanup must not block the connection lifecycle.
    }
    _progressionByAccount.remove(event.accountId);
  }

  Future<void> _onProgressionResetRequested(
    IntelligenceProgressionResetRequested event,
    Emitter<IntelligenceState> emit,
  ) async {
    // Invalidate any source event still awaiting persistence before resetting.
    ++_sourceGeneration;
    final accountId = state.accountId;
    if (accountId == null) return;

    _progressionByAccount.remove(accountId);
    try {
      await _store.clear(accountId);
    } catch (_) {
      // Best-effort; in-memory history is forgotten either way.
    }
    if (isClosed) return;

    final source = _lastSource;
    if (source != null) {
      add(source);
    } else {
      emit(
        state.copyWith(
          progression: ProgressionRecord.empty,
          computedAt: _clock(),
        ),
      );
    }
  }
}
