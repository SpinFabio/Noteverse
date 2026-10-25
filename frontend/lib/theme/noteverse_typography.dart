import 'package:flutter/material.dart';

/// Shared font family and heading conventions for widgets and canvas text.
abstract final class NoteverseTypography {
  static const fontFamily = 'Atkinson Hyperlegible Next';

  /// Applies the bundled font and bold weights to all heading roles.
  static TextTheme apply(TextTheme source) {
    final text = source.apply(fontFamily: fontFamily);
    return text.copyWith(
      displayLarge: text.displayLarge?.copyWith(fontWeight: FontWeight.w700),
      displayMedium: text.displayMedium?.copyWith(fontWeight: FontWeight.w700),
      displaySmall: text.displaySmall?.copyWith(fontWeight: FontWeight.w700),
      headlineLarge: text.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium: text.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}
