import 'package:flutter/material.dart';

/// Brand colours for Brolly.
class BrollyColors {
  BrollyColors._();

  /// Deep British-rainy-day blue — primary brand.
  static const Color brandBlue = Color(0xFF1E5A8E);

  /// Darker brand blue for dark-mode surfaces.
  static const Color brandBlueDark = Color(0xFF0B2E4E);

  /// Warm amber — used for warnings and CTAs.
  static const Color brandAmber = Color(0xFFF5A623);

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
    );

    final TextTheme baseText = brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true).textTheme
        : ThemeData.light(useMaterial3: true).textTheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          baseText.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
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
