# Architecture — Open Source Developer Command Center

**Last updated:** 2026-10-03
**Current phase:** Phase 2 — GitHub Integration (implementation complete; verification in progress)

This document records the architecture decisions that are actually implemented in
the codebase. Anything not yet built is listed under "Not implemented yet".

---

## 1. Overview

A mobile-first Flutter application that turns open-source contribution activity
into an actionable, gamified developer experience. Android is the primary target.

The product is **not** a GitHub statistics dashboard: the UI is a dark/navy,
pixel-art-inspired, game-like design system, and GitHub data is normalized into
domain entities so that future providers (GitLab, Bitbucket, Jira, Linear) can be
added behind the same abstraction.

---

## 2. Layering

```
UI (features/*/presentation)
        │  reads state, dispatches events
        ▼
BLoC (flutter_bloc)
        │  calls provider abstraction
        ▼
Domain (lib/domain)          ← entities, provider interface, typed failures
        ▲  implemented by
Services (lib/services/*)    ← GitHub REST/GraphQL, device flow, token storage,
                               connection persistence, Firebase linking
```

Rules enforced in code:

- `lib/domain` has **no** dependency on Flutter widgets, `http`, Firebase, or
  `flutter_secure_storage`. It is pure Dart (plus `equatable`).
- Feature code never talks to the GitHub HTTP API directly; it goes through
  `DeveloperProvider`.
- Business logic (state transitions, error mapping, dedupe, retries) lives in
  blocs/services, not in widgets.
- Reusable UI is centralized in `lib/core/widgets` and feature `widgets/`.

### Directory map (as implemented)

```
lib/
  core/
    config/app_config.dart           Environment + app metadata
    navigation/                      go_router + responsive shell
    theme/                           Colors, typography, spacing, themes, preference
    utils/                           responsive_helper, time_ago
    widgets/                         responsive_layout, provider_avatar,
                                     sample_data_banner, status_message_card
  domain/
    entities/                        developer_profile, connected_account,
                                     repository, developer_activity,
                                     contribution_summary, provider_connection_record
    errors/provider_failure.dart     Sealed typed failures
    providers/                       developer_provider.dart, connection_prompt.dart
  features/
    auth/                            Firebase Auth UI + AuthBloc
    dashboard/                       Home tab (hero card, stats, repos section)
    activity/                        Normalized feed + filters
    contributions/                   Calendar + stats
    repositories/                    Shared repository list widgets
    integrations/                    IntegrationBloc + GitHub connection UI
    progress/                        Placeholder (Phase 3)
    profile/                         Profile + connection card
    settings/                        Appearance/account/about/sign-out
  services/
    connection/connection_store.dart Non-secret connection record persistence
    firebase/                        Firebase wrappers (Auth, Analytics, Crashlytics)
    github/                          Config, API client, device flow, token store,
                                     Firebase link, mappers, provider
  app.dart                           Root widget: theme + blocs + router
  main.dart                          Entry point: Firebase init + runApp
```

---

## 3. State management

**flutter_bloc** with `equatable` states.

Two blocs are provided at the root in `lib/app.dart`:

| Bloc | Responsibility | Lifecycle |
| --- | --- | --- |
| `AuthBloc` | Firebase session: check, sign-in, sign-up, sign-out, errors | App lifetime |
| `IntegrationBloc` | GitHub connection + fetched data (profile, repos, activity, contributions) | App lifetime |

The blocs are wired by a `BlocListener<AuthBloc>` in `lib/app.dart` with a
transition-only `listenWhen`:

- `AuthAuthenticated` → `IntegrationStarted` (load any persisted connection)
- `AuthUnauthenticated` → `IntegrationResetRequested` (clear in-memory data)

Separation of concerns:

- **UI state** (filter chip selection, dialogs) lives in `StatefulWidget`s.
- **Application state** (connection phase, fetched data, loading flags) lives in
  `IntegrationBloc`.
- **Network state** is modeled explicitly in `IntegrationState`
  (`isLoadingData`, `isRefreshing`, `failure`) rather than inferred in widgets.

`IntegrationBloc` accepts an injected `DeveloperProvider` (default
`GitHubProvider()`), which is how tests substitute `FakeDeveloperProvider`.

---

## 4. Domain model

### Entities (`lib/domain/entities`)

| Entity | Notes |
| --- | --- |
| `DeveloperProfile` | providerId, username, displayName, avatarUrl, bio, profileUrl, publicRepos, followers, following; `effectiveDisplayName` falls back to username |
| `ConnectedAccount` | Lightweight provider identity used in UI (providerId, username, avatarUrl, profileUrl, connectedAt) |
| `Repository` | name, fullName, description, language, stars, forks, isFork, updatedAt, htmlUrl |
| `DeveloperActivity` | id, type (`DeveloperActivityType`, 12 variants), title, repositoryName, identifier, url, timestamp, `commitCount` (push events) |
| `ContributionSummary` | `dailyCounts` keyed `yyyy-MM-dd`, `total`, `countForDate` |
| `ProviderConnectionRecord` | Non-secret persisted record: providerId, username, avatarUrl, profileUrl, connectedAt |

### Provider abstraction (`lib/domain/providers/developer_provider.dart`)

```dart
abstract class DeveloperProvider {
  String get providerId;
  String get displayName;
  Future<bool> get isConnected;
  Future<ConnectionResult> connect({void Function(ConnectionPrompt)? onPrompt});
  Future<void> cancelAuthorization();
  Future<void> disconnect();
  Future<DeveloperProfile> fetchProfile();
  Future<List<Repository>> fetchRepositories({int limit});
  Future<List<DeveloperActivity>> fetchActivity({int limit = 30});
  Future<ContributionSummary> fetchContributions();
}
```

`ConnectionPrompt` carries the device-flow user code, verification URL, expiry
and polling interval so the UI can display it while `connect()` is pending.

### Typed failures (`lib/domain/errors/provider_failure.dart`)

A sealed hierarchy — no raw strings or exception types cross the domain
boundary:

`ProviderNotConnected`, `AuthenticationFailed(detail?)`,
`AuthorizationExpired`, `RateLimited(resetAt?)`, `NetworkUnavailable`,
`ApiUnavailable(statusCode?)`, `PermissionDenied`, `UnknownProviderError(detail?)`.

UI maps these to friendly copy in
`lib/features/integrations/presentation/utils/failure_message.dart`. Internal
`detail` text is **not** shown to users.

---

## 5. GitHub integration

### 5.1 Authentication — OAuth Device Authorization Flow

Chosen because it is the only GitHub OAuth flow that requires **no client
secret** in the client, satisfying the project rule that no GitHub secret may
live in the Flutter app.

Flow:

1. User taps **Connect GitHub** → `IntegrationBloc` dispatches
   `IntegrationConnectRequested`.
2. `GitHubProvider.connect` calls the device-code endpoint
   (`POST https://github.com/login/device/code`) with the public client id and
   scope `read:user`.
3. A `ConnectionPrompt` (user code + verification URL) is emitted to the UI,
   which opens the URL via `url_launcher`.
4. The provider polls `POST https://github.com/login/oauth/access_token`,
   handling `authorization_pending`, `slow_down` (backoff), `expired_token`,
   `access_denied` and `incorrect_device_code`.
5. On success the token is written to `flutter_secure_storage` and a non-secret
   `ProviderConnectionRecord` to `SharedPreferences`; then data is fetched.

Cancellation is supported (`cancelAuthorization`) and disconnecting clears both
stores.

### 5.2 Configuration

`GitHubConfig` reads the client id from
`String.fromEnvironment('GITHUB_OAUTH_CLIENT_ID')`. If absent, `connect()`
fails fast with a typed `AuthenticationFailed` naming the missing define; the
rest of the app continues to work. Full external setup is documented in
[docs/GITHUB_SETUP.md](docs/GITHUB_SETUP.md).

### 5.3 Data sources (`GitHubApiClient`)

| Call | Transport |
| --- | --- |
| Profile | REST `GET /user` |
| Repositories | REST `GET /user/repos?sort=updated` |
| Activity | REST `GET /users/{login}/events/public` |
| Contributions | GraphQL `contributionsCollection` (calendar + totals) |

All requests use a 20-second timeout. HTTP failures are mapped to typed domain
failures (401 → `AuthorizationExpired`, 403 → `RateLimited`/`PermissionDenied`
based on `x-ratelimit-remaining`, 404 → `ProviderNotConnected`, 422 →
`PermissionDenied`, 5xx → `ApiUnavailable`, timeouts/socket errors →
`NetworkUnavailable`).

`github_mappers.dart` converts raw payloads into domain entities; unsupported
event types are dropped rather than displayed as unknown.

### 5.4 Token storage

`GitHubTokenStore` wraps `flutter_secure_storage` (Android Keystore) and keeps
an in-memory fallback for platforms/tests where the platform channel is
unavailable. Tokens are never logged, never placed in `SharedPreferences`,
never in analytics.

### 5.5 Firebase identity linking (optional)

After authorization, `FirebaseGitHubLinker` attempts
`linkWithCredential(GithubAuthProvider.credential(token))`. This is
**best-effort**: on failure the integration continues token-only and only an
error code is logged.

---

## 6. Connection lifecycle & UI states

`IntegrationBloc` exposes `IntegrationPhase`:

`unknown` → `disconnected` → `connecting` → `connected`
(with `expired` and `error` as recovery states)

State fields: `phase`, `prompt`, `connection`, `profile`, `repositories`,
`activities`, `contributions`, `isLoadingData`, `isRefreshing`, `failure`.

Notable behaviors:

- Refresh is deduplicated (`isBusy` guard) so repeated taps do not fan out.
- `AuthorizationExpired` while fetching moves the phase to `expired` **and**
  keeps the stored record, so the user can reconnect without losing context.
- Any screen can dispatch `IntegrationDataRefreshRequested` for retry.

### Where the integration surfaces

| Screen | Widget | Behavior |
| --- | --- | --- |
| Profile | `GithubConnectionCard` | Full state machine: disconnected CTA, connecting prompt, connected (avatar, repo/follower pills, last synced, Refresh, Disconnect w/ confirm), expired, error |
| Dashboard | `GithubConnectHeroCard` | Connected → `GithubConnectedBanner`; connecting → prompt; disconnected → CTA + terminal preview; expired/error → typed copy + retry |
| Dashboard | `StatsOverviewGrid` | Live counts from activities (PRs, issues solved, commits, reviews) with `—` when no data |
| Dashboard | `DashboardRepositoriesSection` | Hidden until connected; loading/empty/error states |
| Activity | `ActivityPage` + `GithubConnectCallout` | Filters (All/PRs/Issues/Commits/Reviews) over normalized feed |
| Contributions | `ContributionsPage` + `GithubConnectCallout` | Live calendar + stats from `ContributionSummary` |

### Loading / error / empty conventions

- `StatusMessageCard` is the single reusable loading/empty/error card, with an
  optional action button (used for retries).
- `SampleDataBanner` marks preview data; live data is labeled LIVE /
  LAST 12 MONTHS.
- No indeterminate spinners in always-visible states (they break
  `pumpAndSettle` and look unfinished); loading states use determinate or
  static placeholders.
- `ProviderAvatar` degrades to initials when the network image fails; it never
  shows a spinner.

---

## 7. Navigation

`go_router` with a responsive shell (`MainShell`): bottom navigation on phones,
extended rail on tablet/desktop widths. Routes:

- `/` splash (auth check)
- `/login`, sign-up
- `/home` with tabs `dashboard`, `activity`, `contributions`, `progress`,
  `profile`
- `/settings`

---

## 8. Theming

- `AppColors` exposes semantic, theme-resolved getters (dark navy base +
  vibrant accents; a full light variant with ≥4.5:1 contrast accents).
- `AppTheme` builds dark/light `ThemeData` from one brightness-aware builder.
- `ThemePreference` persists dark/light/system via `shared_preferences`.
- `AppTypography` (google_fonts) and `AppSpacing` tokens are used everywhere;
  no ad-hoc values in feature code.

---

## 9. Testing

- `flutter_test`, `bloc_test`, `mocktail`.
- `test/support/` holds `FakeDeveloperProvider` (call counters, gates for
  connect/fetch, injectable failures) and `InMemoryConnectionStore`.
- GitHub services are tested **offline** with `http`'s `MockClient`: mappers,
  API client error mapping, device flow (pending/slow_down/expired/denied),
  provider end-to-end, and token-free persistence assertions.
- Widget tests cover the connection card (including a 320 dp no-overflow
  regression), page states for Dashboard/Activity/Contributions, and the
  auth/theme suites from Phase 1.
- Current status: **270 tests passing** (Phase 1: 177).

Test-writing constraints worth remembering:

- `FlutterSecureStorage` platform calls never complete under widget-test fake
  async — `GitHubProvider.isConnected` uses the in-memory fallback so tests are
  deterministic.
- Avoid `pumpAndSettle` with indeterminate animations.
- Assert on `captured.single.body` for `http` requests (finalizing a request
  twice throws).

---

## 10. Security decisions

| Decision | Rationale |
| --- | --- |
| Device Authorization Flow | Only GitHub OAuth flow without a client secret in the client |
| Client id via `--dart-define` | Keeps identifiers out of source; public value only |
| `read:user` scope only | Minimum needed for profile, public events, public contributions |
| Token in `flutter_secure_storage` | Keystore-backed; never in prefs/logs |
| Non-secret `ProviderConnectionRecord` | UI can restore identity without the token |
| `failure_message.dart` hides `detail` | Prevents internal error text leaking to users |
| `.gitignore` additions | `google-services.json`, `GoogleService-Info.plist`, `.env*`, `*.jks`, `*.keystore`, `key.properties` |
| Disconnect clears token + record | Users can always sever the integration |

Outstanding (documented, not implemented): server-side token revocation and
backend-mediated token exchange are future backend work.

---

## 11. Dependencies added in Phase 2

| Package | Why |
| --- | --- |
| `http: ^1.2.2` | First-party Dart HTTP client for GitHub REST + GraphQL |
| `flutter_secure_storage: ^9.2.2` | Keystore-backed token storage (no plaintext) |
| `url_launcher: ^6.3.0` | Open the GitHub device verification page in the system browser |

No other dependencies were added; existing Phase 1 packages were reused.

---

## 12. Not implemented yet (by phase)

- **Phase 3:** XP, levels, streaks, achievements, quests, contribution health.
- **Phase 4:** AdMob, premium, advanced analytics.
- **Phase 5:** GitLab/Bitbucket/Jira/Linear providers, public profiles, teams.
- Notifications sync, background refresh, and Firestore caching of GitHub data
  are also future work; the current implementation fetches on demand.
