# Open Source Developer Command Center

## Product Vision

A mobile-first command center for open-source developers.

The app connects to developer platforms and transforms contribution activity into:

- actionable tasks
- progress
- contribution insights
- gamification
- personal developer growth

The goal is to make open-source contribution feel like a journey rather than a collection of GitHub statistics.

## Initial Platform

GitHub is the only integration in the first implementation.

Future providers:

- GitLab
- Bitbucket
- Jira
- Linear

The architecture must allow these providers to be added without rewriting the core application.

## Core Product Loop

The primary loop is:

Connect account
→ Sync activity
→ Understand what needs attention
→ Take action
→ Earn progress
→ Build streak
→ Complete quests
→ Improve contribution health

## Main Navigation

The application will eventually contain:

1. Home
2. Activity
3. Contributions
4. Progress
5. Profile

## Home

The Home screen should answer:

- What should I do today?
- What needs my attention?
- How am I progressing?
- Am I maintaining my streak?

Planned components:

- Developer greeting
- Level and XP
- Today's contribution summary
- Needs Your Attention
- Current streak
- Daily quest
- Recent activity

## Activity

A chronological normalized feed of developer activity.

Examples:

- Pull request opened
- Pull request merged
- Pull request closed
- Pull request reviewed
- Changes requested
- Issue opened
- Issue closed
- Issue commented
- Commit created
- Review requested
- Mention received

## Contributions

Contribution overview including:

- commits
- pull requests
- issues
- reviews
- repositories
- contribution calendar
- contribution trends

## Progress

Gamification and personal development.

Planned features:

- XP
- levels
- streaks
- achievements
- badges
- daily quests
- weekly quests
- contribution health score
- milestones
- progress statistics

## Profile

Developer profile containing:

- avatar
- username
- connected providers
- level
- XP
- streak
- achievements
- contribution summary
- repositories
- shareable developer profile

## GitHub Integration

GitHub is the source of truth for GitHub activity.

The application should retrieve and normalize relevant data rather than attempting to replace GitHub.

Important data:

- repositories
- pull requests
- issues
- reviews
- commits
- notifications
- requested reviews
- mentions

Authentication and authorization must be secure.

Never hardcode credentials or expose GitHub secrets in the Flutter application.

## Gamification

Gamification should reward meaningful contribution rather than encourage spam.

Potential XP sources:

- meaningful pull request
- merged pull request
- useful review
- resolved issue
- meaningful commit
- helpful contribution

The exact XP rules will be defined during the gamification phase.

Do not implement gamification during the foundation phase.

## Monetization

Planned monetization:

Free tier:
- core tracking
- tasteful advertisements
- basic insights

Premium:
- no advertisements
- advanced analytics
- deeper history
- advanced reports
- additional personalization

Rewarded advertisements may optionally unlock temporary advanced functionality.

AdMob will be used.

Use test advertisements during development.

Do not implement monetization during the foundation phase.

## Design

The product should feel:

- creative
- playful
- premium
- energetic
- game-like
- developer-focused

Visual direction:

- dark/navy foundation
- vibrant accent colors
- pixel-art influence
- playful typography
- expressive illustrations/characters
- subtle animations
- clear hierarchy

The design should be inspired by the feeling of coding-game products without copying their branding, characters, assets or exact layouts.

Avoid generic:

- enterprise dashboards
- spreadsheet-like interfaces
- GitHub clones
- excessive tables
- default Flutter UI

## Mobile First

Android is the first target.

The UI must work across different phone sizes.

Desktop/web support may be useful for development but is not the primary product experience.

## Future Roadmap

Phase 1:
Foundation

Phase 2:
GitHub integration and core tracking

Phase 3:
Gamification and analytics

Phase 4:
Monetization and advanced product

Phase 5:
Multi-provider ecosystem and scale

Future possibilities:

- GitLab
- Bitbucket
- Jira
- Linear
- Chrome extension
- AI contribution summaries
- smart recommendations
- public developer profiles
- teams
- seasonal challenges
- custom themes and avatars