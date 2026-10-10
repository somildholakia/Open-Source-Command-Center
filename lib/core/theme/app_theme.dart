import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Centralized theme configuration for the Open Source Developer Command Center.
///
/// Assembles AppColors, AppTypography, and AppSpacing into Material 3 ThemeData.
///
/// Design Direction:
/// - Dark theme is primary (game-like, premium developer aesthetic)
/// - Light theme is a cohesive first-class citizen sharing the same vibrant
///   identity — deep navy ink on soft cool-grey, with deepened accent colors
///   so text/icons remain readable
/// - Creative, playful, energetic visual language
/// - Avoids generic admin dashboard look
/// - Mobile-first with high contrast and accessibility
///
/// Implementation notes:
/// - A single [_componentThemes] builder derives every component theme from
///   the active [ColorScheme], so light and dark can never drift apart.
/// - [AppColors.configureForBrightness] is called before building each theme
///   so theme-resolved color tokens (AppColors.surface, AppColors.border, ...)
///   always match the theme being constructed.
///
/// Usage:
/// ```dart
/// MaterialApp(
///   theme: AppTheme.lightTheme,
///   darkTheme: AppTheme.darkTheme,
///   themeMode: ThemeMode.dark, // Default to dark
/// )
/// ```
class AppTheme {
  AppTheme._(); // Private constructor to prevent instantiation

  // ============================================================================
  // THEME GETTERS
  // ============================================================================

  /// Dark theme - PRIMARY theme for the app
  /// Game-like, premium, developer-focused aesthetic
  static ThemeData get darkTheme => _darkTheme ??= _buildDarkTheme();

  /// Light theme - cohesive with dark theme's vibrant energy
  /// Light background with deepened, readable accents
  static ThemeData get lightTheme => _lightTheme ??= _buildLightTheme();

  // ============================================================================
  // DARK THEME (PRIMARY)
  // ============================================================================

  // Memoized ThemeData. The getter bodies call [configureForBrightness]
  // exactly once per cache fill; afterwards widgets must resolve tokens via
  // the effective theme (see the ThemeSyncWidget note in app.dart), not by
  // re-reading the static flag, which would go stale.
  static ThemeData? _darkTheme;
  static ThemeData? _lightTheme;

  static ThemeData _buildDarkTheme() {
    AppColors.configureForBrightness(Brightness.dark);

    final colorScheme = ColorScheme.dark(
      // Primary colors - vibrant cyan
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      primaryContainer: AppColors.primaryDark,
      onPrimaryContainer: AppColors.primaryLight,

      // Secondary colors - vibrant purple
      secondary: AppColors.secondary,
      onSecondary: AppColors.textOnPrimary,
      secondaryContainer: AppColors.secondaryDark,
      onSecondaryContainer: AppColors.secondaryLight,

      // Tertiary colors - vibrant pink accent
      tertiary: AppColors.accent,
      onTertiary: AppColors.textOnAccent,
      tertiaryContainer: AppColors.accentDark,
      onTertiaryContainer: AppColors.textOnAccent,

      // Error colors
      error: AppColors.error,
      onError: AppColors.textOnPrimary,
      errorContainer: AppColors.errorBackgroundDark,
      onErrorContainer: AppColors.error,

      // Surface colors - dark navy foundation
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textOnDark,
      surfaceContainerHighest: AppColors.surfaceElevatedDark,
      onSurfaceVariant: AppColors.textSecondaryOnDark,

      // Outline/border colors
      outline: AppColors.borderDark,
      outlineVariant: AppColors.borderStrongDark,

      // Other colors
      shadow: Colors.black,
      scrim: AppColors.overlay,
      inverseSurface: AppColors.textOnDark,
      onInverseSurface: AppColors.backgroundDark,
      inversePrimary: AppColors.primaryDark,
      surfaceTint: AppColors.primary,
    );

    return _componentThemes(
      colorScheme,
      scaffoldBackground: AppColors.backgroundDark,
      appBarSurfaceTint: AppColors.primarySubtle,
      softShadow: Colors.black.withValues(alpha: 0.3),
      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  // ============================================================================
  // LIGHT THEME (COHESIVE - Vibrant with light background)
  // ============================================================================

  static ThemeData _buildLightTheme() {
    AppColors.configureForBrightness(Brightness.light);

    final colorScheme = ColorScheme.light(
      // Primary colors - deepened cyan for readability on light surfaces
      primary: AppColors.primaryDeep,
      onPrimary: AppColors.textOnAccent,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.primaryDark,

      // Secondary colors - deepened purple
      secondary: AppColors.secondaryDark,
      onSecondary: AppColors.textOnAccent,
      secondaryContainer: AppColors.secondaryLight,
      onSecondaryContainer: AppColors.textOnLight,

      // Tertiary colors - deepened pink accent
      tertiary: AppColors.accentDark,
      onTertiary: AppColors.textOnAccent,
      tertiaryContainer: AppColors.accentDark,
      onTertiaryContainer: AppColors.textOnAccent,

      // Error colors - deepened for readability
      error: AppColors.errorDark,
      onError: AppColors.textOnAccent,
      errorContainer: AppColors.errorBackgroundLight,
      onErrorContainer: AppColors.errorDark,

      // Surface colors - light foundation
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textOnLight,
      surfaceContainerHighest: AppColors.surfaceElevatedLight,
      onSurfaceVariant: AppColors.textSubtleOnLight,

      // Outline colors
      outline: AppColors.borderStrongLight,
      outlineVariant: AppColors.borderLight,

      // Other colors
      shadow: Colors.black,
      scrim: AppColors.overlay,
      inverseSurface: AppColors.backgroundDark,
      onInverseSurface: AppColors.textOnDark,
      inversePrimary: AppColors.primaryLight,
      surfaceTint: AppColors.primaryDark,
    );

    return _componentThemes(
      colorScheme,
      scaffoldBackground: AppColors.backgroundLight,
      appBarSurfaceTint: AppColors.surfaceLight,
      softShadow: Colors.black.withValues(alpha: 0.12),
      systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  // ============================================================================
  // SHARED COMPONENT THEMES
  // ============================================================================

  /// Builds the full component theme set from [colorScheme].
  ///
  /// Every color is derived from the scheme (or the explicit light/dark
  /// parameters) so both themes stay visually consistent by construction.
  static ThemeData _componentThemes(
    ColorScheme colorScheme, {
    required Color scaffoldBackground,
    required Color appBarSurfaceTint,
    required Color softShadow,
    required SystemUiOverlayStyle systemOverlayStyle,
  }) {
    final isLight = colorScheme.brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      canvasColor: colorScheme.surface,
      dividerColor: colorScheme.outlineVariant,
      splashFactory: InkSparkle.splashFactory,
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(
          color: colorScheme.onSurface,
        ),
        displayMedium: AppTypography.displayMedium.copyWith(
          color: colorScheme.onSurface,
        ),
        displaySmall: AppTypography.displaySmall.copyWith(
          color: colorScheme.onSurface,
        ),
        headlineLarge: AppTypography.headingLarge.copyWith(
          color: colorScheme.onSurface,
        ),
        headlineMedium: AppTypography.headingMedium.copyWith(
          color: colorScheme.onSurface,
        ),
        headlineSmall: AppTypography.headingSmall.copyWith(
          color: colorScheme.onSurface,
        ),
        titleLarge: AppTypography.titleLarge.copyWith(
          color: colorScheme.onSurface,
        ),
        titleMedium: AppTypography.titleMedium.copyWith(
          color: colorScheme.onSurface,
        ),
        titleSmall: AppTypography.titleSmall.copyWith(
          color: colorScheme.onSurface,
        ),
        bodyLarge: AppTypography.bodyLarge.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        bodySmall: AppTypography.bodySmall.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        labelLarge: AppTypography.labelLarge.copyWith(
          color: colorScheme.onSurface,
        ),
        labelMedium: AppTypography.labelMedium.copyWith(
          color: colorScheme.onSurface,
        ),
        labelSmall: AppTypography.labelSmall.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: softShadow,
        surfaceTintColor: appBarSurfaceTint,
        centerTitle: false,
        titleSpacing: AppSpacing.appBarTitleSpacing,
        toolbarHeight: AppSpacing.appBarHeight,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: colorScheme.onSurface,
        ),
        systemOverlayStyle: systemOverlayStyle,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        surfaceTintColor: appBarSurfaceTint,
        elevation: isLight ? 1 : 2,
        shadowColor: softShadow,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusMd),
        margin: EdgeInsets.all(AppSpacing.cardMargin),
        clipBehavior: Clip.antiAlias,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.surfaceContainerHighest,
          disabledForegroundColor: colorScheme.onSurface.withValues(
            alpha: 0.38,
          ),
          elevation: isLight ? 1 : 2,
          shadowColor: softShadow,
          padding: AppSpacing.buttonPadding,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusSm,
          ),
          textStyle: AppTypography.buttonMedium,
        ),
      ),

      // Filled Button Theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.surfaceContainerHighest,
          disabledForegroundColor: colorScheme.onSurface.withValues(
            alpha: 0.38,
          ),
          padding: AppSpacing.buttonPadding,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusSm,
          ),
          textStyle: AppTypography.buttonMedium,
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          disabledForegroundColor: colorScheme.onSurface.withValues(
            alpha: 0.38,
          ),
          side: BorderSide(color: colorScheme.primary, width: 2),
          padding: AppSpacing.buttonPadding,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusSm,
          ),
          textStyle: AppTypography.buttonMedium,
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          disabledForegroundColor: colorScheme.onSurface.withValues(
            alpha: 0.38,
          ),
          padding: AppSpacing.buttonPaddingSmall,
          minimumSize: const Size(48, 40),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusXs,
          ),
          textStyle: AppTypography.buttonMedium,
        ),
      ),

      // Icon Button Theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          disabledForegroundColor: colorScheme.onSurface.withValues(
            alpha: 0.38,
          ),
          highlightColor: colorScheme.primary.withValues(alpha: 0.2),
          hoverColor: colorScheme.primary.withValues(alpha: 0.1),
          minimumSize: const Size(48, 48),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: isLight ? 2 : 4,
        focusElevation: 6,
        hoverElevation: 6,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.formFieldPadding,
          vertical: AppSpacing.formFieldPadding,
        ),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: BorderSide(color: colorScheme.outline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: BorderSide(color: colorScheme.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: BorderSide(color: colorScheme.outline, width: 1),
        ),
        labelStyle: AppTypography.labelLarge.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        floatingLabelStyle: AppTypography.labelMedium.copyWith(
          color: colorScheme.primary,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        errorStyle: AppTypography.errorText.copyWith(color: colorScheme.error),
        helperStyle: AppTypography.captionMedium.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface,
        deleteIconColor: colorScheme.onSurfaceVariant,
        disabledColor: colorScheme.surface.withValues(alpha: 0.5),
        selectedColor: colorScheme.primary.withValues(alpha: 0.2),
        secondarySelectedColor: colorScheme.secondary.withValues(alpha: 0.2),
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        labelStyle: AppTypography.labelMedium.copyWith(
          color: colorScheme.onSurface,
        ),
        secondaryLabelStyle: AppTypography.labelMedium.copyWith(
          color: colorScheme.onSurface,
        ),
        brightness: colorScheme.brightness,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.chipPaddingHorizontal,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusFull,
          side: BorderSide(color: colorScheme.outline, width: 1),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: appBarSurfaceTint,
        elevation: isLight ? 4 : 8,
        shadowColor: softShadow,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
        titleTextStyle: AppTypography.headingMedium.copyWith(
          color: colorScheme.onSurface,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        actionsPadding: EdgeInsets.all(AppSpacing.dialogPadding),
      ),

      // Popup Menu Theme (dropdown menus, theme selector)
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: isLight ? 4 : 8,
        shadowColor: softShadow,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        textStyle: AppTypography.bodyMedium.copyWith(
          color: colorScheme.onSurface,
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppTypography.bodyMedium.copyWith(
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : colorScheme.onSurface,
          ),
        ),
      ),

      // Dropdown Menu Theme
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: AppTypography.bodyMedium.copyWith(
          color: colorScheme.onSurface,
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(colorScheme.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: WidgetStatePropertyAll(isLight ? 4.0 : 8.0),
          shadowColor: WidgetStatePropertyAll(softShadow),
          side: WidgetStatePropertyAll(
            BorderSide(color: colorScheme.outlineVariant, width: 1),
          ),
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: appBarSurfaceTint,
        elevation: isLight ? 4 : 8,
        modalElevation: isLight ? 4 : 8,
        shadowColor: softShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        selectedIconTheme: IconThemeData(
          color: colorScheme.primary,
          size: AppSpacing.iconSizeMedium,
        ),
        unselectedIconTheme: IconThemeData(
          color: colorScheme.onSurfaceVariant,
          size: AppSpacing.iconSizeMedium,
        ),
        selectedLabelStyle: AppTypography.labelSmall.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.labelSmall.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        type: BottomNavigationBarType.fixed,
        enableFeedback: true,
      ),

      // Navigation Bar Theme (Material 3 bottom nav)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        height: AppSpacing.bottomNavHeight,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.2),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusSm,
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelSmall.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTypography.labelSmall.copyWith(
            color: colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: colorScheme.primary,
              size: AppSpacing.iconSizeMedium,
            );
          }
          return IconThemeData(
            color: colorScheme.onSurfaceVariant,
            size: AppSpacing.iconSizeMedium,
          );
        }),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: AppSpacing.dividerThickness,
        space: AppSpacing.md,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),

      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withValues(alpha: 0.2),
        valueIndicatorColor: colorScheme.primary,
        valueIndicatorTextStyle: AppTypography.labelSmall.copyWith(
          color: colorScheme.onPrimary,
        ),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return colorScheme.outlineVariant;
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(colorScheme.onPrimary),
        side: BorderSide(color: colorScheme.outline, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        ),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        actionTextColor: colorScheme.inversePrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusSm),
      ),

      // Tooltip Theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: AppSpacing.borderRadiusXs,
        ),
        textStyle: AppTypography.captionMedium.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: colorScheme.primary.withValues(alpha: 0.1),
        iconColor: colorScheme.onSurfaceVariant,
        selectedColor: colorScheme.primary,
        textColor: colorScheme.onSurface,
        titleTextStyle: AppTypography.titleSmall.copyWith(
          color: colorScheme.onSurface,
        ),
        subtitleTextStyle: AppTypography.bodySmall.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        leadingAndTrailingTextStyle: AppTypography.labelMedium.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        contentPadding: AppSpacing.listItemPaddingInsets,
        minLeadingWidth: 40,
        horizontalTitleGap: AppSpacing.sm,
        minVerticalPadding: AppSpacing.xs,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusSm),
      ),

      // Badge Theme
      badgeTheme: BadgeThemeData(
        backgroundColor: colorScheme.error,
        textColor: colorScheme.onError,
        textStyle: AppTypography.captionSmall.copyWith(
          fontWeight: FontWeight.w700,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xxs,
          vertical: AppSpacing.xxs,
        ),
        alignment: AlignmentDirectional.topEnd,
        offset: Offset(AppSpacing.badgeOffset, -AppSpacing.badgeOffset),
      ),

      // Bottom App Bar Theme
      bottomAppBarTheme: BottomAppBarThemeData(
        color: colorScheme.surface,
        elevation: 0,
        surfaceTintColor: appBarSurfaceTint,
        shadowColor: softShadow,
        height: AppSpacing.bottomNavHeight,
      ),

      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: AppTypography.labelLarge.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.labelLarge.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: colorScheme.outlineVariant,
      ),

      // Icon Theme
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: AppSpacing.iconSizeMedium,
      ),

      // Primary Icon Theme
      primaryIconTheme: IconThemeData(
        color: colorScheme.primary,
        size: AppSpacing.iconSizeMedium,
      ),
    );
  }
}
