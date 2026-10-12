import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/widgets/cartoon_page_banner.dart';
import '../../../auth/presentation/bloc/auth.dart';
import '../../../integrations/presentation/widgets/github_connection_card.dart';
import '../widgets/profile_empty_state.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_loading_state.dart';
import '../widgets/profile_section_card.dart';
import '../widgets/profile_sign_out_button.dart';
import '../widgets/profile_stats_row.dart';

/// Profile screen - user profile and settings.
///
/// Stage 6.5: Uses real authenticated [UserModel] from [AuthBloc].
/// Phase 2: Connected Accounts reflects the real GitHub provider connection
/// via [IntegrationBloc]. Presentation-only mock data remains only for
/// Level/XP/Streak until gamification phases.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: AppTypography.titleLarge),
        elevation: 0,
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
            if (state is AuthLoading) {
              return const ProfileLoadingState();
            }

            if (state is AuthAuthenticated || state is AuthSignOutFailed) {
              final user = state is AuthAuthenticated
                  ? state.user
                  : (state as AuthSignOutFailed).user;
              return ResponsiveContainer(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      AppSpacing.vSpaceMd,
                      const CartoonPageBanner(
                        eyebrow: 'Your developer story',
                        title: 'This is your space',
                        subtitle:
                            'Your identity, connections and achievements.',
                        icon: Icons.face_retouching_natural_rounded,
                        accent: Color(0xFF008F86),
                      ),
                      AppSpacing.vSpaceMd,
                      ProfileHeader(
                        photoUrl: user.photoUrl,
                        displayName: user.displayNameOrDefault,
                        email: user.email ?? 'No email',
                        createdAt: user.createdAt,
                      ),
                      AppSpacing.vSpaceMd,
                      const ProfileStatsRow(),
                      AppSpacing.vSpaceXl,
                      // Phase 2: real GitHub connection state (connect /
                      // connecting / connected / expired / error).
                      const GithubConnectionCard(),
                      AppSpacing.vSpaceMd,
                      const ProfileSectionCard(
                        icon: Icons.emoji_events_rounded,
                        title: 'Achievements',
                        subtitle: '0 unlocked',
                      ),
                      AppSpacing.vSpaceMd,
                      ProfileSectionCard(
                        icon: Icons.settings_rounded,
                        title: 'Settings',
                        subtitle: 'Preferences and configuration',
                        onTap: () => context.push('/settings'),
                      ),
                      AppSpacing.vSpaceMd,
                      const ProfileSectionCard(
                        icon: Icons.info_outline_rounded,
                        title: 'About',
                        subtitle: 'Version 1.0.0',
                      ),
                      AppSpacing.vSpaceXl,
                      const ProfileSignOutButton(),
                      AppSpacing.vSpaceMd,
                    ],
                  ),
                ),
              );
            }

            // AuthUnauthenticated or any other state.
            return const ProfileEmptyState();
          },
        ),
      ),
    );
  }
}
