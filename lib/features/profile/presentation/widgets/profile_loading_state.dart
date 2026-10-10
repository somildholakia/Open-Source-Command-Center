import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/responsive_layout.dart';

/// Lightweight loading state using existing theme components.
///
/// Does not use the shimmer dependency — keeps Stage 6.5 loading
/// state minimal per approval.
class ProfileLoadingState extends StatelessWidget {
  const ProfileLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ResponsiveContainer(
      child: SingleChildScrollView(
        child: Column(
          children: [
            AppSpacing.vSpaceXl,
            // Avatar placeholder
            Center(
              child: CircleAvatar(
                radius: AppSpacing.avatarSizeXLarge / 2,
                backgroundColor: colorScheme.surfaceContainerHighest,
                child: SizedBox(
                  width: AppSpacing.avatarSizeXLarge,
                  height: AppSpacing.avatarSizeXLarge,
                ),
              ),
            ),
            AppSpacing.vSpaceMd,
            // Name placeholder
            Center(child: SizedBox(width: 160, height: 24)),
            AppSpacing.vSpaceXs,
            // Email placeholder
            Center(child: SizedBox(width: 200, height: 16)),
            AppSpacing.vSpaceXl,
            // Stats placeholders
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _PlaceholderBox(width: 60, height: 32),
                _PlaceholderBox(width: 60, height: 32),
                _PlaceholderBox(width: 60, height: 32),
              ],
            ),
            AppSpacing.vSpaceXl,
            // Section card placeholders
            _PlaceholderBox(width: double.infinity, height: 64),
            AppSpacing.vSpaceMd,
            _PlaceholderBox(width: double.infinity, height: 64),
            AppSpacing.vSpaceMd,
            _PlaceholderBox(width: double.infinity, height: 64),
            AppSpacing.vSpaceMd,
            _PlaceholderBox(width: double.infinity, height: 64),
            AppSpacing.vSpaceXl,
            // Sign out placeholder
            _PlaceholderBox(width: double.infinity, height: 48),
            AppSpacing.vSpaceMd,
          ],
        ),
      ),
    );
  }
}

class _PlaceholderBox extends StatelessWidget {
  final double width;
  final double height;

  const _PlaceholderBox({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppSpacing.borderRadiusSm,
      ),
    );
  }
}
