import 'package:flutter/material.dart';

/// Centralized spacing system for the Open Source Developer Command Center.
///
/// Design Direction:
/// - Mobile-first spacing values optimized for phone screens
/// - Consistent 4px base unit for harmonious layouts
/// - Clear hierarchy from micro (4px) to macro (64px) spacing
/// - Supports playful, premium, game-like aesthetic with breathing room
///
/// Base Scale: 4px, 8px, 16px, 24px, 32px, 48px, 64px
///
/// Usage:
/// ```dart
/// Padding(
///   padding: EdgeInsets.all(AppSpacing.md),
///   child: Text('Hello'),
/// )
/// ```
class AppSpacing {
  AppSpacing._(); // Private constructor to prevent instantiation

  // ============================================================================
  // BASE SPACING SCALE
  // ============================================================================

  /// Extra extra small spacing - 4px
  /// Use for: Tight gaps between related elements, icon padding
  static const double xxs = 4.0;

  /// Extra small spacing - 8px
  /// Use for: Small gaps, compact list items, chip padding
  static const double xs = 8.0;

  /// Small spacing - 12px
  /// Use for: Moderate gaps between elements, button padding
  static const double sm = 12.0;

  /// Medium spacing - 16px (base unit)
  /// Use for: Default padding, card padding, section gaps
  static const double md = 16.0;

  /// Large spacing - 24px
  /// Use for: Section separation, card margins, prominent spacing
  static const double lg = 24.0;

  /// Extra large spacing - 32px
  /// Use for: Major section breaks, screen padding on larger devices
  static const double xl = 32.0;

  /// Extra extra large spacing - 48px
  /// Use for: Hero sections, major visual breaks
  static const double xxl = 48.0;

  /// Extra extra extra large spacing - 64px
  /// Use for: Maximum separation, splash screen elements
  static const double xxxl = 64.0;

  // ============================================================================
  // SCREEN PADDING
  // ============================================================================

  /// Default screen horizontal padding - 16px
  /// Standard edge padding for most screens
  static const double screenHorizontal = md;

  /// Default screen vertical padding - 16px
  /// Standard top/bottom padding for scrollable screens
  static const double screenVertical = md;

  /// Screen padding for larger content areas - 20px
  /// Use for screens with wider content
  static const double screenHorizontalLarge = 20.0;

  /// Screen padding EdgeInsets - horizontal only
  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(
    horizontal: screenHorizontal,
  );

  /// Screen padding EdgeInsets - vertical only
  static const EdgeInsets screenPaddingVertical = EdgeInsets.symmetric(
    vertical: screenVertical,
  );

  /// Screen padding EdgeInsets - all sides
  static const EdgeInsets screenPadding = EdgeInsets.all(screenHorizontal);

  /// Screen padding with extra top space (for content below app bar)
  static const EdgeInsets screenPaddingWithTop = EdgeInsets.only(
    left: screenHorizontal,
    right: screenHorizontal,
    top: lg,
    bottom: screenVertical,
  );

  // ============================================================================
  // CARD SPACING
  // ============================================================================

  /// Card internal padding - 16px
  static const double cardPadding = md;

  /// Card internal padding for compact cards - 12px
  static const double cardPaddingCompact = sm;

  /// Card internal padding for spacious cards - 20px
  static const double cardPaddingLarge = 20.0;

  /// Card margin (gap between cards) - 12px
  static const double cardMargin = sm;

  /// Card margin for prominent cards - 16px
  static const double cardMarginLarge = md;

  /// Card padding EdgeInsets
  static const EdgeInsets cardPaddingInsets = EdgeInsets.all(cardPadding);

  /// Compact card padding EdgeInsets
  static const EdgeInsets cardPaddingCompactInsets = EdgeInsets.all(
    cardPaddingCompact,
  );

  /// Large card padding EdgeInsets
  static const EdgeInsets cardPaddingLargeInsets = EdgeInsets.all(
    cardPaddingLarge,
  );

  // ============================================================================
  // SECTION SPACING
  // ============================================================================

  /// Gap between sections on a screen - 24px
  static const double sectionGap = lg;

  /// Gap between major sections - 32px
  static const double sectionGapLarge = xl;

  /// Gap within a section (between elements) - 16px
  static const double sectionItemGap = md;

  /// Gap between section header and content - 12px
  static const double sectionHeaderGap = sm;

  // ============================================================================
  // LIST SPACING
  // ============================================================================

  /// Gap between list items - 12px
  static const double listItemGap = sm;

  /// Gap between list items (comfortable) - 16px
  static const double listItemGapComfortable = md;

  /// Padding inside list items - 16px
  static const double listItemPadding = md;

  /// Padding inside compact list items - 12px
  static const double listItemPaddingCompact = sm;

  /// Leading/trailing padding for list items - 16px
  static const double listItemHorizontal = md;

  /// List item padding EdgeInsets
  static const EdgeInsets listItemPaddingInsets = EdgeInsets.symmetric(
    horizontal: listItemHorizontal,
    vertical: listItemPadding,
  );

  /// Compact list item padding EdgeInsets
  static const EdgeInsets listItemPaddingCompactInsets = EdgeInsets.symmetric(
    horizontal: listItemHorizontal,
    vertical: listItemPaddingCompact,
  );

  // ============================================================================
  // GRID SPACING
  // ============================================================================

  /// Gap between grid items - 12px
  static const double gridGap = sm;

  /// Gap between grid items (comfortable) - 16px
  static const double gridGapComfortable = md;

  /// Gap between grid items (spacious) - 24px
  static const double gridGapSpacious = lg;

  /// Padding around grid containers - 16px
  static const double gridPadding = md;

  // ============================================================================
  // BUTTON SPACING
  // ============================================================================

  /// Button internal horizontal padding - 24px
  static const double buttonPaddingHorizontal = lg;

  /// Button internal vertical padding - 12px
  static const double buttonPaddingVertical = sm;

  /// Button internal horizontal padding (large) - 32px
  static const double buttonPaddingHorizontalLarge = xl;

  /// Button internal vertical padding (large) - 16px
  static const double buttonPaddingVerticalLarge = md;

  /// Button internal horizontal padding (small) - 16px
  static const double buttonPaddingHorizontalSmall = md;

  /// Button internal vertical padding (small) - 8px
  static const double buttonPaddingVerticalSmall = xs;

  /// Gap between buttons - 12px
  static const double buttonGap = sm;

  /// Gap between buttons (spacious) - 16px
  static const double buttonGapSpacious = md;

  /// Button padding EdgeInsets
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: buttonPaddingHorizontal,
    vertical: buttonPaddingVertical,
  );

  /// Large button padding EdgeInsets
  static const EdgeInsets buttonPaddingLarge = EdgeInsets.symmetric(
    horizontal: buttonPaddingHorizontalLarge,
    vertical: buttonPaddingVerticalLarge,
  );

  /// Small button padding EdgeInsets
  static const EdgeInsets buttonPaddingSmall = EdgeInsets.symmetric(
    horizontal: buttonPaddingHorizontalSmall,
    vertical: buttonPaddingVerticalSmall,
  );

  // ============================================================================
  // ICON SPACING
  // ============================================================================

  /// Gap between icon and text - 8px
  static const double iconTextGap = xs;

  /// Gap between icon and text (comfortable) - 12px
  static const double iconTextGapComfortable = sm;

  /// Padding around icons in buttons - 8px
  static const double iconPadding = xs;

  /// Size for small icons - 16px
  static const double iconSizeSmall = 16.0;

  /// Size for medium icons (default) - 24px
  static const double iconSizeMedium = 24.0;

  /// Size for large icons - 32px
  static const double iconSizeLarge = 32.0;

  /// Size for extra large icons (hero, splash) - 48px
  static const double iconSizeXLarge = 48.0;

  // ============================================================================
  // FORM SPACING
  // ============================================================================

  /// Gap between form fields - 16px
  static const double formFieldGap = md;

  /// Gap between form fields (comfortable) - 20px
  static const double formFieldGapComfortable = 20.0;

  /// Padding inside form fields - 16px
  static const double formFieldPadding = md;

  /// Padding inside compact form fields - 12px
  static const double formFieldPaddingCompact = sm;

  /// Gap between form label and field - 8px
  static const double formLabelGap = xs;

  /// Gap between form sections - 24px
  static const double formSectionGap = lg;

  // ============================================================================
  // BOTTOM NAVIGATION SPACING
  // ============================================================================

  /// Bottom navigation bar height - 64px
  static const double bottomNavHeight = 64.0;

  /// Bottom navigation bar height (compact) - 56px
  static const double bottomNavHeightCompact = 56.0;

  /// Bottom navigation item padding - 8px
  static const double bottomNavItemPadding = xs;

  /// Gap between bottom nav icon and label - 4px
  static const double bottomNavIconLabelGap = xxs;

  // ============================================================================
  // APP BAR SPACING
  // ============================================================================

  /// App bar height - 56px (Material standard)
  static const double appBarHeight = 56.0;

  /// App bar height (large) - 64px
  static const double appBarHeightLarge = 64.0;

  /// App bar horizontal padding - 16px
  static const double appBarHorizontal = md;

  /// App bar title spacing from leading - 16px
  static const double appBarTitleSpacing = md;

  // ============================================================================
  // DIALOG/MODAL SPACING
  // ============================================================================

  /// Dialog padding - 24px
  static const double dialogPadding = lg;

  /// Dialog content spacing - 16px
  static const double dialogContentGap = md;

  /// Dialog title to content gap - 16px
  static const double dialogTitleGap = md;

  /// Dialog action buttons gap - 8px
  static const double dialogActionGap = xs;

  /// Dialog padding EdgeInsets
  static const EdgeInsets dialogPaddingInsets = EdgeInsets.all(dialogPadding);

  // ============================================================================
  // BORDER RADIUS
  // ============================================================================

  /// Extra small border radius - 4px
  /// Use for: Small chips, badges
  static const double radiusXs = 4.0;

  /// Small border radius - 8px
  /// Use for: Buttons, small cards
  static const double radiusSm = 8.0;

  /// Medium border radius - 12px
  /// Use for: Standard cards, inputs
  static const double radiusMd = 12.0;

  /// Large border radius - 16px
  /// Use for: Prominent cards, hero sections
  static const double radiusLg = 16.0;

  /// Extra large border radius - 24px
  /// Use for: Major cards, feature sections
  static const double radiusXl = 24.0;

  /// Full circular radius - 999px
  /// Use for: Circular avatars, pills
  static const double radiusFull = 999.0;

  /// Border radius for small elements
  static const BorderRadius borderRadiusXs = BorderRadius.all(
    Radius.circular(radiusXs),
  );

  /// Border radius for buttons, small cards
  static const BorderRadius borderRadiusSm = BorderRadius.all(
    Radius.circular(radiusSm),
  );

  /// Border radius for standard cards, inputs
  static const BorderRadius borderRadiusMd = BorderRadius.all(
    Radius.circular(radiusMd),
  );

  /// Border radius for prominent cards
  static const BorderRadius borderRadiusLg = BorderRadius.all(
    Radius.circular(radiusLg),
  );

  /// Border radius for major cards
  static const BorderRadius borderRadiusXl = BorderRadius.all(
    Radius.circular(radiusXl),
  );

  /// Circular border radius for avatars, pills
  static const BorderRadius borderRadiusFull = BorderRadius.all(
    Radius.circular(radiusFull),
  );

  // ============================================================================
  // GAMIFICATION SPACING
  // ============================================================================

  /// XP bar height - 8px
  static const double xpBarHeight = 8.0;

  /// XP bar height (prominent) - 12px
  static const double xpBarHeightLarge = 12.0;

  /// Gap between XP bar and label - 8px
  static const double xpBarLabelGap = xs;

  /// Achievement card padding - 16px
  static const double achievementCardPadding = md;

  /// Gap between achievement icon and text - 12px
  static const double achievementIconGap = sm;

  /// Streak indicator size - 32px
  static const double streakIndicatorSize = 32.0;

  /// Quest card padding - 16px
  static const double questCardPadding = md;

  /// Gap between quest items - 12px
  static const double questItemGap = sm;

  // ============================================================================
  // CONTRIBUTION/ACTIVITY SPACING
  // ============================================================================

  /// Contribution calendar cell size - 12px
  static const double contributionCellSize = 12.0;

  /// Contribution calendar cell gap - 4px
  static const double contributionCellGap = xxs;

  /// Activity card padding - 16px
  static const double activityCardPadding = md;

  /// Gap between activity items - 12px
  static const double activityItemGap = sm;

  /// PR/Issue status indicator size - 16px
  static const double statusIndicatorSize = 16.0;

  // ============================================================================
  // SPECIAL ELEMENT SPACING
  // ============================================================================

  /// Avatar size small - 32px
  static const double avatarSizeSmall = 32.0;

  /// Avatar size medium - 40px
  static const double avatarSizeMedium = 40.0;

  /// Avatar size large - 56px
  static const double avatarSizeLarge = 56.0;

  /// Avatar size extra large - 80px
  static const double avatarSizeXLarge = 80.0;

  /// Badge size - 20px
  static const double badgeSize = 20.0;

  /// Badge offset from parent - 4px
  static const double badgeOffset = xxs;

  /// Divider thickness - 1px
  static const double dividerThickness = 1.0;

  /// Chip height - 32px
  static const double chipHeight = 32.0;

  /// Chip padding horizontal - 12px
  static const double chipPaddingHorizontal = sm;

  // ============================================================================
  // RESPONSIVE BREAKPOINTS
  // ============================================================================

  /// Small phone breakpoint - 360dp
  static const double breakpointSmall = 360.0;

  /// Medium phone breakpoint - 400dp
  static const double breakpointMedium = 400.0;

  /// Large phone breakpoint - 480dp
  static const double breakpointLarge = 480.0;

  /// Tablet breakpoint - 600dp
  static const double breakpointTablet = 600.0;

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Get responsive horizontal padding based on screen width
  static double getResponsiveHorizontalPadding(double screenWidth) {
    if (screenWidth < breakpointSmall) {
      return md; // 16px for very small phones
    } else if (screenWidth < breakpointMedium) {
      return md; // 16px for small phones
    } else if (screenWidth < breakpointLarge) {
      return screenHorizontalLarge; // 20px for medium phones
    } else if (screenWidth < breakpointTablet) {
      return lg; // 24px for large phones
    } else {
      return xl; // 32px for tablets and larger
    }
  }

  /// Get responsive EdgeInsets based on screen width
  static EdgeInsets getResponsivePadding(double screenWidth) {
    return EdgeInsets.all(getResponsiveHorizontalPadding(screenWidth));
  }

  /// Get EdgeInsets with only horizontal padding
  static EdgeInsets horizontal(double value) {
    return EdgeInsets.symmetric(horizontal: value);
  }

  /// Get EdgeInsets with only vertical padding
  static EdgeInsets vertical(double value) {
    return EdgeInsets.symmetric(vertical: value);
  }

  /// Get EdgeInsets with custom values
  static EdgeInsets custom({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return EdgeInsets.only(left: left, top: top, right: right, bottom: bottom);
  }

  /// Get EdgeInsets with symmetric values
  static EdgeInsets symmetric({double horizontal = 0, double vertical = 0}) {
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }

  /// Get SizedBox with vertical spacing
  static SizedBox verticalSpace(double height) {
    return SizedBox(height: height);
  }

  /// Get SizedBox with horizontal spacing
  static SizedBox horizontalSpace(double width) {
    return SizedBox(width: width);
  }

  // Pre-defined vertical spacers
  static final SizedBox vSpaceXxs = verticalSpace(xxs);
  static final SizedBox vSpaceXs = verticalSpace(xs);
  static final SizedBox vSpaceSm = verticalSpace(sm);
  static final SizedBox vSpaceMd = verticalSpace(md);
  static final SizedBox vSpaceLg = verticalSpace(lg);
  static final SizedBox vSpaceXl = verticalSpace(xl);
  static final SizedBox vSpaceXxl = verticalSpace(xxl);

  // Pre-defined horizontal spacers
  static final SizedBox hSpaceXxs = horizontalSpace(xxs);
  static final SizedBox hSpaceXs = horizontalSpace(xs);
  static final SizedBox hSpaceSm = horizontalSpace(sm);
  static final SizedBox hSpaceMd = horizontalSpace(md);
  static final SizedBox hSpaceLg = horizontalSpace(lg);
  static final SizedBox hSpaceXl = horizontalSpace(xl);
  static final SizedBox hSpaceXxl = horizontalSpace(xxl);
}
