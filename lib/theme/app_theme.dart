import 'package:flutter/material.dart';

/// App theme converted from the Tailwind v4 / shadcn-style design tokens.
///
/// Source tokens were OKLCH; values below are rounded to the nearest sRGB.
/// Token -> Material 3 mapping:
///   background -> surface            foreground -> onSurface
///   muted      -> surfaceContainerLow        secondary -> surfaceContainer
///   border     -> outline/outlineVariant/surfaceContainerHighest
///   accent     -> primaryContainer       accentForeground -> onPrimaryContainer
///   destructive-> error                  mutedForeground  -> onSurfaceVariant
///
/// Fonts: `Inter`, `Source Serif 4`, `JetBrains Mono` require the
/// `google_fonts` package (or bundled assets). Font wiring is deferred to the
/// screens task to keep this file dependency-free.
abstract final class AppFonts {
  static const String sans = 'Inter';
  static const String serif = 'Source Serif 4';
  static const String mono = 'JetBrains Mono';
}

/// Base radius token is 0.375rem (6px); sm/md/xl derive from it.
abstract final class AppRadius {
  static const double sm = 2;
  static const double md = 4;
  static const double lg = 6;
  static const double xl = 10;
}

/// Shadow tokens converted from the CSS custom properties.
abstract final class AppShadows {
  static const List<BoxShadow> xs = [
    BoxShadow(offset: Offset(0, 1), blurRadius: 3, color: Color(0x0D000000)),
  ];

  static const List<BoxShadow> sm = [
    BoxShadow(offset: Offset(0, 1), blurRadius: 3, color: Color(0x1A000000)),
    BoxShadow(offset: Offset(0, 1), blurRadius: 2, spreadRadius: -1, color: Color(0x1A000000)),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(offset: Offset(0, 1), blurRadius: 3, color: Color(0x1A000000)),
    BoxShadow(offset: Offset(0, 2), blurRadius: 4, spreadRadius: -1, color: Color(0x1A000000)),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(offset: Offset(0, 1), blurRadius: 3, color: Color(0x1A000000)),
    BoxShadow(offset: Offset(0, 4), blurRadius: 6, spreadRadius: -1, color: Color(0x1A000000)),
  ];

  static const List<BoxShadow> xl = [
    BoxShadow(offset: Offset(0, 1), blurRadius: 3, color: Color(0x1A000000)),
    BoxShadow(offset: Offset(0, 8), blurRadius: 10, spreadRadius: -1, color: Color(0x1A000000)),
  ];

  static const List<BoxShadow> xxl = [
    BoxShadow(offset: Offset(0, 1), blurRadius: 3, color: Color(0x40000000)),
  ];
}

/// Raw palette converted from the OKLCH source tokens.
abstract final class AppColors {
  // Light mode.
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightForeground = Color(0xFF333333);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightSecondary = Color(0xFFF3F4F5);
  static const Color lightSecondaryForeground = Color(0xFF475569);
  static const Color lightMuted = Color(0xFFFAFAFB);
  static const Color lightMutedForeground = Color(0xFF6B7280);
  static const Color lightAccent = Color(0xFFDFF2FD);
  static const Color lightAccentForeground = Color(0xFF1E3A8A);
  static const Color lightDestructive = Color(0xFFEF4444);
  static const Color lightBorder = Color(0xFFE5E7EB);

  // Dark mode.
  static const Color darkBackground = Color(0xFF171717);
  static const Color darkForeground = Color(0xFFE5E5E5);
  static const Color darkCard = Color(0xFF262626);
  static const Color darkSecondary = Color(0xFF262626);
  static const Color darkMuted = Color(0xFF1F1F1F);
  static const Color darkMutedForeground = Color(0xFFA3A3A3);
  static const Color darkAccent = Color(0xFF1E3A8A);
  static const Color darkAccentForeground = Color(0xFFBFDCFD);
  static const Color darkBorder = Color(0xFF404040);

  // Shared accents.
  static const Color primary = Color(0xFF3B82F6);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color destructive = Color(0xFFEF4444);

  // Chart ramp (light) and its brightened dark variant.
  static const Color chart1 = Color(0xFF3B82F6);
  static const Color chart2 = Color(0xFF2563EB);
  static const Color chart1Dark = Color(0xFF60A5FA);
}

/// Builds the Material 3 color scheme for a given brightness from the tokens.
ColorScheme _scheme(Brightness brightness) {
  final bool isLight = brightness == Brightness.light;
  final Color surface = isLight ? AppColors.lightBackground : AppColors.darkBackground;
  final Color onSurface = isLight ? AppColors.lightForeground : AppColors.darkForeground;
  final Color border = isLight ? AppColors.lightBorder : AppColors.darkBorder;

  return ColorScheme(
    brightness: brightness,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: isLight ? AppColors.lightAccent : AppColors.darkAccent,
    onPrimaryContainer: isLight ? AppColors.lightAccentForeground : AppColors.darkAccentForeground,
    secondary: isLight ? AppColors.lightSecondary : AppColors.darkSecondary,
    onSecondary: isLight ? AppColors.lightSecondaryForeground : AppColors.darkForeground,
    surface: surface,
    onSurface: onSurface,
    surfaceContainerLowest: surface,
    surfaceContainerLow: isLight ? AppColors.lightMuted : AppColors.darkMuted,
    surfaceContainer: isLight ? AppColors.lightSecondary : AppColors.darkSecondary,
    surfaceContainerHigh: isLight ? AppColors.lightSecondary : AppColors.darkCard,
    surfaceContainerHighest: border,
    onSurfaceVariant: isLight ? AppColors.lightMutedForeground : AppColors.darkMutedForeground,
    outline: border,
    outlineVariant: border,
    error: AppColors.destructive,
    onError: AppColors.onPrimary,
    inverseSurface: isLight ? AppColors.darkCard : AppColors.lightBackground,
    onInverseSurface: isLight ? AppColors.darkForeground : AppColors.lightForeground,
    inversePrimary: isLight ? AppColors.chart1Dark : AppColors.chart1,
  );
}

/// Light theme built from the converted design tokens.
final ThemeData appThemeLight = _build(Brightness.light);

/// Dark theme built from the converted design tokens.
final ThemeData appThemeDark = _build(Brightness.dark);

ThemeData _build(Brightness brightness) {
  final ColorScheme scheme = _scheme(brightness);
  final bool isLight = brightness == Brightness.light;

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: AppShadows.xs.first.blurRadius.toDouble(),
    ),
    cardTheme: CardThemeData(
      color: isLight ? AppColors.lightCard : AppColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: scheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: scheme.outline),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    ),
  );
}
