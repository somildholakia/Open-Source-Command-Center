import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/navigation/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_preference.dart';
import 'features/auth/presentation/bloc/auth.dart';
import 'domain/domain.dart';
import 'features/integrations/presentation/bloc/integration_bloc.dart';
import 'features/progress/presentation/bloc/intelligence_bloc.dart';
import 'services/firebase/auth_service.dart';
import 'services/firebase/firebase_service.dart';
import 'services/github/github_provider.dart';
import 'services/progression/progression_store.dart';

/// Root application widget.
///
/// Configures theme, routing, and app-level settings.
///
/// Phase 2: also owns the app-scoped [IntegrationBloc] (provider connection
/// state + normalized GitHub data shared across all screens).
///
/// Phase 3: owns the app-scoped [IntelligenceBloc], which turns that normalized
/// data into level, XP, streaks, achievements and quests and is the single
/// source of progression state for every screen.
class App extends StatefulWidget {
  final AuthService? authService;

  /// Overrides the default [GitHubProvider] (used by widget tests to avoid
  /// platform-channel storage; production uses the real provider).
  final DeveloperProvider? developerProvider;

  /// Progression persistence. Production passes the SharedPreferences-backed
  /// store loaded in `main`; tests fall back to an in-memory store.
  final ProgressionStore? progressionStore;

  const App({
    super.key,
    this.authService,
    this.developerProvider,
    this.progressionStore,
  });

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _router;
  String? _lastConnectedAccountId;
  bool _demoSessionActive = false;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.createRouter();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final mode = await ThemePreference.getThemeMode();
    ThemePreference.notifier.value = mode;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) =>
              AuthBloc(authService: widget.authService ?? AuthService.instance),
        ),
        BlocProvider<IntegrationBloc>(
          create: (context) => IntegrationBloc(
            provider: widget.developerProvider ?? GitHubProvider(),
          ),
        ),
        BlocProvider<IntelligenceBloc>(
          create: (context) => IntelligenceBloc(
            widget.progressionStore ?? InMemoryProgressionStore(),
          ),
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        // Only react to actual session transitions, not repeated emissions.
        listenWhen: (previous, current) =>
            (current is AuthAuthenticated && previous is! AuthAuthenticated) ||
            (current is AuthUnauthenticated &&
                previous is! AuthUnauthenticated),
        listener: (context, state) {
          final integration = context.read<IntegrationBloc>();
          if (state is AuthAuthenticated) {
            if (state.user.uid == 'local-demo') {
              // The local preview must not load or mutate a real GitHub session.
              _demoSessionActive = true;
            } else {
              _demoSessionActive = false;
              integration.add(const IntegrationStarted());
            }
          } else if (state is AuthUnauthenticated) {
            if (_demoSessionActive ||
                !FirebaseService.instance.isInitialized) {
              // A local preview or unavailable Firebase setup has no Firebase
              // session whose sign-out should erase a stored GitHub connection.
              _demoSessionActive = false;
            } else {
              integration.add(const IntegrationResetRequested());
            }
          }
        },
        child: BlocListener<IntegrationBloc, IntegrationState>(
          // Recompute progression only when something that affects it changed
          // (data, connection phase, busy flag, failure or last sync).
          listenWhen: (previous, current) =>
              _intelligenceSourceChanged(previous, current),
          listener: (context, state) {
            final intelligenceBloc = context.read<IntelligenceBloc>();
            final currentAccountId = _accountIdOf(state);
            final previousAccountId = _lastConnectedAccountId;

            if (state.phase == IntegrationPhase.disconnected) {
              if (previousAccountId != null) {
                intelligenceBloc.add(
                  IntelligenceAccountDisconnected(previousAccountId),
                );
              }
              _lastConnectedAccountId = null;
            } else if (currentAccountId != null) {
              if (previousAccountId != null &&
                  previousAccountId != currentAccountId) {
                intelligenceBloc.add(
                  IntelligenceAccountDisconnected(previousAccountId),
                );
              }
              _lastConnectedAccountId = currentAccountId;
            }

            intelligenceBloc.add(_intelligenceSourceOf(state));
          },
          child: ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemePreference.notifier,
            builder: (context, themeMode, _) {
              return MaterialApp.router(
                title: 'Open Source Command Center',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,
                routerConfig: _router,
                builder: (context, child) =>
                    _ThemeSyncWidget(child: child ?? const SizedBox.shrink()),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Source status the intelligence layer should act on.
IntelligenceSourceStatus _intelligenceStatusOf(IntegrationState state) {
  switch (state.phase) {
    case IntegrationPhase.connected:
      return IntelligenceSourceStatus.connected;
    case IntegrationPhase.expired:
      return IntelligenceSourceStatus.expired;
    case IntegrationPhase.error:
      return IntelligenceSourceStatus.failed;
    case IntegrationPhase.unknown:
    case IntegrationPhase.disconnected:
    case IntegrationPhase.connecting:
      return IntelligenceSourceStatus.disconnected;
  }
}

/// Progression history is scoped to the connected account, so signing in as a
/// different developer never shows someone else's achievements.
String? _accountIdOf(IntegrationState state) {
  final record = state.connection;
  final account = record?.account;
  final username = account?.username;
  if (record == null || username == null || username.isEmpty) return null;
  return '${account?.providerId ?? record.providerId}:$username';
}

IntelligenceSourceChanged _intelligenceSourceOf(IntegrationState state) {
  return IntelligenceSourceChanged(
    accountId: _accountIdOf(state),
    activities: state.activities,
    contributions: state.contributions,
    repositories: state.repositories,
    status: _intelligenceStatusOf(state),
    // `unknown` is the session-restore phase: treat it as loading.
    busy: state.isBusy || state.phase == IntegrationPhase.unknown,
    failure: state.failure,
    lastSyncedAt: state.connection?.lastSyncedAt,
  );
}

bool _intelligenceSourceChanged(
  IntegrationState previous,
  IntegrationState current,
) {
  return current.phase != previous.phase ||
      current.isBusy != previous.isBusy ||
      current.failure != previous.failure ||
      current.connection?.lastSyncedAt != previous.connection?.lastSyncedAt ||
      _accountIdOf(current) != _accountIdOf(previous) ||
      !identical(current.activities, previous.activities) ||
      !identical(current.contributions, previous.contributions) ||
      !identical(current.repositories, previous.repositories);
}

/// Keeps [AppColors] static token resolution in sync with the theme
/// MaterialApp actually applies (theme + darkTheme + themeMode).
///
/// MaterialApp evaluates its theme getters in a fixed order regardless of
/// [ThemeMode], so the static flag set during ThemeData construction can go
/// stale. This widget reads the effective theme below MaterialApp and
/// re-configures the tokens; widgets build after it, so every screen reads
/// fresh, theme-consistent values.
class _ThemeSyncWidget extends StatelessWidget {
  final Widget child;

  const _ThemeSyncWidget({required this.child});

  @override
  Widget build(BuildContext context) {
    AppColors.configureForBrightness(Theme.of(context).brightness);
    return child;
  }
}
