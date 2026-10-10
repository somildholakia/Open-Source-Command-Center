# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Open Source Developer Command Center — a mobile-first Flutter application that transforms open-source contribution activity into an actionable, gamified developer experience.

**Not a GitHub statistics dashboard.** This is a personal operating system for open-source developers with progress tracking, gamification (XP, levels, streaks, achievements, quests), and multi-platform integration.

Current Phase: **PHASE 1 — FOUNDATION** (architecture, theme/design system, navigation, responsive UI foundation, authentication UI, Firebase foundation)

## Essential Commands

### Development
```bash
# Run the app
flutter run

# Run on specific device
flutter run -d <device-id>

# Hot reload: press 'r' in terminal
# Hot restart: press 'R' in terminal

# Format code
flutter format .

# Static analysis
flutter analyze

# Run tests
flutter test

# Run specific test
flutter test test/path/to/test_file.dart

# Clean build artifacts
flutter clean
```

### Dependencies
```bash
# Install dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Check for outdated packages
flutter pub outdated
```

### Building
```bash
# Build APK (Android)
flutter build apk

# Build app bundle (Android)
flutter build appbundle

# Build for release
flutter build apk --release
```

## Architecture

### Current State
- Fresh Flutter project with only `lib/main.dart` (boilerplate counter app)
- No feature structure implemented yet
- Standard Flutter dependencies only (cupertino_icons, flutter_lints)

### Target Architecture Pattern
**Feature-based architecture** with clear separation of concerns:

```
lib/
  core/              # Shared infrastructure
    config/          # App configuration
    constants/       # App-wide constants
    errors/          # Error handling
    network/         # HTTP clients, API clients
    storage/         # Local storage abstractions
    theme/           # Design system, colors, typography
    utils/           # Utilities and helpers
    widgets/         # Reusable UI components

  features/          # Feature modules (create as needed)
    auth/            # Authentication
    dashboard/       # Home screen
    activity/        # Activity feed
    contributions/   # Contribution tracking
    gamification/    # XP, levels, streaks, achievements
    profile/         # User profile
    settings/        # App settings
    # ... others as needed

  services/          # External service integrations
    github/          # GitHub API integration
    firebase/        # Firebase services
    # ... others as needed
```

**Key Principles:**
- Create directories/files **only when needed** (don't scaffold everything upfront)
- Keep business logic separate from UI
- Use provider abstraction for multi-platform support (GitHub, GitLab, Bitbucket, Jira, Linear)
- Never hardcode secrets, API keys, or tokens

### State Management
Choose a predictable state-management solution and keep these concerns separated:
- UI state (form inputs, UI toggles)
- Application/business state (user data, contribution data)
- Network state (loading, error, success)

### Backend Strategy
Firebase-based backend (to be implemented):
- Firebase Authentication
- Firestore (data storage)
- Cloud Functions/Cloud Run (backend logic)
- Firebase Cloud Messaging (notifications)
- Firebase Analytics, Crashlytics

**Important:** GitHub remains the source of truth for GitHub data. Backend normalizes and caches provider data.

## Product Constraints

### Current Phase Restrictions
**DO NOT IMPLEMENT** until their respective phases:
- GitHub API synchronization (Phase 2)
- XP calculations, achievements, quests (Phase 3)
- AdMob, premium features (Phase 4)
- GitLab, Bitbucket, Jira, Linear (Phase 5)

Build incrementally. Focus on foundation work only.

### Design Direction
The UI must feel:
- Creative, playful, premium, game-like
- Dark/navy foundation with vibrant accents
- Pixel-art inspired with subtle animations
- Developer-focused, not corporate

**Avoid:**
- Generic admin dashboards
- Excessive tables or spreadsheet-like layouts
- Default Flutter-looking screens
- Copying other products' assets or exact UI

Take inspiration from the *feeling* of coding-game products, never their assets, characters, or branding.

### Mobile-First
- Primary target: **Android**
- Must work across different phone sizes
- Desktop/web support is secondary (useful for development only)
- Be mindful of lower-end device performance

### Security
- **Never store GitHub personal access tokens directly in Flutter client**
- Use secure authorization with minimum required permissions
- Never commit secrets to Git (API keys, passwords, OAuth secrets, credentials)
- Users must be able to disconnect integrations

## Development Workflow

For every feature:
1. Understand the requirement
2. Inspect existing code
3. Explain implementation approach
4. Implement the smallest correct change
5. Run `flutter format .`
6. Run `flutter analyze`
7. Run relevant tests
8. Fix any failures
9. Summarize what changed

### UI Development
- Use mock/local data early (don't block on backend)
- Keep API-dependent logic behind services/repositories
- Build reusable components instead of duplicating UI
- Handle loading, error, and empty states
- Use centralized theme tokens

### Git Practices
Keep commits small and meaningful. Use conventional commit style:
- `feat:` new feature
- `fix:` bug fix
- `refactor:` code restructuring
- `chore:` maintenance
- `docs:` documentation
- `test:` test changes

## Product Context

### Main Features (Eventually)
1. **Home** — What needs attention today, streaks, daily quests, recent activity
2. **Activity** — Chronological normalized feed (PRs, issues, commits, reviews, mentions)
3. **Contributions** — Commits, PRs, issues, reviews, contribution calendar/trends
4. **Progress** — XP, levels, streaks, achievements, badges, quests, contribution health
5. **Profile** — Avatar, username, connected providers, shareable profile

### GitHub Integration (Phase 2)
GitHub is the source of truth. Retrieve and normalize:
- Repositories, pull requests, issues, reviews, commits
- Notifications, requested reviews, mentions

### Gamification (Phase 3)
Reward **meaningful contribution**, not spam:
- Meaningful/merged PRs, useful reviews, resolved issues, helpful commits
- Do not implement until Phase 3

### Monetization (Phase 4)
- Free tier: core tracking, tasteful ads, basic insights
- Premium: no ads, advanced analytics, deeper history, advanced reports
- AdMob with test ads during development
- Do not implement until Phase 4

## Key Reference Documents

- **PRODUCT_SPEC.md** — Complete product vision and roadmap
- **AGENTS.md** — Engineering rules and architecture decisions
- **ARCHITECTURE.md** — (Empty, to be populated with implementation decisions)
- **DEVELOPMENT_PLAN.md** — (Empty, to be populated with development tasks)

## Known Issues

- `lib/main.dart:28` has a syntax error: `colorScheme: .fromSeed(...)` is missing `ColorScheme` prefix
