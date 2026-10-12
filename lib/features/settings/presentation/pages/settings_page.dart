import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/widgets/cartoon_page_banner.dart';
import '../../../auth/presentation/bloc/auth.dart';
import '../../../progress/presentation/bloc/intelligence_bloc.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/theme_toggle.dart';

/// Settings screen for account, appearance, privacy, and app information.
///
/// Functional: theme persistence, authenticated account details, and sign-out.
/// Notifications and privacy controls remain informational until their
/// corresponding local notification/privacy features are implemented.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: AppTypography.titleLarge.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            // Return to the auth flow when the user signs out.
            if (state is AuthUnauthenticated) {
              context.go(AppRouter.login);
            } else if (state is AuthSignOutFailed) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is AuthAuthenticated || state is AuthSignOutFailed) {
              final user = state is AuthAuthenticated
                  ? state.user
                  : (state as AuthSignOutFailed).user;
              return SingleChildScrollView(
                child: ResponsiveContainer(
                  child: Column(
                    children: [
                      AppSpacing.vSpaceMd,
                      const CartoonPageBanner(
                        eyebrow: 'Make it yours',
                        title: 'Your space, your rules',
                        subtitle: 'Tune the app to fit the way you build.',
                        icon: Icons.palette_rounded,
                        accent: Color(0xFF7C4DFF),
                      ),
                      AppSpacing.vSpaceMd,
                      // Appearance — functional: theme selection + persistence
                      const SettingsSectionCard(
                        icon: Icons.brightness_6_rounded,
                        title: 'Appearance',
                        subtitle: 'Theme and display preferences',
                        child: ThemeToggle(),
                      ),
                      AppSpacing.vSpaceMd,
                      // Account — real authenticated user information
                      SettingsSectionCard(
                        icon: Icons.account_circle_rounded,
                        title: 'Account',
                        subtitle: user.email ?? 'No email',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _AccountInfoRow(
                              icon: Icons.person_outline_rounded,
                              label: 'Name',
                              value: user.displayNameOrDefault,
                            ),
                            AppSpacing.vSpaceXs,
                            _AccountInfoRow(
                              icon: Icons.alternate_email_rounded,
                              label: 'Email',
                              value: user.email ?? 'No email',
                            ),
                            if (user.createdAt != null) ...[
                              AppSpacing.vSpaceXs,
                              _AccountInfoRow(
                                icon: Icons.calendar_today_rounded,
                                label: 'Member since',
                                value: _formatDate(user.createdAt!),
                              ),
                            ],
                          ],
                        ),
                      ),
                      AppSpacing.vSpaceMd,
                      // Progression — functional: XP/achievements/quests summary
                      // and reset of persisted history (Phase 3).
                      const SettingsSectionCard(
                        icon: Icons.emoji_events_rounded,
                        title: 'Progression',
                        subtitle: 'XP, achievements and quest history',
                        child: _ProgressionRow(),
                      ),
                      AppSpacing.vSpaceMd,
                      // Notifications — presentation-only (Phase 2)
                      const SettingsSectionCard(
                        icon: Icons.notifications_rounded,
                        title: 'Notifications',
                        subtitle: 'Push and reminder settings',
                        child: _NotificationRow(),
                      ),
                      AppSpacing.vSpaceMd,
                      // Privacy — presentation-only (GitHub disconnect in Phase 2)
                      const SettingsSectionCard(
                        icon: Icons.lock_outline_rounded,
                        title: 'Privacy',
                        subtitle: 'Data usage and connections',
                        child: _PrivacyRow(),
                      ),
                      AppSpacing.vSpaceMd,
                      // About — presentation-only
                      const SettingsSectionCard(
                        icon: Icons.info_outline_rounded,
                        title: 'About',
                        subtitle: 'Version, environment and project info',
                        child: _AboutContent(),
                      ),
                      AppSpacing.vSpaceXl,
                      // Sign out — functional via AuthBloc
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.read<AuthBloc>().add(
                              const AuthSignOutRequested(),
                            );
                          },
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Sign Out'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.error,
                            side: BorderSide(
                              color: colorScheme.error,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                      AppSpacing.vSpaceMd,
                    ],
                  ),
                ),
              );
            }

            // Unauthenticated — empty/prompt state
            return SingleChildScrollView(
              child: Column(
                children: [
                  AppSpacing.vSpaceXl,
                  Icon(
                    Icons.settings_outlined,
                    size: AppSpacing.avatarSizeXLarge,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  AppSpacing.vSpaceMd,
                  Text(
                    'No Settings',
                    style: AppTypography.emptyStateHeading.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  AppSpacing.vSpaceXs,
                  Text(
                    'Sign in to configure your preferences.',
                    style: AppTypography.emptyStateMessage.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$month/$year';
  }
}

/// Progression summary plus a reset for persisted history.
///
/// Reset only forgets history the current data window cannot recreate
/// (recorded unlocks and past quest completions); achievements the live data
/// still satisfies legitimately stay unlocked, which the confirmation says
/// plainly.
class _ProgressionRow extends StatelessWidget {
  const _ProgressionRow();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<IntelligenceBloc, IntelligenceState>(
      builder: (context, state) {
        if (!state.hasData) {
          return Text(
            'Connect GitHub to start building XP, streaks and achievements.',
            style: AppTypography.captionSmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          );
        }

        final intelligence = state.intelligence;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AccountInfoRow(
              icon: Icons.workspace_premium_rounded,
              label: 'Level',
              value:
                  '${intelligence.level.level} · '
                  '${intelligence.level.totalXp} XP',
            ),
            AppSpacing.vSpaceXs,
            _AccountInfoRow(
              icon: Icons.local_fire_department_rounded,
              label: 'Streak',
              value: '${intelligence.streak.currentStreak} days',
            ),
            AppSpacing.vSpaceXs,
            _AccountInfoRow(
              icon: Icons.emoji_events_rounded,
              label: 'Achievements',
              value:
                  '${intelligence.unlockedAchievementCount} / '
                  '${intelligence.achievements.length}',
            ),
            AppSpacing.vSpaceSm,
            OutlinedButton.icon(
              onPressed: () => _confirmReset(context),
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Reset progression history'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final bloc = context.read<IntelligenceBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset progression history?'),
        content: const Text(
          'This forgets recorded achievement unlocks and completed quests. '
          'Anything your current GitHub data still shows stays unlocked and is '
          're-derived, so your live progress is not lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    bloc.add(const IntelligenceProgressionResetRequested());
    messenger.showSnackBar(
      const SnackBar(content: Text('Progression history cleared.')),
    );
  }
}

/// Compact label/value row for the Account section.
class _AccountInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AccountInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: AppSpacing.iconSizeSmall,
          color: colorScheme.onSurfaceVariant,
        ),
        AppSpacing.hSpaceXs,
        Text(
          label,
          style: AppTypography.captionMedium.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        AppSpacing.hSpaceSm,
        Expanded(
          child: Text(
            value,
            style: AppTypography.labelMedium.copyWith(
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Presentation-only notification toggles — no backend yet (Phase 2).
///
/// Switches are visually complete but clearly marked as coming soon so
/// users are not misled into thinking they are functional.
class _NotificationRow extends StatelessWidget {
  const _NotificationRow();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ComingSoonToggleRow(
          icon: Icons.notifications_active_rounded,
          label: 'Contribution alerts',
          colorScheme: colorScheme,
        ),
        AppSpacing.vSpaceXs,
        _ComingSoonToggleRow(
          icon: Icons.emoji_events_rounded,
          label: 'Achievement unlocked',
          colorScheme: colorScheme,
        ),
        AppSpacing.vSpaceXs,
        Row(
          children: [
            Icon(
              Icons.schedule_rounded,
              size: AppSpacing.iconSizeSmall,
              color: AppColors.warningAccent,
            ),
            AppSpacing.hSpaceXs,
            Expanded(
              child: Text(
                'Notification delivery arrives with GitHub sync in Phase 2.',
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.warningAccent,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A disabled-looking toggle row for presentation-only settings.
class _ComingSoonToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  const _ComingSoonToggleRow({
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: AppSpacing.iconSizeSmall,
          color: colorScheme.onSurfaceVariant,
        ),
        AppSpacing.hSpaceSm,
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Switch.adaptive(
          value: false,
          onChanged: null, // Presentation-only until Phase 2
        ),
      ],
    );
  }
}

/// Presentation-only privacy content — GitHub account management in Phase 2.
class _PrivacyRow extends StatelessWidget {
  const _PrivacyRow();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PrivacyItem(
          icon: Icons.shield_outlined,
          title: 'Secure authorization',
          description:
              'GitHub connects through OAuth with minimum required '
              'permissions. Access tokens are stored only in '
              'device-secure storage.',
          colorScheme: colorScheme,
        ),
        AppSpacing.vSpaceXs,
        _PrivacyItem(
          icon: Icons.link_off_rounded,
          title: 'Disconnect integrations',
          description:
              'Disconnecting GitHub removes its saved token, local snapshots, '
              'and account-scoped progression history.',
          colorScheme: colorScheme,
        ),
      ],
    );
  }
}

class _PrivacyItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final ColorScheme colorScheme;

  const _PrivacyItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: AppSpacing.iconSizeSmall,
          color: colorScheme.onSurfaceVariant,
        ),
        AppSpacing.hSpaceSm,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppSpacing.vSpaceXxs,
              Text(
                description,
                style: AppTypography.captionSmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// About content — app name, version and project context.
///
/// Version and environment come from the existing architecture
/// ([AppConfig]); no new dependencies or platform channels.
class _AboutContent extends StatelessWidget {
  const _AboutContent();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Open Source Developer Command Center',
          style: AppTypography.titleSmall.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        AppSpacing.vSpaceXs,
        _AboutRow(label: 'Version', value: '1.0.0'),
        _AboutRow(label: 'Environment', value: AppConfig.environmentLabel),
        _AboutRow(label: 'Platform', value: 'GitHub · Progress (Phase 3)'),
        AppSpacing.vSpaceXs,
        Text(
          'A personal operating system for open-source developers: '
          'track contributions, surface what needs attention, and build '
          'streaks, XP and achievements.',
          style: AppTypography.captionSmall.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;

  const _AboutRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Text(
            label,
            style: AppTypography.captionMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.hSpaceSm,
          Expanded(
            child: Text(
              value,
              style: AppTypography.labelMedium.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
