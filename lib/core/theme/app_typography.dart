import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Centralized typography system for the Open Source Developer Command Center.
///
/// Design Direction:
/// - Playful but readable font hierarchy
/// - Premium, game-like developer aesthetic
/// - Clear visual hierarchy for mobile-first experience
/// - Accessible font sizes and weights
/// - Uses Google Fonts for custom typography
///
/// Font Choices:
/// - **Display/Headings:** Space Grotesk - Geometric, modern, tech-forward
/// - **Body/UI:** Inter - Highly readable, developer-friendly
/// - **Monospace:** JetBrains Mono - Code snippets, stats, XP values
///
/// Usage:
/// ```dart
/// Text(
///   'Level Up!',
///   style: AppTypography.displayLarge,
/// )
/// ```
///
/// Note: Text styles do NOT hardcode colors. Colors should be applied
/// via `.copyWith(color: Theme.of(context).colorScheme.onSurface)` etc.
/// This ensures proper theming for both light and dark modes.
class AppTypography {
  AppTypography._(); // Private constructor to prevent instantiation

  // ============================================================================
  // FONT FAMILIES
  // ============================================================================

  /// Display and heading font - Space Grotesk
  /// Geometric, modern, playful but professional
  static const String _displayFontFamily = 'Space Grotesk';

  /// Body and UI text font - Inter
  /// Highly legible, excellent for interfaces, developer-friendly
  static const String _bodyFontFamily = 'Inter';

  /// Monospace font for code, stats, numbers - JetBrains Mono
  /// Popular developer font, great for XP/stats display
  static const String _monospaceFontFamily = 'JetBrains Mono';

  // ============================================================================
  // DISPLAY STYLES (Hero sections, splash screens)
  // ============================================================================

  /// Extra large display text - for splash screen, major hero sections
  /// 64px, Bold, Space Grotesk
  static TextStyle displayLarge = GoogleFonts.getFont(
    _displayFontFamily,
    fontSize: 64,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -1.5,
  );

  /// Large display text - for major headings, feature titles
  /// 48px, Bold, Space Grotesk
  static TextStyle displayMedium = GoogleFonts.getFont(
    _displayFontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -1.0,
  );

  /// Medium display text - for section headers
  /// 36px, Bold, Space Grotesk
  static TextStyle displaySmall = GoogleFonts.getFont(
    _displayFontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  // ============================================================================
  // HEADING STYLES (Screen titles, card headers)
  // ============================================================================

  /// H1 - Main screen titles
  /// 32px, Bold, Space Grotesk
  static TextStyle headingXLarge = GoogleFonts.getFont(
    _displayFontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.5,
  );

  /// H2 - Section headings
  /// 28px, Bold, Space Grotesk
  static TextStyle headingLarge = GoogleFonts.getFont(
    _displayFontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.25,
  );

  /// H3 - Subsection headings
  /// 24px, SemiBold, Space Grotesk
  static TextStyle headingMedium = GoogleFonts.getFont(
    _displayFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: 0,
  );

  /// H4 - Card titles, list headers
  /// 20px, SemiBold, Space Grotesk
  static TextStyle headingSmall = GoogleFonts.getFont(
    _displayFontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
  );

  /// H5 - Small headers, emphasized labels
  /// 18px, SemiBold, Space Grotesk
  static TextStyle headingXSmall = GoogleFonts.getFont(
    _displayFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
  );

  // ============================================================================
  // TITLE STYLES (Navigation, tabs, modal headers)
  // ============================================================================

  /// Large title - for modal headers, feature names
  /// 22px, SemiBold, Inter
  static TextStyle titleLarge = GoogleFonts.getFont(
    _bodyFontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0,
  );

  /// Medium title - for tab labels, list section headers
  /// 18px, SemiBold, Inter
  static TextStyle titleMedium = GoogleFonts.getFont(
    _bodyFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.15,
  );

  /// Small title - for list item titles, card subtitles
  /// 16px, Medium, Inter
  static TextStyle titleSmall = GoogleFonts.getFont(
    _bodyFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );

  // ============================================================================
  // BODY STYLES (Main content, descriptions, lists)
  // ============================================================================

  /// Large body text - for important descriptions
  /// 18px, Regular, Inter
  static TextStyle bodyLarge = GoogleFonts.getFont(
    _bodyFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.15,
  );

  /// Medium body text - primary body text
  /// 16px, Regular, Inter
  static TextStyle bodyMedium = GoogleFonts.getFont(
    _bodyFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.25,
  );

  /// Small body text - for secondary content
  /// 14px, Regular, Inter
  static TextStyle bodySmall = GoogleFonts.getFont(
    _bodyFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.25,
  );

  // ============================================================================
  // LABEL STYLES (Form labels, badges, chips)
  // ============================================================================

  /// Large label - for prominent labels, input labels
  /// 16px, Medium, Inter
  static TextStyle labelLarge = GoogleFonts.getFont(
    _bodyFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );

  /// Medium label - for standard form labels, badges
  /// 14px, Medium, Inter
  static TextStyle labelMedium = GoogleFonts.getFont(
    _bodyFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
  );

  /// Small label - for chips, tags, micro labels
  /// 12px, Medium, Inter
  static TextStyle labelSmall = GoogleFonts.getFont(
    _bodyFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
  );

  // ============================================================================
  // CAPTION STYLES (Timestamps, helper text, footnotes)
  // ============================================================================

  /// Large caption - for metadata, timestamps
  /// 14px, Regular, Inter
  static TextStyle captionLarge = GoogleFonts.getFont(
    _bodyFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.4,
  );

  /// Medium caption - for helper text, hints
  /// 12px, Regular, Inter
  static TextStyle captionMedium = GoogleFonts.getFont(
    _bodyFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.4,
  );

  /// Small caption - for micro text, legal text
  /// 10px, Regular, Inter
  static TextStyle captionSmall = GoogleFonts.getFont(
    _bodyFontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.4,
  );

  // ============================================================================
  // BUTTON STYLES
  // ============================================================================

  /// Large button text - for primary CTAs
  /// 18px, SemiBold, Inter
  static TextStyle buttonLarge = GoogleFonts.getFont(
    _bodyFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.5,
  );

  /// Medium button text - for standard buttons
  /// 16px, SemiBold, Inter
  static TextStyle buttonMedium = GoogleFonts.getFont(
    _bodyFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.5,
  );

  /// Small button text - for compact buttons
  /// 14px, SemiBold, Inter
  static TextStyle buttonSmall = GoogleFonts.getFont(
    _bodyFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.5,
  );

  // ============================================================================
  // MONOSPACE STYLES (Code, stats, XP, numbers)
  // ============================================================================

  /// Large monospace - for prominent stats, XP displays
  /// 24px, Bold, JetBrains Mono
  static TextStyle monoLarge = GoogleFonts.getFont(
    _monospaceFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.5,
  );

  /// Medium monospace - for stats, counters
  /// 18px, SemiBold, JetBrains Mono
  static TextStyle monoMedium = GoogleFonts.getFont(
    _monospaceFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
  );

  /// Small monospace - for inline code, small numbers
  /// 14px, Medium, JetBrains Mono
  static TextStyle monoSmall = GoogleFonts.getFont(
    _monospaceFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0,
  );

  // ============================================================================
  // GAMIFICATION STYLES (XP, levels, achievements, streaks)
  // ============================================================================

  /// XP display - large, bold, energetic
  /// 48px, Bold, JetBrains Mono
  static TextStyle xpDisplay = GoogleFonts.getFont(
    _monospaceFontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -1.0,
  );

  /// Level display - prominent, game-like
  /// 36px, Bold, Space Grotesk
  static TextStyle levelDisplay = GoogleFonts.getFont(
    _displayFontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  /// Streak counter - fiery, energetic
  /// 28px, Bold, JetBrains Mono
  static TextStyle streakCounter = GoogleFonts.getFont(
    _monospaceFontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0,
  );

  /// Achievement title - celebratory, prominent
  /// 24px, Bold, Space Grotesk
  static TextStyle achievementTitle = GoogleFonts.getFont(
    _displayFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0,
  );

  /// Quest title - action-oriented
  /// 20px, SemiBold, Space Grotesk
  static TextStyle questTitle = GoogleFonts.getFont(
    _displayFontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
  );

  /// Stats label - for contribution stats, activity counts
  /// 16px, Medium, Inter
  static TextStyle statsLabel = GoogleFonts.getFont(
    _bodyFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
  );

  /// Stats value - for numerical stats
  /// 20px, Bold, JetBrains Mono
  static TextStyle statsValue = GoogleFonts.getFont(
    _monospaceFontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0,
  );

  // ============================================================================
  // SPECIAL STYLES (Errors, success, warnings, empty states)
  // ============================================================================

  /// Error message text
  /// 14px, Medium, Inter
  static TextStyle errorText = GoogleFonts.getFont(
    _bodyFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.25,
  );

  /// Success message text
  /// 14px, Medium, Inter
  static TextStyle successText = GoogleFonts.getFont(
    _bodyFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.25,
  );

  /// Warning message text
  /// 14px, Medium, Inter
  static TextStyle warningText = GoogleFonts.getFont(
    _bodyFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.25,
  );

  /// Empty state heading
  /// 24px, SemiBold, Space Grotesk
  static TextStyle emptyStateHeading = GoogleFonts.getFont(
    _displayFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0,
  );

  /// Empty state message
  /// 16px, Regular, Inter
  static TextStyle emptyStateMessage = GoogleFonts.getFont(
    _bodyFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.25,
  );

  // ============================================================================
  // GITHUB INTEGRATION STYLES
  // ============================================================================

  /// Pull request title
  /// 18px, SemiBold, Inter
  static TextStyle prTitle = GoogleFonts.getFont(
    _bodyFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
  );

  /// Issue title
  /// 18px, SemiBold, Inter
  static TextStyle issueTitle = GoogleFonts.getFont(
    _bodyFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
  );

  /// Repository name
  /// 16px, Medium, JetBrains Mono
  static TextStyle repoName = GoogleFonts.getFont(
    _monospaceFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0,
  );

  /// Commit message
  /// 14px, Regular, JetBrains Mono
  static TextStyle commitMessage = GoogleFonts.getFont(
    _monospaceFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
  );

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Apply a color to any text style
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Apply a custom font weight to any text style
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  /// Apply a custom font size to any text style
  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }

  /// Apply opacity to any text style
  static TextStyle withOpacity(TextStyle style, double opacity) {
    return style.copyWith(color: style.color?.withValues(alpha: opacity));
  }

  /// Make text style bold
  static TextStyle bold(TextStyle style) {
    return style.copyWith(fontWeight: FontWeight.w700);
  }

  /// Make text style italic
  static TextStyle italic(TextStyle style) {
    return style.copyWith(fontStyle: FontStyle.italic);
  }

  /// Apply a gradient effect to text (for use with ShaderMask)
  /// Returns the text style - gradient should be applied via ShaderMask widget
  static TextStyle withGradient(TextStyle style) {
    return style.copyWith(
      foreground: Paint()
        ..shader = const LinearGradient(colors: AppColors.gradientPremium)
            .createShader(const Rect.fromLTWH(0, 0, 200, 70)),
    );
  }
}
