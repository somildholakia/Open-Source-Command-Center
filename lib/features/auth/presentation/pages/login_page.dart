import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/email_validator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/cartoon_page_banner.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../bloc/auth.dart';

/// Login page for existing users.
///
/// Provides email/password login and social login placeholders.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      // Hide keyboard
      FocusScope.of(context).unfocus();

      context.read<AuthBloc>().add(
        AuthSignInRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/');
        } else if (state is AuthPasswordResetResult) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: state.success
                  ? AppColors.successAccent
                  : AppColors.errorAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.onError,
                  ),
                  AppSpacing.hSpaceSm,
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.borderRadiusMd,
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: ResponsiveContainer(
            child: SingleChildScrollView(
              padding: AppSpacing.screenPaddingWithTop,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSpacing.vSpaceXxl,
                  // Header
                  _buildHeader(),
                  AppSpacing.vSpaceXxl,

                  // Login Form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildEmailField(isLoading),
                        AppSpacing.vSpaceMd,
                        _buildPasswordField(isLoading),
                        AppSpacing.vSpaceSm,

                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: isLoading
                                ? null
                                : () => _showForgotPassword(),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryAccent,
                              minimumSize: Size.zero,
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.padded,
                            ),
                            child: Text(
                              'Forgot Password?',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.primaryAccent,
                              ),
                            ),
                          ),
                        ),
                        AppSpacing.vSpaceLg,

                        // Login Button
                        _buildLoginButton(isLoading),
                      ],
                    ),
                  ),

                  AppSpacing.vSpaceXl,

                  // Divider
                  _buildDivider(),

                  AppSpacing.vSpaceXl,

                  // Social Login
                  _buildSocialButtons(isLoading),

                  AppSpacing.vSpaceXl,

                  // Sign Up Link
                  _buildSignUpLink(isLoading),
                  AppSpacing.vSpaceXl,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return CartoonPageBanner(
      eyebrow: 'Welcome back, adventurer',
      title: 'Login to Terminal',
      subtitle: 'Connect to continue your journey',
      icon: Icons.terminal_rounded,
      accent: AppColors.primaryAccent,
    );
  }

  Widget _buildEmailField(bool isLoading) {
    return TextFormField(
      controller: _emailController,
      focusNode: _emailFocusNode,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
      enabled: !isLoading,
      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: 'Email Address',
        hintText: 'developer@example.com',
        prefixIcon: const Icon(Icons.email_outlined),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: AppColors.primaryAccent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: AppTypography.bodyMedium,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your email';
        }
        if (!EmailValidator.isValid(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(bool isLoading) {
    return TextFormField(
      controller: _passwordController,
      focusNode: _passwordFocusNode,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _submit(),
      enabled: !isLoading,
      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: '••••••••',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: AppColors.textSecondary,
          ),
          onPressed: isLoading
              ? null
              : () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: AppColors.primaryAccent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: AppTypography.bodyMedium,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        return null;
      },
    );
  }

  Widget _buildLoginButton(bool isLoading) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: AppSpacing.borderRadiusMd,
        gradient: isLoading
            ? null
            : const LinearGradient(colors: AppColors.gradientPremium),
        color: isLoading ? AppColors.surfaceElevated : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : _submit,
          borderRadius: AppSpacing.borderRadiusMd,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  )
                : Text(
                    'Initialize Session',
                    style: AppTypography.buttonLarge.copyWith(
                      color: AppColors.textOnPrimary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.border, thickness: 1)),
        AppSpacing.hSpaceMd,
        Text('OR CONNECT WITH', style: AppTypography.labelSmall),
        AppSpacing.hSpaceMd,
        Expanded(child: Divider(color: AppColors.border, thickness: 1)),
      ],
    );
  }

  Widget _buildSocialButtons(bool isLoading) {
    final githubButton = _SocialButton(
      icon: Icons.code,
      label: 'GitHub',
      color: AppColors.surfaceElevated,
      textColor: AppColors.textPrimary,
      isLoading: isLoading,
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GitHub OAuth coming in Phase 2'),
            backgroundColor: AppColors.infoAccent,
          ),
        );
      },
    );
    final googleButton = _SocialButton(
      icon: Icons.g_mobiledata_rounded,
      label: 'Google',
      color: AppColors.surfaceElevated,
      textColor: AppColors.textPrimary,
      iconSize: 32,
      isLoading: isLoading,
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google OAuth coming soon'),
            backgroundColor: AppColors.infoAccent,
          ),
        );
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              githubButton,
              SizedBox(height: AppSpacing.sm),
              googleButton,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: githubButton),
            AppSpacing.hSpaceMd,
            Expanded(child: googleButton),
          ],
        );
      },
    );
  }

  Widget _buildSignUpLink(bool isLoading) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.xxs,
      runSpacing: AppSpacing.xxs,
      children: [
        Text(
          'Don\\'t have an account?',
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
        TextButton(
          onPressed: isLoading ? null : () => context.push('/signup'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryAccent,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusSm,
            ),
          ),
          child: Text(
            'Create Account',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.primaryAccent,
            ),
          ),
        ),
      ],
    );
  }

  void _showForgotPassword() {
    final emailParam = _emailController.text.trim();
    if (EmailValidator.isValid(emailParam)) {
      context.read<AuthBloc>().add(
        AuthPasswordResetRequested(email: emailParam),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid email address first'),
          backgroundColor: AppColors.warningAccent,
        ),
      );
      _emailFocusNode.requestFocus();
    }
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onPressed;
  final bool isLoading;
  final double iconSize;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
    required this.onPressed,
    this.isLoading = false,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.borderStrong, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: AppSpacing.borderRadiusMd,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: iconSize),
              AppSpacing.hSpaceSm,
              Text(
                label,
                style: AppTypography.buttonMedium.copyWith(color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
