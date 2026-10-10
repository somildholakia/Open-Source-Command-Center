import 'dart:ui';

import 'package:flutter/material.dart';

/// Centralized color palette for the Open Source Developer Command Center.
///
/// Design Direction:
/// - Dark/navy foundation for a premium, game-like aesthetic
/// - Vibrant accent colors for energy and playfulness
/// - High contrast for accessibility
/// - Fully supported light theme with the same vibrant identity
///
/// Architecture:
/// - Static `const` tokens hold the raw palette for both brightnesses.
/// - Theme-resolved getters (`surface`, `border`, `primaryAccent`, ...)
///   return the correct value for the active theme. They are configured by
///   [AppTheme] via [configureForBrightness] when the `ThemeData` is built,
///   so every widget resolves consistently without passing BuildContext.
/// - Accent colors (cyan/purple/pink/green/orange) are intentional brand
///   colors. Where they appear as text or icons on light backgrounds, use the
///   `*Accent` getters (or the `*Dark` constants) to keep contrast readable.
///
/// Usage:
/// ```dart
/// // Theme-aware surfaces (never hardcode dark navy in widgets):
/// Container(color: AppColors.surface)
///
/// // Accent colors that stay readable in both themes:
/// Icon(Icons.star, color: AppColors.primaryAccent)
/// ```
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // ============================================================================
  // DARK THEME FOUNDATION COLORS
  // ============================================================================

  /// Deep navy background - dark theme primary app background
  static const Color backgroundDark = Color(0xFF0A0E27);

  /// Slightly lighter navy for elevated surfaces - dark theme
  static const Color surfaceDark = Color(0xFF151932);

  /// Even lighter surface for nested elevation - dark theme
  static const Color surfaceElevatedDark = Color(0xFF1E2340);

  /// Subtle borders and dividers - dark theme
  static const Color borderDark = Color(0xFF2A3354);

  /// Stronger borders for emphasis - dark theme
  static const Color borderStrongDark = Color(0xFF3D4563);

  // ============================================================================
  // LIGHT THEME FOUNDATION COLORS
  // ============================================================================

  /// Soft cool-grey background - light theme primary app background.
  /// Deliberately darker than card surfaces so white cards still read
  /// as elevated.
  static const Color backgroundLight = Color(0xFFF2F5FA);

  /// White surface - light theme cards and sheets
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// Slightly darker surface for nested elevation - light theme
  static const Color surfaceElevatedLight = Color(0xFFE7EBF2);

  /// Subtle borders and dividers - light theme
  static const Color borderLight = Color(0xFFD9DFE9);

  /// Stronger borders for emphasis - light theme
  static const Color borderStrongLight = Color(0xFFB9C2D4);

  // ============================================================================
  // TEXT COLORS
  // ============================================================================

  /// Primary text on dark surfaces
  static const Color textOnDark = Color(0xFFFFFFFF);

  /// Faint/disabled text on dark surfaces
  static const Color textSubtleOnDark = Color(0xFF6B7394);

  /// Secondary text on dark surfaces
  static const Color textSecondaryOnDark = Color(0xFFB0B8D4);

  /// Primary text on light surfaces - deep navy, keeps brand identity
  static const Color textOnLight = Color(0xFF101426);

  /// Faint/disabled text on light surfaces
  static const Color textSubtleOnLight = Color(0xFF5A6379);

  /// Text on vibrant primary (cyan) backgrounds
  static const Color textOnPrimary = Color(0xFF0A0E27);

  /// Text on pink accent backgrounds
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // ============================================================================
  // PRIMARY ACCENT COLORS (vibrant cyan)
  // ============================================================================

  /// Vibrant cyan - primary brand color (dark theme)
  static const Color primary = Color(0xFF00E5FF);

  /// Darker cyan for hover/pressed states (dark theme)
  static const Color primaryDark = Color(0xFF00B8D4);

  /// Deep cyan - readable primary on light backgrounds (≥4.5:1 on white)
  static const Color primaryDeep = Color(0xFF007A8A);

  /// Lighter cyan for highlights
  static const Color primaryLight = Color(0xFF6EFFFF);

  /// Deep cyan-tinted navy used as surface tint in the dark theme
  static const Color primarySubtle = Color(0xFF0A2A2F);

  // ============================================================================
  // SECONDARY ACCENT COLORS (vibrant purple)
  // ============================================================================

  /// Vibrant purple - secondary accent (dark theme)
  static const Color secondary = Color(0xFFB388FF);

  /// Deep purple - readable secondary on light backgrounds
  static const Color secondaryDark = Color(0xFF7C4DFF);

  /// Lighter purple for highlights
  static const Color secondaryLight = Color(0xFFE1BEE7);

  // ============================================================================
  // TERTIARY ACCENT COLORS (pink / green / orange)
  // ============================================================================

  /// Vibrant pink/magenta - tertiary accent (dark theme)
  static const Color accent = Color(0xFFFF4081);

  /// Deep pink/magenta - readable pink on light backgrounds
  static const Color accentDark = Color(0xFFC2185B);

  /// Vibrant green for growth/success (dark theme)
  static const Color accentGreen = Color(0xFF00E676);

  /// Deep green - readable green on light backgrounds (≥4.5:1 on white)
  static const Color accentGreenDark = Color(0xFF00875A);

  /// Vibrant orange for energy/action (dark theme)
  static const Color accentOrange = Color(0xFFFF9100);

  /// Deep orange - readable orange on light backgrounds
  static const Color accentOrangeDark = Color(0xFFB25000);

  // ============================================================================
  // SEMANTIC STATUS COLORS
  // ============================================================================

  /// Success state - vibrant green (dark theme)
  static const Color success = Color(0xFF00E676);

  /// Success state - deep green (light theme text/icons)
  static const Color successDark = Color(0xFF00875A);

  static const Color successBackgroundDark = Color(0xFF0A2F1A);
  static const Color successBackgroundLight = Color(0xFFD7F5E4);

  /// Warning state - vibrant amber (dark theme)
  static const Color warning = Color(0xFFFFD600);

  /// Warning state - deep amber (light theme text/icons, ≥4.5:1 on white)
  static const Color warningDark = Color(0xFF7A6000);

  static const Color warningBackgroundDark = Color(0xFF2F2A0A);
  static const Color warningBackgroundLight = Color(0xFFFFF3C4);

  /// Error state - vibrant red (dark theme)
  static const Color error = Color(0xFFFF5252);

  /// Error state - deep red (light theme text/icons)
  static const Color errorDark = Color(0xFFC62828);

  static const Color errorBackgroundDark = Color(0xFF2F0A0A);
  static const Color errorBackgroundLight = Color(0xFFFFDAD6);

  /// Info state - vibrant blue (dark theme)
  static const Color info = Color(0xFF448AFF);

  /// Info state - deep blue (light theme text/icons)
  static const Color infoDark = Color(0xFF1565C0);

  static const Color infoBackgroundDark = Color(0xFF0A1A2F);
  static const Color infoBackgroundLight = Color(0xFFD6E7FF);

  // ============================================================================
  // GAMIFICATION COLORS
  // ============================================================================

  /// Streak indicator - fiery orange (dark theme)
  static const Color streak = Color(0xFFFF6D00);

  /// Streak indicator - deep orange (light theme text/icons)
  static const Color streakDark = Color(0xFFB25000);

  /// Achievement/badge - golden yellow (dark theme)
  static const Color achievement = Color(0xFFFFD700);

  /// Achievement/badge - deep gold (light theme text/icons, ≥4.5:1 on white)
  static const Color achievementDark = Color(0xFF7A6000);

  /// Quest/challenge - vibrant cyan (follows the primary brand color)
  static const Color quest = primary;

  // ============================================================================
  // GITHUB INTEGRATION COLORS
  // ============================================================================

  static const Color pullRequest = Color(0xFF8957E5);
  static const Color pullRequestDark = Color(0xFF6639BA);
  static const Color issue = Color(0xFF3FB950);
  static const Color issueDark = Color(0xFF1A7F37);
  static const Color commit = Color(0xFF79C0FF);
  static const Color commitDark = Color(0xFF0550AE);
  static const Color review = Color(0xFFFFAB00);
  static const Color reviewDark = Color(0xFF9A6700);
  static const Color merged = Color(0xFFB388FF);
  static const Color mergedDark = Color(0xFF8250DF);
  static const Color closed = Color(0xFFFF5252);
  static const Color closedDark = Color(0xFFCF222E);

  // ============================================================================
  // SPECIAL EFFECTS
  // ============================================================================

  /// Overlay for modals/dialogs
  static const Color overlay = Color(0xCC000000);

  // ============================================================================
  // GRADIENTS (brand gradients work in both themes)
  // ============================================================================

  static const List<Color> gradientPremium = [
    Color(0xFF00E5FF),
    Color(0xFFB388FF),
  ];

  static const List<Color> gradientDark = [
    Color(0xFF0A0E27),
    Color(0xFF151932),
  ];

  // ============================================================================
  // CHART/DATA VISUALIZATION COLORS
  // ============================================================================

  static const List<Color> chartColors = [
    Color(0xFF00E5FF), // Cyan
    Color(0xFFB388FF), // Purple
    Color(0xFFFF4081), // Pink
    Color(0xFF00E676), // Green
    Color(0xFFFFD600), // Amber
    Color(0xFFFF9100), // Orange
    Color(0xFF448AFF), // Blue
    Color(0xFF69F0AE), // Light green
  ];

  // ============================================================================
  // THEME-RESOLVED TOKENS
  // ============================================================================
  //
  // Configured by [AppTheme] via [configureForBrightness] every time a
  // ThemeData is built, so the tokens always match the freshest theme the
  // app produced (MaterialApp caches `theme`/`darkTheme`, so "once at
  // startup" would let the flag drift behind rebuilds).

  static Brightness _brightness = Brightness.dark;

  /// The brightness the resolved tokens currently target.
  static Brightness get brightness => _brightness;

  static bool get _isLight => _brightness == Brightness.light;

  /// Configure every theme-resolved token for [brightness].
  ///
  /// Called by [AppTheme] when building the dark and light `ThemeData`, so
  /// token resolution always matches the theme the app is about to render.
  static void configureForBrightness(Brightness brightness) {
    _brightness = brightness;
  }

  // ---- Foundation surfaces ----

  /// App background for the active theme.
  static Color get background => _isLight ? backgroundLight : backgroundDark;

  /// Card/elevated surface for the active theme.
  static Color get surface => _isLight ? surfaceLight : surfaceDark;

  /// Nested-elevation surface for the active theme.
  static Color get surfaceElevated =>
      _isLight ? surfaceElevatedLight : surfaceElevatedDark;

  /// Subtle border/divider for the active theme.
  static Color get border => _isLight ? borderLight : borderDark;

  /// Stronger border for emphasis in the active theme.
  static Color get borderStrong =>
      _isLight ? borderStrongLight : borderStrongDark;

  // ---- Text ----

  /// Primary text color for the active theme.
  static Color get textPrimary => _isLight ? textOnLight : textOnDark;

  /// Secondary text color for the active theme.
  static Color get textSecondary =>
      _isLight ? textOnLight.withValues(alpha: 0.72) : textSecondaryOnDark;

  /// Faint/disabled text color for the active theme.
  static Color get textTertiary =>
      _isLight ? textSubtleOnLight : textSubtleOnDark;

  // ---- Accents (readable as text/icons in both themes) ----

  /// Cyan accent that stays readable on the active background.
  static Color get primaryAccent => _isLight ? primaryDeep : primary;

  /// Purple accent that stays readable on the active background.
  static Color get secondaryAccent => _isLight ? secondaryDark : secondary;

  /// Pink accent that stays readable on the active background.
  static Color get accentPink => _isLight ? accentDark : accent;

  /// Green accent that stays readable on the active background.
  static Color get accentGreenAccent =>
      _isLight ? accentGreenDark : accentGreen;

  /// Orange accent that stays readable on the active background.
  static Color get accentOrangeAccent =>
      _isLight ? accentOrangeDark : accentOrange;

  /// Success color that stays readable on the active background.
  static Color get successAccent => _isLight ? successDark : success;

  /// Warning color that stays readable on the active background.
  static Color get warningAccent => _isLight ? warningDark : warning;

  /// Error color that stays readable on the active background.
  static Color get errorAccent => _isLight ? errorDark : error;

  /// Info color that stays readable on the active background.
  static Color get infoAccent => _isLight ? infoDark : info;

  /// Streak color that stays readable on the active background.
  static Color get streakAccent => _isLight ? streakDark : streak;

  /// Achievement color that stays readable on the active background.
  static Color get achievementAccent =>
      _isLight ? achievementDark : achievement;

  /// Quest color that stays readable on the active background.
  static Color get questAccent => primaryAccent;

  // ---- Status backgrounds (subtle tints matching the active theme) ----

  static Color get successBackground =>
      _isLight ? successBackgroundLight : successBackgroundDark;

  static Color get warningBackground =>
      _isLight ? warningBackgroundLight : warningBackgroundDark;

  static Color get errorBackground =>
      _isLight ? errorBackgroundLight : errorBackgroundDark;

  static Color get infoBackground =>
      _isLight ? infoBackgroundLight : infoBackgroundDark;

  // ---- GitHub domain colors (readable in both themes) ----

  static Color get pullRequestAccent =>
      _isLight ? pullRequestDark : pullRequest;

  static Color get issueAccent => _isLight ? issueDark : issue;

  static Color get commitAccent => _isLight ? commitDark : commit;

  static Color get reviewAccent => _isLight ? reviewDark : review;

  static Color get mergedAccent => _isLight ? mergedDark : merged;

  static Color get closedAccent => _isLight ? closedDark : closed;

  // ============================================================================
  // STATIC RESOLVERS (for contexts without access to the theme flag)
  // ============================================================================

  /// App background for an explicit [Brightness] (e.g. inside a `const`
  /// widget tree where the resolved getters are not const-safe).
  static Color backgroundFor(Brightness b) =>
      b == Brightness.light ? backgroundLight : backgroundDark;

  /// Card/elevated surface for an explicit [Brightness].
  static Color surfaceFor(Brightness b) =>
      b == Brightness.light ? surfaceLight : surfaceDark;

  /// Nested-elevation surface for an explicit [Brightness].
  static Color surfaceElevatedFor(Brightness b) =>
      b == Brightness.light ? surfaceElevatedLight : surfaceElevatedDark;

  /// Faint/disabled text color for an explicit [Brightness].
  static Color textSubtleFor(Brightness b) =>
      b == Brightness.light ? textSubtleOnLight : textSubtleOnDark;

  // ============================================================================
  // ACCESSIBILITY HELPERS
  // ============================================================================

  /// Check if a color has sufficient contrast against a background
  static bool hasSufficientContrast(Color foreground, Color background) {
    final fgLuminance = foreground.computeLuminance();
    final bgLuminance = background.computeLuminance();
    final contrast =
        (fgLuminance > bgLuminance ? fgLuminance + 0.05 : bgLuminance + 0.05) /
        (fgLuminance > bgLuminance ? bgLuminance + 0.05 : fgLuminance + 0.05);
    return contrast >= 4.5;
  }

  /// Get appropriate text color for any background
  static Color getTextColorForBackground(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? textOnLight : textOnDark;
  }
}
