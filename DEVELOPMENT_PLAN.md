# Development Plan — Phase 1: Foundation

**Started:** 2026-09-05  
**Phase:** Foundation  
**Status:** Planning

## Phase 1 Objectives

Build the architectural foundation for a production-quality, mobile-first Flutter application:
- Establish project structure and architecture patterns
- Create a cohesive, game-like design system
- Implement responsive navigation shell
- Build authentication UI (without backend integration yet)
- Set up Firebase infrastructure (Auth, Firestore, Analytics, Crashlytics)
- Create foundational screens (Profile, Settings)
- Establish patterns for loading, error, and empty states
- Set up testing infrastructure

**What we are NOT building in Phase 1:**
- GitHub API integration/synchronization
- XP, levels, achievements, quests, gamification logic
- AdMob or monetization
- Multi-provider support (GitLab, Bitbucket, Jira, Linear)
- Real data fetching or backend business logic

---

## Implementation Order

### Stage 1: Core Architecture (Days 1-2)

#### 1.1 Project Structure Setup
Create the feature-based directory structure:

```
lib/
  core/
    config/
      app_config.dart          # App-wide configuration
    constants/
      app_constants.dart       # Constants (URLs, limits, etc.)
    theme/
      app_theme.dart           # Theme configuration
      colors.dart              # Color palette
      typography.dart          # Text styles
      spacing.dart             # Spacing scale
      animations.dart          # Animation constants
    widgets/
      [empty initially]        # Shared widgets go here as needed
    utils/
      [empty initially]        # Utilities as needed
  
  features/
    auth/
      presentation/
        pages/
          splash_page.dart
          login_page.dart
        widgets/
          [auth-specific widgets]
    
    dashboard/
      presentation/
        pages/
          dashboard_page.dart  # Main home screen
        widgets/
          [dashboard widgets]
    
    profile/
      presentation/
        pages/
          profile_page.dart
        widgets/
          [profile widgets]
    
    settings/
      presentation/
        pages/
          settings_page.dart
        widgets/
          [settings widgets]
  
  services/
    firebase/
      firebase_service.dart    # Firebase initialization
      auth_service.dart        # Firebase Auth wrapper
      analytics_service.dart   # Firebase Analytics wrapper
      crashlytics_service.dart # Crashlytics wrapper
  
  app.dart                     # Root app widget
  main.dart                    # Entry point
```

**Create only what we need, when we need it.** Don't create empty files prematurely.

#### 1.2 Dependencies
Add to `pubspec.yaml`:

```yaml
dependencies:
  # State Management
  flutter_bloc: ^8.1.6           # or provider/riverpod - choose one
  equatable: ^2.0.5               # Value equality
  
  # Firebase
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.4
  firebase_analytics: ^11.3.3
  firebase_crashlytics: ^4.1.3
  
  # Navigation
  go_router: ^14.6.1
  
  # UI/Design
  google_fonts: ^6.2.1           # Custom typography
  flutter_svg: ^2.0.10+1         # SVG support for icons/illustrations
  shimmer: ^3.0.0                # Loading state animations
  
  # Utilities
  shared_preferences: ^2.3.2     # Local storage
  intl: ^0.19.0                  # Date formatting

dev_dependencies:
  flutter_lints: ^6.0.0
  bloc_test: ^9.1.7              # If using flutter_bloc
  mocktail: ^1.0.4               # Mocking for tests
```

**Decision Point:** Choose state management (flutter_bloc recommended for scalability, but provider or riverpod also acceptable). Document the choice.

---

### Stage 2: Design System (Days 2-4)

#### 2.1 Color Palette
Create `lib/core/theme/colors.dart`:

Define a dark/navy foundation with vibrant game-like accents:
- Primary: Vibrant accent color (blue, purple, or cyan)
- Secondary: Complementary vibrant accent
- Background: Dark navy (#0A0E27 range)
- Surface: Slightly lighter navy
- Error, Warning, Success, Info states
- Text colors (high contrast for accessibility)
- Gradient definitions for premium feel

#### 2.2 Typography
Create `lib/core/theme/typography.dart`:

- Playful but readable font hierarchy
- Use Google Fonts for custom typography
- Heading styles (H1-H6)
- Body text styles (body1, body2)
- Caption/label styles
- Button text styles
- Ensure readability across phone sizes

#### 2.3 Spacing & Layout
Create `lib/core/theme/spacing.dart`:

- Consistent spacing scale (4px, 8px, 16px, 24px, 32px, 48px, 64px)
- Responsive breakpoints (though mobile-first)
- Padding/margin constants
- Border radius scale

#### 2.4 Animation Constants
Create `lib/core/theme/animations.dart`:

- Duration constants (fast: 150ms, normal: 300ms, slow: 500ms)
- Curve definitions (playful easing)
- Transition configurations
- Keep animations subtle and performant

#### 2.5 Theme Assembly
Create `lib/core/theme/app_theme.dart`:

Assemble into `ThemeData`:
- Dark theme as primary (light theme optional for Phase 1)
- Material 3 design system
- Consistent component theming (buttons, cards, inputs, etc.)
- App bar styling
- Bottom navigation styling
- Floating action button styling

---

### Stage 3: Navigation Shell (Days 4-5)

#### 3.1 Navigation Structure
Create navigation with `go_router`:

Routes:
- `/` → Splash (checks auth state)
- `/login` → Login page
- `/home` → Dashboard (main app shell)
  - `/home/dashboard` → Dashboard/Home tab
  - `/home/activity` → Activity tab (placeholder)
  - `/home/contributions` → Contributions tab (placeholder)
  - `/home/progress` → Progress tab (placeholder)
  - `/home/profile` → Profile tab
- `/settings` → Settings page

#### 3.2 Bottom Navigation
Create main app shell with bottom navigation (5 tabs):
1. Home (dashboard icon)
2. Activity (list/feed icon)
3. Contributions (chart/graph icon)
4. Progress (trophy/star icon)
5. Profile (user icon)

Design considerations:
- Custom icon design (pixel-art influenced or SVG)
- Active/inactive states with vibrant colors
- Smooth tab transitions
- Proper state preservation across tabs

#### 3.3 Responsive Layout
- Test across different Android phone sizes
- Handle notches/safe areas properly
- Ensure touch targets are adequate (min 48px)
- Keyboard handling for forms

---

### Stage 4: Firebase Foundation (Days 5-6) — ✅ COMPLETED (2026-09-06)

- **Firebase project:** Configured
- **Android app:** Registered in Firebase
- **Configuration file:** `google-services.json` present in `android/app/`
- **Gradle:** Google Services plugin configured in `android/settings.gradle.kts` and `android/app/build.gradle.kts`
- **Implementation:** Created `FirebaseService`, `AuthService`, `AnalyticsService`, `CrashlyticsService` wrappers in `lib/services/firebase/`, and `AppConfig` in `lib/core/config/`. Firebase initialized on app startup in `main.dart`.

**Verification (2026-09-06):**
- `flutter analyze` — passes
- `flutter test` — passes (36 tests)
- `flutter build apk --debug` — succeeds

---

#### 4.1 Firebase Project Setup
1. Create Firebase project in console
2. Add Android app (package name: com.example.opensource_command_center or appropriate)
3. Download `google-services.json` → `android/app/`
4. Configure `android/build.gradle` and `android/app/build.gradle`
5. **DO NOT commit google-services.json if it contains sensitive data** (add to .gitignore if needed)

#### 4.2 Firebase Services
Create service wrappers:

`lib/services/firebase/firebase_service.dart`:
- Initialize Firebase
- Handle initialization errors
- Singleton pattern

`lib/services/firebase/auth_service.dart`:
- Auth state stream
- Sign-in methods (email/password, Google, GitHub OAuth)
- Sign-out
- User state management
- Error handling

`lib/services/firebase/analytics_service.dart`:
- Log screen views
- Log custom events
- User properties
- Wrapper for Firebase Analytics

`lib/services/firebase/crashlytics_service.dart`:
- Initialize Crashlytics
- Log errors
- Set user identifiers
- Custom keys for debugging

#### 4.3 Environment Configuration
Create `lib/core/config/app_config.dart`:
- Environment detection (dev, staging, prod)
- Firebase configuration per environment
- Feature flags (if needed)
- Debug settings

---

### Stage 5: Authentication UI & Firebase Authentication (Task 1.7) (Days 6-8) — ✅ COMPLETED (2026-09-06)

- **AuthBloc & AuthService Integration:** Connected `AuthBloc` directly to `AuthService` via constructor dependency injection.
- **Firebase SDK Boundary:** Firebase SDK types (`FirebaseAuth`, `User`, `FirebaseAuthException`) remain encapsulated beneath `AuthService`; mapped to domain `UserModel`, `AuthErrorType`, and `AuthFailure`.
- **Session Persistence:** Implemented `AuthCheckRequested` using `_authService.currentUser` so persisted Firebase sessions are restored on app launch.
- **Email/Password Auth:** Real email/password registration (`AuthSignUpRequested`) and sign-in (`AuthSignInRequested`) with client-side validation and friendly error handling.
- **Testing:** Added `mocktail: ^1.0.4` dev-dependency; isolated all unit and widget tests with `MockAuthService` (44/44 tests passing).

**Verification (2026-09-06):**
- `flutter analyze` — passes (0 issues)
- `flutter test` — passes (44/44 tests)
- **Manual verification performed on Android emulator:**
  - Created a real Firebase Email/Password account.
  - Successfully authenticated.
  - Stopped the Flutter app.
  - Relaunched the app.
  - The authenticated session persisted and the app remained logged in.

#### 5.1 Splash Screen
Create `lib/features/auth/presentation/pages/splash_page.dart`:
- App logo/branding
- Loading indicator
- Check auth state
- Navigate to login or dashboard
- Handle initialization errors

#### 5.2 Login Page
Create `lib/features/auth/presentation/pages/login_page.dart`:

UI Components:
- App branding at top
- Email/password form
- "Sign In" button
- "Sign Up" button/link
- Social auth buttons (Google, GitHub)
- Loading state
- Error state (display auth errors)
- Form validation

Design:
- Game-like, playful design
- Vibrant accent colors
- Smooth transitions
- Clear call-to-action buttons

**Note:** Wire up to Firebase Auth. OAuth for GitHub/Google requires:
- Firebase Console configuration
- OAuth client setup
- Redirect URIs configured
- Test with Firebase Auth test accounts

#### 5.3 Sign-Up Flow
Create sign-up page or modal:
- Email/password registration
- Form validation (email format, password strength)
- Terms of service acceptance (placeholder)
- Loading/error states
- Success → navigate to dashboard

#### 5.4 State Management for Auth
Create auth state management:
- Auth state (authenticated, unauthenticated, loading)
- User model (uid, email, displayName, photoURL)
- Handle auth errors
- Persist auth state

---

### Stage 6: Core Screens (Days 8-11)

#### 6.1 Dashboard/Home Screen — ✅ COMPLETED (2026-09-07)

- **Dashboard UI:** Dashboard UI was implemented adhering to the design system.
- **Dynamic Greeting:** Dynamic Firebase-authenticated greeting was verified.
- **Responsive Sections:** Responsive dashboard sections were implemented.
- **GitHub CTA:** GitHub CTA remains presentation-only and Phase 2.

**Verification (2026-09-07):**
- `flutter analyze` — 0 issues
- `flutter test` — 48/48 passed
- **Manual Verification:** Dashboard was manually launched and visually verified on the Android emulator.

**Implementation Details:**
- Greeting header ("Hello, Developer!" / dynamic user greeting)
- Empty state message: "Connect your GitHub account to get started" (non-functional)
- Placeholder cards for:
  - "Today's Activity" (empty state)
  - "Current Streak" (shows 0 or mock data)
  - "Daily Quest" (locked/coming soon)
- Consistent design system tokens and responsive layout
- Kept GitHub API synchronization, XP/streak calculation, and functional quests out of scope (deferred to subsequent phases)

#### 6.2 Activity Screen — ✅ COMPLETED (2026-09-07)

- **Activity Timeline UI:** Fully implemented with timeline visual language.
- **Responsive Timeline and Activity Cards:** `ActivityItem` widget with timeline connector (dot + vertical line), type badge, title, subtitle, repository name (monospace), identifier, and timestamp. `ResponsiveContainer` used throughout.
- **Multiple Activity Types Visually Represented:** 10 `ActivityType` enum variants (pullRequestOpened, pullRequestMerged, pullRequestClosed, pullRequestReviewed, issueOpened, issueClosed, issueCommented, commitPushed, reviewRequested, mentionReceived), each with distinct icon, label, and color.
- **Phase 2 GitHub Synchronization:** Remains out of scope. Activity data is presentation-only mock data. No GitHub API calls, OAuth, or real sync.

**Verification (2026-09-07):**
- `flutter analyze` — 0 issues
- `flutter test` — 98/98 tests passed
- **Manual Verification:** Activity screen was manually launched and visually verified on the Android emulator, including scrolling through the timeline.

**Implementation Details:**
- `ActivityPage` with `AppBar`, `SafeArea`, `ResponsiveContainer`, `SingleChildScrollView`
- `ActivityHeader` with "Activity Timeline" title, "LIVE FEED" badge, description, and presentation-only filter chips (All, PRs, Issues, Commits, Reviews)
- `ActivityTimelinePlaceholder` with 10 mock `ActivityItemData` entries covering all activity types, timeline connectors, and "All caught up!" end-of-timeline indicator
- `ActivityTypeBadge` rendering colored icon containers for each activity type
- `ActivityEmptyState` with Phase 2 messaging, feature preview list, and schedule badge
- Static human-readable timestamps (no `intl` package): "2 hours ago", "Yesterday", "2 days ago", etc.
- All existing design system tokens reused (`AppColors`, `AppTypography`, `AppSpacing`, `ResponsiveContainer`, `ResponsiveBuilder`)
- No new dependencies added

#### 6.3 Contributions Screen — ✅ COMPLETED (2026-09-07)
- `lib/features/contributions/presentation/pages/contributions_page.dart` — full screen with `AppBar`, `SingleChildScrollView`, `ResponsiveContainer`
- `lib/features/contributions/presentation/widgets/contributions_header.dart` — title, ANALYTICS badge, SAMPLE DATA label, filter chips
- `lib/features/contributions/presentation/widgets/contributions_stat_card.dart` — color-coded metric cards (PRs, Issues, Commits, Reviews)
- `lib/features/contributions/presentation/widgets/contributions_calendar.dart` — 7×4 heatmap grid with 5-level color scale
- `lib/features/contributions/presentation/widgets/contributions_empty_state.dart` — meaningful not-connected state with Phase 2 indicator
- `lib/features/contributions/presentation/widgets/contributions_overview.dart` — stat cards + heatmap combined
- 6 test files created (header, stat card, calendar, empty state, overview, page)
- All mock data clearly labeled "SAMPLE DATA" / "SAMPLE"; no fake toggle; single consistent state

#### 6.4 Progress (Placeholder)
Create `lib/features/progress/presentation/pages/progress_page.dart`:
- Empty state: "Your progress tracking will appear here"
- Locked/coming soon badges for achievements
- Placeholder XP bar (shows 0 / 100)

#### 6.5 Profile Screen
Create `lib/features/profile/presentation/pages/profile_page.dart`:

UI Components:
- User avatar (from Firebase Auth or default)
- Display name
- Email
- "Connected Providers" section (empty or "None connected")
- Navigation to Settings
- Sign Out button
- Edit profile button (opens basic form)

#### 6.6 Settings Screen — ✅ COMPLETED (2026-10-01)

- **Appearance:** Functional Dark / Light / System theme selection with
  `shared_preferences` persistence (`ThemePreference`), integrated with the
  theme-resolved color token system.
- **Account:** Real authenticated user information (name, email, member
  since) from `AuthBloc`.
- **Notifications:** Visually complete presentation with disabled switches
  and a clear "arrives in Phase 2" marker (no fake functionality).
- **Privacy:** Presentation-only content describing OAuth authorization and
  integration management (GitHub connect/disconnect is Phase 2).
- **About:** App name, version (1.0.0), environment label, and project
  description.
- **Sign Out:** Functional via `AuthBloc`; navigation returns to `/login`
  through `go_router`.
- **Light Theme:** Completed as an intentional light visual system —
  semantic theme-resolved tokens (`AppColors` getters), deepened accent
  variants for readability (all ≥4.5:1 contrast on light surfaces), a single
  brightness-aware component theme builder, and light variants for the
  contribution heatmap. Dark theme is visually unchanged.

**Verification (2026-10-01):**
- `dart format` — clean
- `flutter analyze` — 0 issues
- `flutter test` — 177/177 passed (includes new theme token, AppTheme,
  settings, and app-level light-mode test suites)

Settings Categories:
- **Account:** Email, password change (Firebase Auth) — display implemented;
  password change deferred
- **Integrations:** "Connect GitHub" (placeholder, non-functional)
- **Notifications:** Toggle switches (store in local preferences, no backend)
- **Appearance:** Theme toggle (Dark / Light / System) — implemented with
  persistence
- **About:** App version, terms of service, privacy policy (placeholder links)
- **Sign Out**

---

### Stage 7: Shared Widgets & Patterns (Days 11-13)

#### 7.1 Loading States
Create `lib/core/widgets/loading_indicator.dart`:
- Branded loading spinner (custom animation or shimmer)
- Skeleton loaders for cards/lists
- Full-screen loading overlay

#### 7.2 Error States
Create `lib/core/widgets/error_view.dart`:
- Error illustration or icon
- Error message
- Retry button
- Generic error vs specific error handling
- Playful error messages that fit brand

#### 7.3 Empty States
Create `lib/core/widgets/empty_state.dart`:
- Illustration or icon
- Message (contextual to feature)
- Call-to-action button (if applicable)
- Consistent design across features

#### 7.4 Common Widgets
As needed, create:
- `custom_button.dart` - Branded buttons (primary, secondary, outline)
- `custom_card.dart` - Branded cards with consistent styling
- `custom_text_field.dart` - Branded form inputs
- `app_bar_widget.dart` - Consistent app bar styling
- `avatar_widget.dart` - User avatar with placeholder

#### 7.5 Responsive Utilities
Create `lib/core/utils/responsive_helper.dart`:
- Screen size helpers
- Responsive padding/margin helpers
- Breakpoint utilities

---

### Stage 8: Testing Infrastructure (Days 13-14)

#### 8.1 Unit Tests
Set up unit testing:
- Test services (auth_service, firebase_service)
- Test utilities
- Test models/data classes
- Mock Firebase dependencies with mocktail

Create example tests:
- `test/services/firebase/auth_service_test.dart`
- `test/core/utils/responsive_helper_test.dart`

#### 8.2 Widget Tests
Set up widget testing:
- Test core widgets (buttons, cards, loading, error, empty states)
- Test navigation flow
- Test form validation

Create example tests:
- `test/core/widgets/custom_button_test.dart`
- `test/features/auth/presentation/pages/login_page_test.dart`

#### 8.3 Integration Tests (Optional for Phase 1)
If time permits:
- Test auth flow end-to-end
- Test navigation between screens
- Create `integration_test/` directory

#### 8.4 Test Coverage
- Aim for >70% coverage on core utilities and services
- Widget tests for all reusable components
- Document testing patterns in comments

---

### Stage 9: Polish & Documentation (Days 14-15)

#### 9.1 Code Quality
- Run `flutter analyze` and fix all issues
- Run `flutter format .`
- Remove unused imports
- Add documentation comments to public APIs
- Ensure consistent naming conventions

#### 9.2 Performance Review
- Profile app startup time
- Check for unnecessary rebuilds
- Optimize image assets (if any added)
- Test on lower-end Android device or emulator

#### 9.3 Accessibility
- Semantic labels for interactive elements
- Color contrast checks (use online tools)
- Screen reader testing (TalkBack on Android)
- Ensure 48px minimum touch targets

#### 9.4 Documentation Updates
Update `ARCHITECTURE.md` with:
- Finalized directory structure
- State management choice and rationale
- Navigation patterns
- Firebase service patterns
- Testing patterns
- Dependencies and why they were chosen

Update `DEVELOPMENT_PLAN.md`:
- Mark Phase 1 tasks as complete
- Document any deviations from plan
- Note technical decisions made
- Prepare Phase 2 outline

#### 9.5 Git Hygiene
- Review all commits
- Ensure no secrets committed
- Clean commit history (squash if needed)
- Tag Phase 1 completion: `git tag v0.1.0-phase1`

---

## Dependencies Summary

### Production Dependencies
```yaml
flutter_bloc: ^8.1.6          # State management (or provider/riverpod)
equatable: ^2.0.5             # Value equality for state
firebase_core: ^3.6.0         # Firebase initialization
firebase_auth: ^5.3.1         # Authentication
cloud_firestore: ^5.4.4       # Database (foundation only)
firebase_analytics: ^11.3.3   # Analytics
firebase_crashlytics: ^4.1.3  # Crash reporting
go_router: ^14.6.1            # Navigation
google_fonts: ^6.2.1          # Typography
flutter_svg: ^2.0.10+1        # SVG icons
shimmer: ^3.0.0               # Loading animations
shared_preferences: ^2.3.2    # Local settings
intl: ^0.19.0                 # Date/time formatting
cupertino_icons: ^1.0.8       # Already included
```

### Dev Dependencies
```yaml
flutter_test: sdk: flutter    # Already included
flutter_lints: ^6.0.0         # Already included
bloc_test: ^9.1.7             # BLoC testing (if using flutter_bloc)
mocktail: ^1.0.4              # Mocking
```

### Why These Dependencies?
- **flutter_bloc:** Scalable state management, good for complex apps, testable
- **firebase_*:** Backend infrastructure, auth, analytics, crash reporting
- **go_router:** Declarative routing, deep linking support, type-safe navigation
- **google_fonts:** Custom typography without bundling fonts
- **flutter_svg:** Scalable icons and illustrations
- **shimmer:** Professional loading states
- **shared_preferences:** Simple key-value storage for settings
- **intl:** Date formatting for activity feeds (future use)

---

## Success Criteria for Phase 1

### Functional Requirements
✅ App launches without errors  
✅ User can sign up with email/password  
✅ User can sign in with email/password  
✅ User can sign out  
✅ Navigation works between all 5 main tabs  
✅ Settings can be changed and persisted locally  
✅ Firebase Analytics logs screen views  
✅ Firebase Crashlytics captures errors  
✅ All placeholder screens render correctly  
✅ Loading, error, and empty states work  

### Technical Requirements
✅ Feature-based architecture implemented  
✅ Design system is complete and applied consistently  
✅ Theme is game-like, playful, dark/navy with vibrant accents  
✅ Responsive across different phone sizes  
✅ No hardcoded secrets or credentials  
✅ `flutter analyze` passes with no issues  
✅ Core utilities and services have unit tests  
✅ Reusable widgets have widget tests  
✅ Code is formatted and documented  

### Design Requirements
✅ Feels creative, playful, premium, game-like  
✅ Does NOT look like generic admin dashboard  
✅ Consistent visual language across all screens  
✅ Smooth animations and transitions  
✅ Clear visual hierarchy  
✅ High contrast text (accessible)  

### Documentation Requirements
✅ ARCHITECTURE.md populated with implementation details  
✅ DEVELOPMENT_PLAN.md updated with decisions made  
✅ README.md updated with setup instructions  
✅ Code comments for non-obvious logic  

---

## Risk Assessment

### Technical Risks
1. **State management complexity:** Mitigate by choosing proven solution (flutter_bloc recommended)
2. **Firebase configuration:** Test early, use test accounts, document setup steps
3. **Design system execution:** Iterate quickly, get early visual feedback, use design tools for color validation
4. **OAuth integration:** GitHub/Google OAuth can be tricky; test thoroughly, handle errors gracefully

### Scope Risks
1. **Feature creep:** Strictly follow "DO NOT implement" list
2. **Over-engineering:** Build only what's needed for Phase 1
3. **Design perfectionism:** Aim for good, not perfect; iterate in later phases

### Timeline Risks
- Estimated: 14-15 days
- Buffer: Add 3-5 days for unknowns
- **Total Phase 1:** ~3 weeks

---

## Phase 1 Deliverables

1. ✅ Feature-based architecture implemented
2. ✅ Design system (colors, typography, spacing, animations, theme)
3. ✅ Navigation shell with 5 tabs
4. ✅ Firebase integrated (Auth, Firestore, Analytics, Crashlytics)
5. ✅ Authentication flow (splash, login, sign-up, sign-out)
6. ✅ Dashboard screen (placeholder with empty states)
7. ✅ Activity screen (fully implemented — timeline, activity cards, empty state, header with filter chips)
8. ✅ Contributions screen (placeholder)
9. ✅ Progress screen (placeholder)
10. ✅ Profile screen (functional)
11. ✅ Settings screen (functional with local persistence)
12. ✅ Shared widgets (loading, error, empty states, buttons, cards)
13. ✅ Unit tests for services and utilities
14. ✅ Widget tests for core components
15. ✅ Documentation (ARCHITECTURE.md, updated DEVELOPMENT_PLAN.md, README.md)

---

## After Phase 1: Next Steps

Phase 1 prepares the foundation for Phase 2: GitHub Integration.

Phase 2 will include:
- GitHub API client
- OAuth flow for GitHub
- Repository syncing
- Pull request tracking
- Issue tracking
- Activity feed with real data
- Notification handling

**Do not begin Phase 2 until Phase 1 is complete and reviewed.**

---

## FIRST IMPLEMENTATION TASK

**Task 1.1: Add Dependencies and Project Structure**

1. Update `pubspec.yaml` with all required dependencies
2. Run `flutter pub get`
3. Create base directory structure:
   - `lib/core/config/`
   - `lib/core/theme/`
   - `lib/core/widgets/`
   - `lib/services/firebase/`
   - `lib/features/auth/presentation/pages/`
4. Create placeholder files (empty or minimal):
   - `lib/core/config/app_config.dart`
   - `lib/core/theme/colors.dart`
   - `lib/core/theme/typography.dart`
   - `lib/core/theme/spacing.dart`
   - `lib/core/theme/animations.dart`
   - `lib/core/theme/app_theme.dart`
5. Run `flutter analyze` to ensure no issues
6. Commit: `chore: add dependencies and project structure for Phase 1`

**Estimated Time:** 1-2 hours

**Success Criteria:**
- All dependencies install without conflicts
- Project structure is created
- Placeholder files exist
- `flutter analyze` passes
- App still builds and runs (even if unchanged from boilerplate)

**Next Task After 1.1:** Begin implementing the color palette in `colors.dart`

---

**END OF PHASE 1 PLAN**

---

# Phase 2 — GitHub Integration

**Started:** 2026-10-02
**Status:** Implementation complete — verification in progress (see verification log below)

## Phase 2 Objectives

Connect the app to GitHub securely, normalize provider data into domain entities,
and wire real data into the existing screens — without adding gamification or
monetization (those stay in later phases).

## Completed Work

### 1. Provider abstraction (`lib/domain/`)
- `DeveloperProvider` interface (connect/cancel/disconnect/fetchProfile/
  fetchRepositories/fetchActivity/fetchContributions) so future providers
  (GitLab, Bitbucket, Jira, Linear) do not require rewriting the app.
- Domain entities: `DeveloperProfile`, `ConnectedAccount`, `Repository`,
  `DeveloperActivity` (12 activity types), `ContributionSummary`,
  `ProviderConnectionRecord`.
- Sealed `ProviderFailure` hierarchy for typed error handling.

### 2. Secure GitHub authorization
- **OAuth Device Authorization Flow** — the only GitHub OAuth flow that
  requires no client secret in the client.
- Public client id supplied at build time:
  `--dart-define=GITHUB_OAUTH_CLIENT_ID=...` (`GitHubConfig`).
- Scope: `read:user` only (minimum required).
- Token stored only in `flutter_secure_storage` (Android Keystore); never in
  SharedPreferences, logs, analytics, or source.
- Non-secret connection record persisted in SharedPreferences so the UI can
  restore identity without the token.
- Optional best-effort Firebase identity linking via
  `GithubAuthProvider.credential` + `linkWithCredential`; failure degrades to
  token-only integration.
- Setup guide: `docs/GITHUB_SETUP.md`.

### 3. GitHub API implementation
- `GitHubApiClient`: REST `/user`, `/user/repos`, `/users/{login}/events/public`
  plus GraphQL `contributionsCollection`; 20 s timeout.
- Typed mapping of HTTP failures: 401 → AuthorizationExpired, 403 →
  RateLimited/PermissionDenied (x-ratelimit-remaining), 404 →
  ProviderNotConnected, 422 → PermissionDenied, 5xx → ApiUnavailable,
  timeouts → NetworkUnavailable.
- `github_mappers.dart` normalizes events; unsupported event types are dropped.
- `GitHubDeviceFlowClient` handles `authorization_pending`, `slow_down`
  (backoff), `expired_token`, `access_denied`, `incorrect_device_code`.

### 4. Integration state (`lib/features/integrations/`)
- `IntegrationBloc` with phases `unknown → disconnected → connecting →
  connected` (plus `expired`, `error`) and explicit loading/refresh/failure
  state; refresh dedupe; reconnect-on-expiry that keeps the connection record.
- Widgets: `GithubConnectionCard` (Profile, full state machine),
  `GithubConnectedBanner` (Dashboard), `GithubConnectCallout`
  (Activity/Contributions), `GithubAuthorizationPromptCard` (device code).

### 5. Screen integration
- **Profile:** static "Connected Accounts" card replaced by the live
  `GithubConnectionCard` (connect / connecting / connected / expired / error,
  disconnect with confirmation).
- **Dashboard:** hero card rewritten state-driven; stats grid shows live counts
  (PRs, issues solved, commits, reviews) with `—` when no data; new
  repositories section (hidden until connected).
- **Activity:** functional filter chips (All/PRs/Issues/Commits/Reviews) over
  the normalized feed; disconnected/connecting/loading/error/empty/filtered-
  empty states; 4 new activity types (repositoryCreated, repositoryForked,
  releasePublished, starred).
- **Contributions:** live calendar built from `ContributionSummary`
  (Monday-first, zero-filled weeks, SAMPLE/LIVE labels) and live stats
  (Contributions / Active Days / Best Day / Avg per active day).

### 6. Shared building blocks
- `core/widgets/status_message_card.dart` — reusable loading/empty/error card
  with optional retry action.
- `core/widgets/provider_avatar.dart` — network avatar with initials fallback.
- `core/widgets/sample_data_banner.dart` — preview-data marker.
- `core/utils/time_ago.dart` — human-readable relative timestamps.
- `features/repositories/` — shared repository list/card widgets.

## Verification Log (Phase 2)

| Check | Result |
| --- | --- |
| `dart format lib test` | Clean (130 files checked) |
| `flutter analyze` | No issues found |
| `flutter test` | 270/270 passed (Phase 1 baseline: 177) |
| `flutter build apk --debug` | See final Phase 2 report |

Tests added in Phase 2: mappers (14), API client (15), device flow (10),
provider end-to-end offline (10), connection/token store, IntegrationBloc (14),
failure messages, connection card (incl. 320 dp overflow regression),
Dashboard/Activity/Contributions page suites, time_ago, contribution day data,
activity mapping. Test support: `FakeDeveloperProvider`,
`InMemoryConnectionStore`.

## External Configuration Still Required (not code)

1. Create a GitHub OAuth App with **Device Flow enabled**; copy its client id.
2. Build/run with `--dart-define=GITHUB_OAUTH_CLIENT_ID=<client id>`.
3. Optional: enable the GitHub provider in Firebase Console (Authentication →
   Sign-in method) to link GitHub identity to the Firebase user. The client
   secret is entered only in the Firebase Console, never in the app.
4. Keep `android/app/google-services.json` local (gitignored).

Without step 1–2 the app runs correctly and shows a clear typed error when
connecting; all other flows (sign-in, disconnect, sample previews) work.

## Not Implemented in Phase 2 (intentionally deferred)

- XP, levels, streaks, achievements, quests, contribution health (Phase 3)
- AdMob / premium (Phase 4)
- GitLab, Bitbucket, Jira, Linear (Phase 5)
- Background/periodic sync, Firestore caching of GitHub data, push
  notifications — future backend work
- Server-side token revocation — requires a backend

## Next Milestone

**Phase 3 — Gamification & Analytics** (per PRODUCT_SPEC.md):
XP calculations, levels, streaks, achievements, badges, daily/weekly quests,
contribution health score, milestones, and progress statistics — built on the
normalized activity/contribution data introduced in Phase 2.
