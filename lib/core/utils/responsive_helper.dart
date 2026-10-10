import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Device screen classification based on screen width breakpoints.
///
/// Categories:
/// - [compact]: Very small mobile devices (< 360dp width)
/// - [mobile]: Standard to large mobile phones (360dp – 599dp width)
/// - [tablet]: Tablets and small foldables (600dp – 1023dp width)
/// - [desktop]: Desktop and large screens (≥ 1024dp width)
enum DeviceScreenType {
  /// Extra small phones (e.g., small older Android devices, iPhone SE 1st gen)
  compact,

  /// Standard and large mobile phones (e.g., Pixel 8, iPhone 15 Pro)
  mobile,

  /// Tablets, large foldables, landscape phones
  tablet,

  /// Desktop monitors, large landscape tablets
  desktop,
}

/// Centralized responsive breakpoints and content width constraints.
class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  // ============================================================================
  // SCREEN WIDTH BREAKPOINTS
  // ============================================================================

  /// Small phone threshold (360dp)
  static const double compact = AppSpacing.breakpointSmall;

  /// Tablet threshold (600dp)
  static const double tablet = AppSpacing.breakpointTablet;

  /// Desktop threshold (1024dp)
  static const double desktop = 1024.0;

  /// Wide desktop threshold (1440dp)
  static const double wideDesktop = 1440.0;

  // ============================================================================
  // MAXIMUM CONTENT WIDTHS (for readability and game-like card layout)
  // ============================================================================

  /// Maximum content width for mobile screens
  static const double maxContentWidthMobile = 600.0;

  /// Maximum content width for tablet screens
  static const double maxContentWidthTablet = 840.0;

  /// Maximum content width for desktop screens
  static const double maxContentWidthDesktop = 1140.0;
}

/// Reusable responsive helper methods and screen queries.
///
/// Supports mobile-first development with graceful scaling to tablets and desktops.
///
/// Usage:
/// ```dart
/// if (ResponsiveHelper.isMobile(context)) {
///   // Mobile layout
/// }
///
/// final padding = ResponsiveHelper.responsiveHorizontalPadding(context);
/// ```
class ResponsiveHelper {
  ResponsiveHelper._();

  // ============================================================================
  // SCREEN TYPE CLASSIFICATION
  // ============================================================================

  /// Get the [DeviceScreenType] from [BuildContext].
  static DeviceScreenType getDeviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return getDeviceTypeFromWidth(width);
  }

  /// Get the [DeviceScreenType] directly from a width value.
  static DeviceScreenType getDeviceTypeFromWidth(double width) {
    if (width < ResponsiveBreakpoints.compact) {
      return DeviceScreenType.compact;
    } else if (width < ResponsiveBreakpoints.tablet) {
      return DeviceScreenType.mobile;
    } else if (width < ResponsiveBreakpoints.desktop) {
      return DeviceScreenType.tablet;
    } else {
      return DeviceScreenType.desktop;
    }
  }

  // ============================================================================
  // CONVENIENCE BOOLEAN QUERIES
  // ============================================================================

  /// Whether the screen is a compact/small phone (< 360dp width).
  static bool isCompact(BuildContext context) {
    return MediaQuery.sizeOf(context).width < ResponsiveBreakpoints.compact;
  }

  /// Whether the screen is a mobile phone (< 600dp width).
  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < ResponsiveBreakpoints.tablet;
  }

  /// Whether the screen is a tablet (600dp ≤ width < 1024dp).
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= ResponsiveBreakpoints.tablet &&
        width < ResponsiveBreakpoints.desktop;
  }

  /// Whether the screen is a desktop (≥ 1024dp width).
  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= ResponsiveBreakpoints.desktop;
  }

  /// Whether the screen is tablet size or larger (≥ 600dp width).
  static bool isTabletOrLarger(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= ResponsiveBreakpoints.tablet;
  }

  // ============================================================================
  // ORIENTATION HELPERS
  // ============================================================================

  /// Whether the device is currently in portrait orientation.
  static bool isPortrait(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.portrait;
  }

  /// Whether the device is currently in landscape orientation.
  static bool isLandscape(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.landscape;
  }

  // ============================================================================
  // DIMENSION HELPERS
  // ============================================================================

  /// Current screen width in logical pixels.
  static double screenWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  /// Current screen height in logical pixels.
  static double screenHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height;
  }

  // ============================================================================
  // VALUE RESOLUTION
  // ============================================================================

  /// Resolves a value [T] based on current [DeviceScreenType].
  ///
  /// Falls back in order:
  /// - `compact` -> `mobile`
  /// - `tablet` -> `mobile`
  /// - `desktop` -> `tablet` -> `mobile`
  static T responsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? compact,
    T? tablet,
    T? desktop,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceScreenType.compact:
        return compact ?? mobile;
      case DeviceScreenType.mobile:
        return mobile;
      case DeviceScreenType.tablet:
        return tablet ?? mobile;
      case DeviceScreenType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  // ============================================================================
  // PADDING & CONTENT WIDTH HELPERS
  // ============================================================================

  /// Get responsive horizontal padding based on screen width.
  static double responsiveHorizontalPadding(BuildContext context) {
    final width = screenWidth(context);
    return AppSpacing.getResponsiveHorizontalPadding(width);
  }

  /// Get responsive [EdgeInsets] for full screen content padding.
  static EdgeInsets responsiveContentPadding(BuildContext context) {
    final horizontal = responsiveHorizontalPadding(context);
    final vertical = responsiveValue<double>(
      context,
      compact: AppSpacing.sm,
      mobile: AppSpacing.md,
      tablet: AppSpacing.lg,
      desktop: AppSpacing.xl,
    );
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }

  /// Maximum recommended content width for readability on large screens.
  static double maxContentWidth(BuildContext context) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceScreenType.compact:
      case DeviceScreenType.mobile:
        return ResponsiveBreakpoints.maxContentWidthMobile;
      case DeviceScreenType.tablet:
        return ResponsiveBreakpoints.maxContentWidthTablet;
      case DeviceScreenType.desktop:
        return ResponsiveBreakpoints.maxContentWidthDesktop;
    }
  }

  /// Recommended column count for responsive grid layouts.
  static int gridColumnCount(
    BuildContext context, {
    int compact = 1,
    int mobile = 2,
    int tablet = 3,
    int desktop = 4,
  }) {
    return responsiveValue<int>(
      context,
      compact: compact,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}

/// Extension on [BuildContext] for convenient responsive access.
extension ResponsiveContextExtension on BuildContext {
  /// Current device screen classification.
  DeviceScreenType get deviceType => ResponsiveHelper.getDeviceType(this);

  /// Whether current screen width is < 360dp.
  bool get isCompact => ResponsiveHelper.isCompact(this);

  /// Whether current screen width is < 600dp.
  bool get isMobile => ResponsiveHelper.isMobile(this);

  /// Whether current screen is a tablet (600dp ≤ width < 1024dp).
  bool get isTablet => ResponsiveHelper.isTablet(this);

  /// Whether current screen is desktop size (≥ 1024dp).
  bool get isDesktop => ResponsiveHelper.isDesktop(this);

  /// Whether current screen is tablet size or larger (≥ 600dp).
  bool get isTabletOrLarger => ResponsiveHelper.isTabletOrLarger(this);

  /// Whether device is in portrait orientation.
  bool get isPortrait => ResponsiveHelper.isPortrait(this);

  /// Whether device is in landscape orientation.
  bool get isLandscape => ResponsiveHelper.isLandscape(this);

  /// Screen width in logical pixels.
  double get screenWidth => ResponsiveHelper.screenWidth(this);

  /// Screen height in logical pixels.
  double get screenHeight => ResponsiveHelper.screenHeight(this);

  /// Responsive value resolver.
  T responsiveValue<T>({required T mobile, T? compact, T? tablet, T? desktop}) {
    return ResponsiveHelper.responsiveValue<T>(
      this,
      mobile: mobile,
      compact: compact,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Responsive horizontal padding value.
  double get responsiveHorizontalPadding =>
      ResponsiveHelper.responsiveHorizontalPadding(this);

  /// Responsive screen content padding [EdgeInsets].
  EdgeInsets get responsiveContentPadding =>
      ResponsiveHelper.responsiveContentPadding(this);

  /// Maximum content width constraint for current screen size.
  double get maxContentWidth => ResponsiveHelper.maxContentWidth(this);
}
