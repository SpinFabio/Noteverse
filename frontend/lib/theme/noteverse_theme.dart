import 'package:flutter/material.dart';

import 'noteverse_colors.dart';
import 'noteverse_typography.dart';

/// Application themes assembled from the canonical Noteverse color tokens.
abstract final class NoteverseTheme {
  static final ColorScheme _darkColorScheme = ColorScheme.fromSeed(
    seedColor: NoteversePalette.primarySeed,
    brightness: Brightness.dark,
  ).copyWith(onSurface: NoteversePalette.foreground);

  /// Dark-mode-first theme used by every currently supported target.
  static final ThemeData dark =
      ThemeData(
        colorScheme: _darkColorScheme,
        useMaterial3: true,
        fontFamily: NoteverseTypography.fontFamily,
      ).copyWith(
        textTheme: NoteverseTypography.apply(
          ThemeData.dark().textTheme.apply(
            bodyColor: NoteversePalette.foreground,
            displayColor: NoteversePalette.foreground,
          ),
        ),
        iconTheme: const IconThemeData(color: NoteversePalette.foreground),
        iconButtonTheme: const IconButtonThemeData(
          style: ButtonStyle(shape: WidgetStatePropertyAll(CircleBorder())),
        ),
        filledButtonTheme: const FilledButtonThemeData(
          style: ButtonStyle(shape: WidgetStatePropertyAll(StadiumBorder())),
        ),
        outlinedButtonTheme: const OutlinedButtonThemeData(
          style: ButtonStyle(shape: WidgetStatePropertyAll(StadiumBorder())),
        ),
        textButtonTheme: const TextButtonThemeData(
          style: ButtonStyle(shape: WidgetStatePropertyAll(StadiumBorder())),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: NoteverseColors.dark.floatingControlSurface,
          foregroundColor: _darkColorScheme.onSurface,
          elevation: 6,
          shape: const CircleBorder(),
        ),
        extensions: const <ThemeExtension<dynamic>>[NoteverseColors.dark],
      );
}
