import 'package:flutter/material.dart';

/// Canonical raw colors used to build the Noteverse design system.
abstract final class NoteversePalette {
  static const primarySeed = Color(0xFF3F51B5);
  static const foreground = Color(0xFFE0E0E0);
  static const neutral900 = Color(0xFF171717);
  static const graphBackground = Color(0xFF303030);
  static const graphGridLines = Color(0x66808080);
  static const graphOrigin = Color(0xFFF44336);
  static const graphNodeSurface = Color(0xFF303F9F);
  static const graphNodeOutline = Color(0xFFE0E0E0);
  static const graphNodeLabel = Color(0xFFE0E0E0);
  static const simulationRunning = Color(0xFF81C784);
  static const graphEdge = Color(0xFF858585);
}

/// Noteverse-specific colors that do not map to Material color roles.
@immutable
class NoteverseColors extends ThemeExtension<NoteverseColors> {
  const NoteverseColors({
    required this.graphBackground,
    required this.graphGridLines,
    required this.graphOrigin,
    required this.graphNodeSurface,
    required this.graphNodeOutline,
    required this.graphNodeLabel,
    required this.graphEdge,
    required this.floatingControlSurface,
    required this.simulationRunning,
  });

  /// Dark-mode-first application color extension.
  static const dark = NoteverseColors(
    graphBackground: NoteversePalette.graphBackground,
    graphGridLines: NoteversePalette.graphGridLines,
    graphOrigin: NoteversePalette.graphOrigin,
    graphNodeSurface: NoteversePalette.graphNodeSurface,
    graphNodeOutline: NoteversePalette.graphNodeOutline,
    graphNodeLabel: NoteversePalette.graphNodeLabel,
    graphEdge: NoteversePalette.graphEdge,
    floatingControlSurface: NoteversePalette.neutral900,
    simulationRunning: NoteversePalette.simulationRunning,
  );

  final Color graphBackground;
  final Color graphGridLines;
  final Color graphOrigin;
  final Color graphNodeSurface;
  final Color graphNodeOutline;
  final Color graphNodeLabel;
  final Color graphEdge;
  final Color floatingControlSurface;

  /// Foreground for the active graph simulation indicator.
  final Color simulationRunning;

  /// Resolves Noteverse-specific colors from the nearest application theme.
  static NoteverseColors of(BuildContext context) {
    final colors = Theme.of(context).extension<NoteverseColors>();
    assert(colors != null, 'NoteverseColors must be registered in ThemeData.');
    return colors!;
  }

  @override
  NoteverseColors copyWith({
    Color? graphBackground,
    Color? graphGridLines,
    Color? graphOrigin,
    Color? graphNodeSurface,
    Color? graphNodeOutline,
    Color? graphNodeLabel,
    Color? graphEdge,
    Color? floatingControlSurface,
    Color? simulationRunning,
  }) => NoteverseColors(
    simulationRunning: simulationRunning ?? this.simulationRunning,
    graphBackground: graphBackground ?? this.graphBackground,
    graphGridLines: graphGridLines ?? this.graphGridLines,
    graphOrigin: graphOrigin ?? this.graphOrigin,
    graphNodeSurface: graphNodeSurface ?? this.graphNodeSurface,
    graphNodeOutline: graphNodeOutline ?? this.graphNodeOutline,
    graphNodeLabel: graphNodeLabel ?? this.graphNodeLabel,
    graphEdge: graphEdge ?? this.graphEdge,
    floatingControlSurface:
        floatingControlSurface ?? this.floatingControlSurface,
  );

  @override
  NoteverseColors lerp(covariant NoteverseColors? other, double t) {
    if (other == null) {
      return this;
    }
    return NoteverseColors(
      simulationRunning: Color.lerp(
        simulationRunning,
        other.simulationRunning,
        t,
      )!,
      graphBackground: Color.lerp(graphBackground, other.graphBackground, t)!,
      graphGridLines: Color.lerp(graphGridLines, other.graphGridLines, t)!,
      graphOrigin: Color.lerp(graphOrigin, other.graphOrigin, t)!,
      graphNodeSurface: Color.lerp(
        graphNodeSurface,
        other.graphNodeSurface,
        t,
      )!,
      graphNodeOutline: Color.lerp(
        graphNodeOutline,
        other.graphNodeOutline,
        t,
      )!,
      graphNodeLabel: Color.lerp(graphNodeLabel, other.graphNodeLabel, t)!,
      graphEdge: Color.lerp(graphEdge, other.graphEdge, t)!,
      floatingControlSurface: Color.lerp(
        floatingControlSurface,
        other.floatingControlSurface,
        t,
      )!,
    );
  }
}
