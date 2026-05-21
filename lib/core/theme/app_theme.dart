import 'package:flutter/material.dart';

/// Brand colours for Brolly.
class BrollyColors {
  BrollyColors._();

  /// Vivid sky blue — primary brand. Lifted from the deep navy original
  /// to read brighter and more energetic in the light theme.
  static const Color brandBlue = Color(0xFF1976D2);

  /// Darker brand blue for dark-mode surfaces.
  static const Color brandBlueDark = Color(0xFF0B2E4E);

  /// Warm amber — used for warnings and CTAs.
  static const Color brandAmber = Color(0xFFF5A623);

  /// Soft sunshine accent for highlights, day-time chips, and selected day.
  static const Color brandYellow = Color(0xFFFFC857);

  /// Subtle background tint behind the scaffold in light mode — keeps the
  /// surface from feeling stark white.
  static const Color lightSurface = Color(0xFFF1F5FA);

  /// Severe weather warning levels.
  static const Color warningYellow = Color(0xFFFFC107);
  static const Color warningAmber = Color(0xFFFF8F00);
  static const Color warningRed = Color(0xFFD32F2F);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: BrollyColors.brandBlue,
      brightness: brightness,
      secondary: BrollyColors.brandYellow,
    );

    final TextTheme baseText = brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true).textTheme
        : ThemeData.light(useMaterial3: true).textTheme;

    final Color scaffold = brightness == Brightness.light
        ? BrollyColors.lightSurface
        : scheme.surface;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: scaffold,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: scheme.onPrimary),
        titleTextStyle: baseText.titleLarge?.copyWith(
          color: scheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>(
          (Set<WidgetState> states) {
            final bool selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
            );
          },
        ),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
          (Set<WidgetState> states) {
            final bool selected = states.contains(WidgetState.selected);
            return baseText.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            );
          },
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: brightness == Brightness.light
            ? scheme.outlineVariant.withValues(alpha: 0.6)
            : scheme.outlineVariant,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      textTheme: baseText.copyWith(
        displayLarge: baseText.displayLarge?.copyWith(
          fontWeight: FontWeight.w300,
          letterSpacing: -2,
        ),
        displayMedium: baseText.displayMedium?.copyWith(
          fontWeight: FontWeight.w300,
          letterSpacing: -1,
        ),
        headlineLarge: baseText.headlineLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        titleLarge: baseText.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
