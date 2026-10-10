# Cartoon UI and Local-First Architecture

**Status:** Active implementation plan  
**Branch:** `feature/cartoon-local-first-redesign`

## Product direction

Open Source Developer Command Center should feel like a friendly, colorful contribution adventure rather than a generic AI dashboard or collaboration tool.

### Visual system

- Keep the existing Flutter design-token system and theme support.
- Use warm coral, sunny yellow, mint/teal, lilac, and sky-blue accents against accessible neutral surfaces.
- Use rounded, tactile cards with clear borders and restrained shadows; avoid excessive blur, glassmorphism, and gradients on every surface.
- Create original cartoon characters and decorative details from native Flutter drawing/widgets first. Prefer small SVG/vector assets when illustration complexity justifies them.
- Make the dashboard the first reference implementation, then migrate Activity, Contributions, Progress, Profile, Settings, and authentication in the same visual language.
- Preserve light/dark/system modes and verify readable text contrast in each.
- Motion should be purposeful and short. Honor platform reduced-motion preferences; never animate large areas continuously.

## Responsive layout rules

- Support narrow Android devices from 320 logical pixels without horizontal overflow.
- Use wrapping layouts for chips/actions and adaptive grids based on available width, not device labels alone.
- Use safe areas, scrollable content, minimum 48dp touch targets, and text scaling that does not clip.
- Avoid fixed heights for text-bearing cards. Keep large illustrations decorative and allow them to shrink/hide at narrow widths.
- Validate compact phone, regular phone, tablet, landscape, and large text scale in widget tests.

## Performance rules

- Prefer native Flutter widgets and vector/cartoon painting over a real-time 3D engine.
- Avoid adding large image/font/animation packages unless a measured need exists.
- Use lazy lists for long timelines/repositories and bounded caches for derived data.
- Keep BLoC rebuilds scoped with `buildWhen`/selectors; do not recalculate contribution history in every build.
- Add no unbounded polling. Sync on explicit refresh, app resume where appropriate, and user-authorized intervals.
- Keep animations short and avoid shader-heavy effects on low-end devices.
- Measure startup, frame jank, memory and scroll performance on a modest Android device before calling performance work complete.

## Local-first data policy

The app should remain useful when offline and should not require a paid application server or paid database for its core personal experience.

| Data | Source of truth | Local behavior |
| --- | --- | --- |
| Theme, preferences | Device | Persist locally |
| GitHub OAuth token | GitHub authorization + device | Keep in secure storage; never write to logs or ordinary preferences |
| Connected account metadata | Device | Persist locally; clear on disconnect |
| Repositories, activity, contribution snapshots | GitHub is authoritative | Cache normalized snapshots locally, show cached data offline, refresh on demand |
| XP, levels, streaks, achievements, quests | Deterministic local engine over normalized activity | Persist only non-derivable history and recompute derived metrics |
| User-owned notes, filters, dismissed items | Device | Persist locally |
| Firebase account | Firebase Auth | Remains an external service unless the product later adopts an entirely local-only account mode |
| Analytics/crash reporting | Optional external Firebase services | Make the trade-off explicit; allow development/local mode without requiring a paid backend |

### Storage implementation sequence

1. Inventory every persistent write and classify it as secret, preference, cache, or user-owned data.
2. Preserve `flutter_secure_storage` for GitHub credentials and avoid storing tokens in JSON caches.
3. Keep `shared_preferences` for small settings and progression metadata only.
4. Add a versioned local repository/cache abstraction for normalized GitHub snapshots. Use account-scoped keys, timestamps, schema versions, expiry, and atomic replacement.
5. Cache successful responses only. On a network/API failure, return a typed error plus the last known snapshot when one exists; always show when data is stale.
6. Clear account-scoped snapshots and progression when the user disconnects or requests local-data deletion. Do not silently erase data when the network is unavailable.
7. Avoid Firestore or a custom backend for core app storage. Firebase Auth is still external; GitHub data still needs network access to refresh.

SharedPreferences is suitable for small JSON snapshots only while their size remains bounded. If the cache grows into large timelines or repository histories, migrate that cache to SQLite behind the same interface rather than allowing preference files to grow without limit.

## Definition of done

- Cartoon visual language is consistent across all screens, not just the dashboard.
- No known overflow at 320dp; responsive tests cover narrow and large layouts.
- Existing authentication, GitHub authorization, theme selection, and progression behavior remain intact.
- Offline launch shows cached data when available and honest empty/error states otherwise.
- No secrets appear in source, logs, preferences, screenshots, or analytics.
- `dart format`, `flutter analyze`, the complete test suite, and a debug APK build pass in an environment with Flutter installed.
- A human checks the app on an Android emulator/device in both light and dark themes.
