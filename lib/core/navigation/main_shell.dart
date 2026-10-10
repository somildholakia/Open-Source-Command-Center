import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/responsive_helper.dart';

/// Main navigation shell with responsive bottom navigation / navigation rail.
///
/// Wraps all main app screens with persistent navigation.
/// - Mobile (< 600dp): Bottom navigation bar
/// - Tablet & Desktop (≥ 600dp): Side navigation rail
/// Maintains state across tab switches.
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (context.isTabletOrLarger) {
      return Scaffold(
        body: Row(
          children: [
            const _SideNavRail(),
            VerticalDivider(width: 1, thickness: 1, color: colorScheme.outline),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(body: child, bottomNavigationBar: const _BottomNavBar());
  }
}

int _getCurrentIndex(BuildContext context) {
  final location = GoRouterState.of(context).uri.path;
  switch (location) {
    case '/':
      return 0;
    case '/activity':
      return 1;
    case '/contributions':
      return 2;
    case '/progress':
      return 3;
    case '/profile':
      return 4;
    default:
      return 0;
  }
}

void _onNavTap(BuildContext context, int index) {
  switch (index) {
    case 0:
      context.go('/');
      break;
    case 1:
      context.go('/activity');
      break;
    case 2:
      context.go('/contributions');
      break;
    case 3:
      context.go('/progress');
      break;
    case 4:
      context.go('/profile');
      break;
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: AppSpacing.bottomNavHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isSelected: currentIndex == 0,
                onTap: () => _onNavTap(context, 0),
              ),
              _NavItem(
                icon: Icons.list_rounded,
                label: 'Activity',
                isSelected: currentIndex == 1,
                onTap: () => _onNavTap(context, 1),
              ),
              _NavItem(
                icon: Icons.bar_chart_rounded,
                label: 'Contributions',
                isSelected: currentIndex == 2,
                onTap: () => _onNavTap(context, 2),
              ),
              _NavItem(
                icon: Icons.emoji_events_rounded,
                label: 'Progress',
                isSelected: currentIndex == 3,
                onTap: () => _onNavTap(context, 3),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                isSelected: currentIndex == 4,
                onTap: () => _onNavTap(context, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isSelected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusSm,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: AppSpacing.bottomNavItemPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: AppSpacing.iconSizeMedium),
                SizedBox(height: AppSpacing.bottomNavIconLabelGap),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tablet and desktop navigation rail.
class _SideNavRail extends StatelessWidget {
  const _SideNavRail();

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 96,
      color: colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            AppSpacing.vSpaceLg,
            // Mini Brand Icon
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              child: Icon(
                Icons.terminal_rounded,
                color: colorScheme.primary,
                size: AppSpacing.iconSizeMedium,
              ),
            ),
            AppSpacing.vSpaceXl,
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RailNavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    isSelected: currentIndex == 0,
                    onTap: () => _onNavTap(context, 0),
                  ),
                  AppSpacing.vSpaceMd,
                  _RailNavItem(
                    icon: Icons.list_rounded,
                    label: 'Activity',
                    isSelected: currentIndex == 1,
                    onTap: () => _onNavTap(context, 1),
                  ),
                  AppSpacing.vSpaceMd,
                  _RailNavItem(
                    icon: Icons.bar_chart_rounded,
                    label: 'Contributions',
                    isSelected: currentIndex == 2,
                    onTap: () => _onNavTap(context, 2),
                  ),
                  AppSpacing.vSpaceMd,
                  _RailNavItem(
                    icon: Icons.emoji_events_rounded,
                    label: 'Progress',
                    isSelected: currentIndex == 3,
                    onTap: () => _onNavTap(context, 3),
                  ),
                  AppSpacing.vSpaceMd,
                  _RailNavItem(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    isSelected: currentIndex == 4,
                    onTap: () => _onNavTap(context, 4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RailNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isSelected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusSm,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: AppSpacing.borderRadiusSm,
            border: isSelected
                ? Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: AppSpacing.iconSizeMedium),
              AppSpacing.vSpaceXxs,
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
