# Open Source Developer Command Center

A mobile-first Flutter app that turns open-source contribution into a personal developer adventure. Track GitHub activity, explore contribution history, and build momentum with locally calculated XP, levels, streaks, achievements, and quests.

## Product direction

- **Playful, colorful UI:** original cartoon-inspired visuals, warm accent colors, friendly progression feedback, and responsive layouts.
- **GitHub-connected:** authorized access to your profile, repositories, public activity, and contribution data.
- **Local-first:** preferences and progression live on the device; normalized GitHub snapshots are cached locally so the app can display last-known data offline and clearly label it as stale when refresh fails.
- **Privacy-aware:** GitHub credentials belong in device-secure storage, never in plain preferences or logs.
- **Mobile-first and responsive:** designed for compact Android phones first, with adaptive layouts for larger screens.

## Current features

- Firebase email/password authentication.
- Dark, light, and system appearance modes.
- GitHub Device Authorization Flow integration.
- Dashboard, Activity, Contributions, Progress, Profile, and Settings screens.
- Local progression engine for XP, levels, streaks, achievements, and quests.
- Responsive Flutter component and theme foundations.

Some integration features require external setup. The GitHub connection requires a GitHub OAuth App with Device Flow enabled. See [GitHub setup](docs/GITHUB_SETUP.md).

## Local development

Requirements: Flutter SDK compatible with the Dart constraint in `pubspec.yaml`, Android SDK/emulator for Android builds, and Git.

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

For GitHub authorization, pass the OAuth App client ID at build/run time:

```bash
flutter run --dart-define=GITHUB_OAUTH_CLIENT_ID=YOUR_CLIENT_ID
```

Do not commit OAuth secrets, Firebase private configuration, signing keys, or access tokens. Follow the repository's ignored-file rules and the setup guide.

## Architecture and plans

- [Product specification](PRODUCT_SPEC.md)
- [Architecture](ARCHITECTURE.md)
- [Development plan](DEVELOPMENT_PLAN.md)
- [GitHub integration setup](docs/GITHUB_SETUP.md)
- [Cartoon redesign and local-first architecture](docs/LOCAL_FIRST_CARTOON_DESIGN.md)

## Local-first promise and limitations

Core personal state should not require a paid app-owned database or custom server. GitHub data still requires internet access to refresh, and Firebase Authentication remains an external identity service in the current architecture. The app should show cached last-known data when possible and communicate clearly when it is stale.

## Project status

Active development. Changes are being made on feature branches and should be reviewed and tested before merging into `main`.
