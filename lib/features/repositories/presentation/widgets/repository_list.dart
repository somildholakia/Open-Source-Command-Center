import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../domain/domain.dart';

/// Reusable list of normalized [Repository] entities.
///
/// Provider-agnostic: callers pass domain entities (GitHub now, other
/// providers later). Renders at most [maxItems] entries so it fits dashboards;
/// pass a larger value for full lists.
class RepositoryList extends StatelessWidget {
  final List<Repository> repositories;
  final int maxItems;

  const RepositoryList({
    super.key,
    required this.repositories,
    this.maxItems = 3,
  });

  @override
  Widget build(BuildContext context) {
    final visible = repositories.take(maxItems).toList(growable: false);

    return Column(
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) AppSpacing.vSpaceSm,
          RepositoryCard(repository: visible[i]),
        ],
      ],
    );
  }
}

/// A single repository card.
class RepositoryCard extends StatelessWidget {
  final Repository repository;

  const RepositoryCard({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: AppSpacing.cardPaddingInsets,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                repository.isFork
                    ? Icons.call_split_rounded
                    : Icons.folder_rounded,
                size: AppSpacing.iconSizeSmall,
                color: colorScheme.primary,
              ),
              AppSpacing.hSpaceXs,
              Expanded(
                child: Text(
                  repository.name,
                  style: AppTypography.repoName.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (repository.isPrivate)
                Icon(
                  Icons.lock_rounded,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
            ],
          ),
          if (repository.description.isNotEmpty) ...[
            AppSpacing.vSpaceXxs,
            Text(
              repository.description,
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          AppSpacing.vSpaceXs,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xxs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (repository.language.isNotEmpty)
                _MetaChip(
                  icon: Icons.circle,
                  iconColor: _languageColor(repository.language),
                  label: repository.language,
                ),
              if (repository.stars != null)
                _MetaChip(
                  icon: Icons.star_rounded,
                  iconColor: AppColors.achievement,
                  label: '${repository.stars}',
                ),
              if (repository.forks != null)
                _MetaChip(
                  icon: Icons.call_split_rounded,
                  iconColor: colorScheme.onSurfaceVariant,
                  label: '${repository.forks}',
                ),
              if (repository.updatedAt != null)
                _MetaChip(
                  icon: Icons.schedule_rounded,
                  iconColor: colorScheme.onSurfaceVariant,
                  label: formatTimeAgo(repository.updatedAt!),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Common GitHub language colors; unknown languages fall back to the
  /// theme primary so the UI never depends on dark-only literals.
  Color _languageColor(String language) {
    switch (language.toLowerCase()) {
      case 'dart':
        return const Color(0xFF00B4AB);
      case 'typescript':
        return const Color(0xFF3178C6);
      case 'javascript':
        return const Color(0xFFF1E05A);
      case 'python':
        return const Color(0xFF3572A5);
      case 'java':
        return const Color(0xFFB07219);
      case 'kotlin':
        return const Color(0xFFA97BFF);
      case 'swift':
        return const Color(0xFFF05138);
      case 'go':
        return const Color(0xFF00ADD8);
      case 'rust':
        return const Color(0xFFDEA584);
      case 'ruby':
        return const Color(0xFF701516);
      case 'c':
        return const Color(0xFF555555);
      case 'c++':
        return const Color(0xFFF34B7D);
      case 'c#':
        return const Color(0xFF178600);
      case 'php':
        return const Color(0xFF4F5D95);
      case 'html':
        return const Color(0xFFE34C26);
      case 'css':
        return const Color(0xFF563D7C);
      case 'shell':
        return const Color(0xFF89E051);
      default:
        return AppColors.primary;
    }
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _MetaChip({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: iconColor),
        AppSpacing.hSpaceXxs,
        Text(
          label,
          style: AppTypography.captionSmall.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
