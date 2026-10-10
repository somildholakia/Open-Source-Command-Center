import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_preference.dart';

/// Theme toggle with shared_preferences persistence (Dark/Light/System).
/// Integrated with AppTheme architecture.
class ThemeToggle extends StatefulWidget {
  const ThemeToggle({super.key});

  @override
  State<ThemeToggle> createState() => _ThemeToggleState();
}

class _ThemeToggleState extends State<ThemeToggle> {
  ThemeMode? _mode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final mode = await ThemePreference.getThemeMode();
    if (mounted) setState(() => _mode = mode);
  }

  Future<void> _save(ThemeMode mode) async {
    await ThemePreference.setThemeMode(mode);
    if (mounted) setState(() => _mode = mode);
  }

  @override
  Widget build(BuildContext context) {
    final mode = _mode ?? ThemeMode.dark;
    final label = mode == ThemeMode.dark
        ? 'Dark'
        : mode == ThemeMode.light
        ? 'Light'
        : 'System';
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Theme',
                style: AppTypography.titleSmall.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<ThemeMode>(
          initialValue: mode,
          onSelected: _save,
          itemBuilder: (context) => [
            const PopupMenuItem(value: ThemeMode.dark, child: Text('Dark')),
            const PopupMenuItem(value: ThemeMode.light, child: Text('Light')),
            const PopupMenuItem(value: ThemeMode.system, child: Text('System')),
          ],
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: AppSpacing.borderRadiusSm,
              border: Border.all(color: colorScheme.outline),
            ),
            child: Row(
              children: [
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
