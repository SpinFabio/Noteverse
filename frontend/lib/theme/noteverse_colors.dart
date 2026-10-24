import 'package:flutter/material.dart';

/// Canonical raw colors used to build the Noteverse design system.
abstract final class NoteversePalette {
  static const primarySeed = Color(0xFF3F51B5);
  static const foreground = Color(0xFFE0E0E0);
  static const neutral900 = Color(0xFF171717);
  static const graphBackground = Color(0xFF303030);
  static const graphGridDots = Color(0xFFB8B8B8);
  static const graphOrigin = Color(0xFFF44336);
}

/// Noteverse-specific colors that do not map to Material color roles.
@immutable
class NoteverseColors extends ThemeExtension<NoteverseColors> {
  const NoteverseColors({
    required this.graphBackground,
    required this.graphGridDots,
    required this.graphOrigin,
    required this.floatingControlSurface,
  });

  /// Dark-mode-first application color extension.
  static const dark = NoteverseColors(
    graphBackground: NoteversePalette.graphBackground,
    graphGridDots: NoteversePalette.graphGridDots,
    graphOrigin: NoteversePalette.graphOrigin,
    floatingControlSurface: NoteversePalette.neutral900,
  );

  final Color graphBackground;
  final Color graphGridDots;
  final Color graphOrigin;
  final Color floatingControlSurface;

  /// Resolves Noteverse-specific colors from the nearest application theme.
  static NoteverseColors of(BuildContext context) {
    final colors = Theme.of(context).extension<NoteverseColors>();
    assert(colors != null, 'NoteverseColors must be registered in ThemeData.');
    return colors!;
  }

  @override
  NoteverseColors copyWith({
    Color? graphBackground,
    Color? graphGridDots,
    Color? graphOrigin,
    Color? floatingControlSurface,
  }) => NoteverseColors(
    graphBackground: graphBackground ?? this.graphBackground,
    graphGridDots: graphGridDots ?? this.graphGridDots,
    graphOrigin: graphOrigin ?? this.graphOrigin,
    floatingControlSurface:
        floatingControlSurface ?? this.floatingControlSurface,
  );

  @override
  NoteverseColors lerp(covariant NoteverseColors? other, double t) {
    if (other == null) {
      return this;
    }
    return NoteverseColors(
      graphBackground: Color.lerp(graphBackground, other.graphBackground, t)!,
      graphGridDots: Color.lerp(graphGridDots, other.graphGridDots, t)!,
      graphOrigin: Color.lerp(graphOrigin, other.graphOrigin, t)!,
      floatingControlSurface: Color.lerp(
        floatingControlSurface,
        other.floatingControlSurface,
        t,
      )!,
    );
  }
}
