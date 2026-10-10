import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Circular avatar for remote provider images (GitHub now, others later).
///
/// Handles the three states every remote image needs:
/// - no URL: renders initials
/// - loading: renders initials (no spinner — avatars are not worth a busy
///   indicator, and static fallbacks keep screens settle-friendly)
/// - load failure (offline, deleted account, rate-limited avatar host):
///   renders initials instead of a broken image
class ProviderAvatar extends StatelessWidget {
  final String? imageUrl;

  /// Fallback text (typically the username); the first character is shown.
  final String? fallbackText;

  /// Avatar diameter in logical pixels.
  final double size;

  final Color? backgroundColor;
  final Color? foregroundColor;

  const ProviderAvatar({
    super.key,
    required this.imageUrl,
    this.fallbackText,
    this.size = AppSpacing.avatarSizeMedium,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background =
        backgroundColor ?? colorScheme.primary.withValues(alpha: 0.2);
    final foreground = foregroundColor ?? colorScheme.primary;

    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Text(
        _initial,
        style: AppTypography.titleSmall.copyWith(
          color: foreground,
          fontSize: size * 0.4,
        ),
      ),
    );

    final url = imageUrl;
    if (url == null || url.isEmpty) return fallback;

    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // Static fallback while loading and on failure.
        errorBuilder: (context, error, stackTrace) => fallback,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : fallback,
      ),
    );
  }

  String get _initial {
    final text = fallbackText?.trim() ?? '';
    return text.isEmpty ? '?' : text[0].toUpperCase();
  }
}
