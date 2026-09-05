# AGENTS.md

## Project
Open Source Developer Command Center — a mobile-first Flutter app for open-source developers.

The app connects to developer platforms such as GitHub and turns contribution activity into an actionable, gamified developer experience.

## Product Vision
This is NOT just a GitHub statistics dashboard.

The product should feel like a personal operating system for an open-source developer:
- Track contributions
- Surface what needs attention
- Show progress and contribution health
- Build XP, levels, streaks and achievements
- Provide quests and goals
- Help developers stay consistent
- Eventually support multiple developer platforms

## Design Direction
The UI should be:
- Creative
- Playful
- Premium
- Game-like
- Mobile-first
- Dark/navy based with vibrant accent colors
- Pixel-art inspired
- Animation-friendly
- Developer-focused

Take inspiration from the feeling of modern coding-game products, but NEVER copy another product's assets, characters, branding or exact UI.

Avoid:
- Generic admin dashboards
- Boring enterprise layouts
- Excessive tables
- Default Flutter-looking screens

## Engineering Rules

1. Build incrementally.
2. Do not implement future phases early.
3. Do not rewrite working code unnecessarily.
4. Before adding a dependency, explain why it is needed.
5. Prefer simple, maintainable solutions.
6. Keep business logic separate from UI.
7. Keep reusable UI components centralized.
8. Never hardcode secrets, API keys, tokens or credentials.
9. Never commit secrets to Git.
10. Handle loading, error and empty states.
11. Write tests for important business logic.
12. Keep the application responsive across phone sizes.
13. Preserve accessibility while maintaining the visual design.
14. Do not make destructive changes without explaining them first.
15. If an architectural decision changes, document it.

## Architecture

Use feature-based architecture.

Target structure:

lib/
  core/
    config/
    constants/
    errors/
    network/
    storage/
    theme/
    utils/
    widgets/

  features/
    auth/
    dashboard/
    activity/
    contributions/
    repositories/
    pull_requests/
    issues/
    reviews/
    gamification/
    profile/
    notifications/
    integrations/
    settings/
    monetization/

  services/
    github/
    firebase/
    analytics/
    notifications/
    ads/

Do not create all files immediately.
Create directories and files only when they are actually needed.

## State Management

Use a predictable state-management architecture.

Keep:
- UI state
- application/business state
- network state

separated where practical.

## Backend

The planned backend is Firebase-based.

Expected future services:
- Firebase Authentication
- Firestore
- Cloud Functions / Cloud Run
- Firebase Cloud Messaging
- Firebase Analytics
- Firebase Crashlytics

GitHub should remain the source of truth for GitHub data.

The backend should normalize provider data and cache/aggregate it where appropriate.

## Integrations

Use a provider abstraction so future integrations do not require rewriting the application.

Planned providers:
- GitHub
- GitLab
- Bitbucket
- Jira
- Linear

Initial implementation should focus ONLY on GitHub.

## GitHub Security

Never store personal GitHub access tokens directly in the Flutter client.

Use secure authorization and minimum required permissions.

Users must be able to disconnect integrations.

## Development Workflow

For every meaningful feature:

1. Understand the requirement.
2. Inspect existing code.
3. Explain the implementation approach.
4. Implement the smallest correct change.
5. Run formatting.
6. Run static analysis.
7. Run relevant tests.
8. Fix failures.
9. Summarize what changed.

## UI Development

For early UI work:
- Use mock/local data.
- Do not block UI development on backend integration.
- Keep API-dependent logic behind services/repositories.
- Use centralized theme tokens.
- Build reusable components instead of duplicating UI.

## Performance

The primary target is Android.

Be mindful of lower-end devices.

Avoid:
- unnecessary rebuilds
- excessive animations
- huge images
- blocking work on the main isolate
- unnecessary network requests

## Git Discipline

Keep commits small and meaningful.

Use conventional commit style where practical:

feat:
fix:
refactor:
chore:
docs:
test:

Never commit:
- API keys
- passwords
- OAuth secrets
- private credentials
- generated sensitive files

## Current Phase

We are currently in:

PHASE 1 — FOUNDATION

Focus on:
- Project architecture
- Theme/design system
- Navigation
- Responsive UI foundation
- Authentication UI
- Firebase foundation
- Basic profile/settings foundation

Do NOT implement:
- GitHub synchronization
- XP calculations
- achievements
- quests
- AdMob
- premium
- GitLab
- Bitbucket
- Jira
- Linear
- Chrome extension

until their respective phases.

## Product Quality

The goal is a production-quality application, not a tutorial/demo.

Prefer:
- clean architecture
- maintainability
- polished UX
- thoughtful empty states
- thoughtful error states
- smooth interactions
- consistent visual language
- secure integrations