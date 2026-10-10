import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/auth.dart';

/// Splash screen displayed on app startup.
///
/// Shows branding and checks authentication state.
/// Navigates to login (unauthenticated) or dashboard (authenticated).
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scale;
  late final Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _glowPulse = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    // Trigger auth check after animation starts
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<AuthBloc>().add(const AuthCheckRequested());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/');
        } else if (state is AuthUnauthenticated) {
          context.go('/login');
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeIn,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Glowing terminal icon
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.primary.withValues(
                                alpha: 0.2 * _glowPulse.value,
                              ),
                              Colors.transparent,
                            ],
                            radius: 1.5,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.surface,
                            border: Border.all(
                              color: AppColors.primary.withValues(
                                alpha: 0.5 * _glowPulse.value,
                              ),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.3 * _glowPulse.value,
                                ),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.terminal_rounded,
                            color: AppColors.primary,
                            size: 64,
                          ),
                        ),
                      ),
                      AppSpacing.vSpaceXl,
                      // App title with gradient. The gradient is re-applied
                      // after ShaderMask so the title stays readable when the
                      // system forces a light/dark swap underneath it.
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: AppColors.gradientPremium,
                        ).createShader(bounds),
                        child: Text(
                          'COMMAND',
                          style: AppTypography.displayMedium.copyWith(
                            color: AppColors.textPrimary,
                            letterSpacing: 6,
                          ),
                        ),
                      ),
                      Text(
                        'CENTER',
                        style: AppTypography.headingLarge.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 10,
                        ),
                      ),
                      AppSpacing.vSpaceLg,
                      // Tagline
                      Text(
                        'Your open source journey starts here',
                        style: AppTypography.bodyMedium.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      AppSpacing.vSpaceXxl,
                      // Loading indicator
                      SizedBox(
                        width: 40,
                        child: ClipRRect(
                          borderRadius: AppSpacing.borderRadiusFull,
                          child: LinearProgressIndicator(
                            backgroundColor: colorScheme.surface,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary.withValues(
                                alpha: _glowPulse.value,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
