import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../utils/responsive_helper.dart';

/// Builder signature for [ResponsiveBuilder].
typedef ResponsiveWidgetBuilder = Widget Function(
  BuildContext context,
  DeviceScreenType screenType,
  BoxConstraints constraints,
);

/// Widget that builds different UI structures using layout constraints.
///
/// Unlike MediaQuery-based widgets, [ResponsiveBuilder] uses [LayoutBuilder]
/// constraints to measure available width locally.
///
/// Usage:
/// ```dart
/// ResponsiveBuilder(
///   builder: (context, screenType, constraints) {
///     if (screenType == DeviceScreenType.tablet) {
///       return TabletLayout();
///     }
///     return MobileLayout();
///   },
/// )
/// ```
class ResponsiveBuilder extends StatelessWidget {
  /// Builder callback invoked with layout information.
  final ResponsiveWidgetBuilder builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenType = ResponsiveHelper.getDeviceTypeFromWidth(
          constraints.maxWidth,
        );
        return builder(context, screenType, constraints);
      },
    );
  }
}

/// Declarative responsive layout widget selecting between pre-defined layouts.
///
/// Usage:
/// ```dart
/// ResponsiveLayout(
///   mobile: MobileView(),
///   tablet: TabletView(),
///   desktop: DesktopView(),
/// )
/// ```
class ResponsiveLayout extends StatelessWidget {
  /// Layout rendered on mobile screens (< 600dp). Also serves as fallback.
  final Widget mobile;

  /// Optional layout for compact screens (< 360dp). Falls back to [mobile].
  final Widget? compact;

  /// Optional layout for tablet screens (600dp – 1023dp). Falls back to [mobile].
  final Widget? tablet;

  /// Optional layout for desktop screens (≥ 1024dp). Falls back to [tablet] or [mobile].
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.compact,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenType, constraints) {
        switch (screenType) {
          case DeviceScreenType.compact:
            return compact ?? mobile;
          case DeviceScreenType.mobile:
            return mobile;
          case DeviceScreenType.tablet:
            return tablet ?? mobile;
          case DeviceScreenType.desktop:
            return desktop ?? tablet ?? mobile;
        }
      },
    );
  }
}

/// A container that centers its child and enforces a maximum content width.
///
/// Prevents UI elements from stretching awkwardly on wide screens (tablets, desktops, landscape).
/// Automatically applies responsive horizontal padding based on screen width.
///
/// Usage:
/// ```dart
/// Scaffold(
///   body: ResponsiveContainer(
///     child: SingleChildScrollView(
///       child: Column(...),
///     ),
///   ),
/// )
/// ```
class ResponsiveContainer extends StatelessWidget {
  /// The content child widget.
  final Widget child;

  /// Optional maximum content width override.
  /// Defaults to [ResponsiveHelper.maxContentWidth].
  final double? maxWidth;

  /// Custom padding override. If omitted, uses responsive padding.
  final EdgeInsetsGeometry? padding;

  /// Alignment within the available space (defaults to top center).
  final AlignmentGeometry alignment;

  /// Background decoration for the container.
  final Decoration? decoration;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? context.maxContentWidth;
    final effectivePadding = padding ?? context.responsiveContentPadding;

    return Container(
      decoration: decoration,
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: Padding(padding: effectivePadding, child: child),
      ),
    );
  }
}

/// Responsive flex layout that switches between a [Row] and [Column] based on screen size.
///
/// On mobile (< 600dp), renders as a [Column].
/// On tablet and desktop (≥ 600dp), renders as a [Row] (or vice versa with [reversed]).
class ResponsiveRowColumn extends StatelessWidget {
  /// Children widgets to arrange.
  final List<Widget> children;

  /// Custom boolean condition to force row layout.
  /// If null, switches based on [DeviceScreenType.tablet] or larger.
  final bool? isRow;

  /// Spacing between children.
  final double spacing;

  /// Main axis alignment when displayed as a Row.
  final MainAxisAlignment rowMainAxisAlignment;

  /// Cross axis alignment when displayed as a Row.
  final CrossAxisAlignment rowCrossAxisAlignment;

  /// Main axis alignment when displayed as a Column.
  final MainAxisAlignment columnMainAxisAlignment;

  /// Cross axis alignment when displayed as a Column.
  final CrossAxisAlignment columnCrossAxisAlignment;

  /// Main axis size for the layout.
  final MainAxisSize mainAxisSize;

  const ResponsiveRowColumn({
    super.key,
    required this.children,
    this.isRow,
    this.spacing = AppSpacing.md,
    this.rowMainAxisAlignment = MainAxisAlignment.start,
    this.rowCrossAxisAlignment = CrossAxisAlignment.center,
    this.columnMainAxisAlignment = MainAxisAlignment.start,
    this.columnCrossAxisAlignment = CrossAxisAlignment.stretch,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenType, constraints) {
        final renderAsRow =
            isRow ??
            (screenType == DeviceScreenType.tablet ||
                screenType == DeviceScreenType.desktop);

        if (renderAsRow) {
          final rowChildren = <Widget>[];
          for (var i = 0; i < children.length; i++) {
            rowChildren.add(
              children[i] is Expanded || children[i] is Flexible
                  ? children[i]
                  : Expanded(child: children[i]),
            );
            if (i < children.length - 1 && spacing > 0) {
              rowChildren.add(SizedBox(width: spacing));
            }
          }

          return Row(
            mainAxisAlignment: rowMainAxisAlignment,
            crossAxisAlignment: rowCrossAxisAlignment,
            mainAxisSize: mainAxisSize,
            children: rowChildren,
          );
        } else {
          final columnChildren = <Widget>[];
          for (var i = 0; i < children.length; i++) {
            columnChildren.add(children[i]);
            if (i < children.length - 1 && spacing > 0) {
              columnChildren.add(SizedBox(height: spacing));
            }
          }

          return Column(
            mainAxisAlignment: columnMainAxisAlignment,
            crossAxisAlignment: columnCrossAxisAlignment,
            mainAxisSize: mainAxisSize,
            children: columnChildren,
          );
        }
      },
    );
  }
}

/// Responsive grid layout that adjusts its column count based on available width.
///
/// Designed for stat cards, achievement grids, and developer dashboards.
class ResponsiveGrid extends StatelessWidget {
  /// Grid item widgets.
  final List<Widget> children;

  /// Column count for compact screens (< 360dp). Default 1.
  final int compactColumns;

  /// Column count for mobile screens (360dp – 599dp). Default 2.
  final int mobileColumns;

  /// Column count for tablet screens (600dp – 1023dp). Default 3.
  final int tabletColumns;

  /// Column count for desktop screens (≥ 1024dp). Default 4.
  final int desktopColumns;

  /// Horizontal and vertical spacing between items.
  final double spacing;

  /// Aspect ratio for grid items (width / height).
  final double childAspectRatio;

  /// Whether the grid shrinks to fit its children.
  final bool shrinkWrap;

  /// Scroll physics for the grid.
  final ScrollPhysics? physics;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.compactColumns = 1,
    this.mobileColumns = 2,
    this.tabletColumns = 3,
    this.desktopColumns = 4,
    this.spacing = AppSpacing.md,
    this.childAspectRatio = 1.0,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenType, constraints) {
        final columns = switch (screenType) {
          DeviceScreenType.compact => compactColumns,
          DeviceScreenType.mobile => mobileColumns,
          DeviceScreenType.tablet => tabletColumns,
          DeviceScreenType.desktop => desktopColumns,
        };

        return GridView.builder(
          shrinkWrap: shrinkWrap,
          physics: physics,
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}
