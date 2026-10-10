import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/cartoon_page_banner.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../bloc/auth.dart';

/// Sign-up page for new developers.
///
/// Collects email, password, and developer display name.
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms of Service to continue'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();

      context.read<AuthBloc>().add(
        AuthSignUpRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/');
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
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => context.pop(),
            ),
          ),
          body: ResponsiveContainer(
            child: SingleChildScrollView(
              padding: AppSpacing.screenPaddingHorizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  _buildHeader(),
                  AppSpacing.vSpaceXl,

                  // Sign-up Form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildNameField(isLoading),
                        AppSpacing.vSpaceMd,
                        _buildEmailField(isLoading),
                        AppSpacing.vSpaceMd,
                        _buildPasswordField(isLoading),
                        AppSpacing.vSpaceMd,
                        _buildConfirmPasswordField(isLoading),
                        AppSpacing.vSpaceMd,

                        // Terms Checkbox
                        _buildTermsCheckbox(isLoading),
                        AppSpacing.vSpaceLg,

                        // Register Button
                        _buildSignUpButton(isLoading),
                      ],
                    ),
                  ),

                  AppSpacing.vSpaceXl,

                  // Login Link
                  _buildLoginLink(isLoading),
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
      eyebrow: 'Start your quest',
      title: 'Create New Agent',
      subtitle: 'Join the ranks of open source contributors',
      icon: Icons.person_add_rounded,
      accent: AppColors.secondary,
    );
  }

  Widget _buildNameField(bool isLoading) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: _nameController,
      focusNode: _nameFocusNode,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
      enabled: !isLoading,
      style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: 'Developer Handle',
        hintText: 'e.g. OctoCoder',
        prefixIcon: const Icon(Icons.badge_outlined),
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.secondary),
        ),
        labelStyle: AppTypography.bodyMedium,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildEmailField(bool isLoading) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: _emailController,
      focusNode: _emailFocusNode,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
      enabled: !isLoading,
      style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: 'Email Address *',
        hintText: 'developer@example.com',
        prefixIcon: const Icon(Icons.email_outlined),
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.secondary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: AppTypography.bodyMedium,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Email is required';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(bool isLoading) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: _passwordController,
      focusNode: _passwordFocusNode,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
      enabled: !isLoading,
      style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: 'Password *',
        hintText: 'At least 8 characters',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: colorScheme.onSurfaceVariant,
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
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.secondary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: AppTypography.bodyMedium,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Password is required';
        }
        if (value.length < 8) {
          return 'Password must be at least 8 characters';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField(bool isLoading) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: _confirmPasswordController,
      focusNode: _confirmPasswordFocusNode,
      obscureText: _obscureConfirmPassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _submit(),
      enabled: !isLoading,
      style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: 'Confirm Password *',
        hintText: '••••••••',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
            color: colorScheme.onSurfaceVariant,
          ),
          onPressed: isLoading
              ? null
              : () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
        ),
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.secondary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: AppTypography.bodyMedium,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm your password';
        }
        if (value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildTermsCheckbox(bool isLoading) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _acceptedTerms,
          onChanged: isLoading
              ? null
              : (value) {
                  setState(() {
                    _acceptedTerms = value ?? false;
                  });
                },
          activeColor: AppColors.secondary,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'I accept the Terms of Service & Privacy Policy',
              style: AppTypography.bodySmall,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpButton(bool isLoading) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: AppSpacing.borderRadiusMd,
        gradient: isLoading
            ? null
            : const LinearGradient(
                colors: [AppColors.secondary, AppColors.accent],
              ),
        color: isLoading ? colorScheme.surfaceContainerHighest : null,
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
                        AppColors.secondary,
                      ),
                    ),
                  )
                : Text(
                    'Initialize New Agent',
                    style: AppTypography.buttonLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink(bool isLoading) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            'Already have an account?',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
        TextButton(
          onPressed: isLoading ? null : () => context.pop(),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.secondary,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusSm,
            ),
          ),
          child: Text(
            'Sign In',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.secondary,
            ),
          ),
        ),
      ],
    );
  }
}
