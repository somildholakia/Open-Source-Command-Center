import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Profile header displaying avatar, name, email, and account info.
///
/// Uses real [UserModel] data from Firebase Auth via [AuthBloc].
/// Falls back to presentation placeholders when data is missing.
class ProfileHeader extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final String email;
  final DateTime? createdAt;

  const ProfileHeader({
    super.key,
    this.photoUrl,
    required this.displayName,
    required this.email,
    this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _initials(displayName);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        CircleAvatar(
          radius: AppSpacing.avatarSizeXLarge / 2,
          backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
          backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
              ? NetworkImage(photoUrl!)
              : null,
          child: photoUrl == null || photoUrl!.isEmpty
              ? Text(
                  initials,
                  style: AppTypography.headingMedium.copyWith(
                    color: colorScheme.primary,
                  ),
                )
              : null,
        ),
        AppSpacing.vSpaceMd,
        Text(
          displayName,
          style: AppTypography.headingMedium.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        AppSpacing.vSpaceXs,
        Text(
          email,
          style: AppTypography.bodyMedium.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        if (createdAt != null) ...[
          AppSpacing.vSpaceXs,
          Text(
            'Member since ${_formatDate(createdAt!)}',
            style: AppTypography.captionMedium.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$month/$year';
  }
}
