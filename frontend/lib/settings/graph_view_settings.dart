import 'package:flutter/material.dart';

/// User-configurable presentation settings for the graph viewport.
class GraphViewSettings {
  const GraphViewSettings({required this.backgroundColor});

  /// Default settings used when no valid persisted value is available.
  static const defaults = GraphViewSettings(backgroundColor: Color(0xFFC8C8C8));

  static const _schemaVersion = 1;

  /// Solid background color painted behind the graph grid.
  final Color backgroundColor;

  /// Creates settings from their versioned persistence representation.
  factory GraphViewSettings.fromJson(Map<String, dynamic> json) {
    if (json['version'] != _schemaVersion) {
      throw const FormatException('Unsupported graph view settings version.');
    }

    final backgroundColor = json['backgroundColor'];
    if (backgroundColor is! int ||
        backgroundColor < 0 ||
        backgroundColor > 0xFFFFFFFF) {
      throw const FormatException('Invalid graph background color.');
    }

    return GraphViewSettings(backgroundColor: Color(backgroundColor));
  }

  /// Converts these settings to a versioned persistence representation.
  Map<String, Object> toJson() => <String, Object>{
    'version': _schemaVersion,
    'backgroundColor': backgroundColor.toARGB32(),
  };

  /// Returns a copy with selected values replaced.
  GraphViewSettings copyWith({Color? backgroundColor}) => GraphViewSettings(
    backgroundColor: backgroundColor ?? this.backgroundColor,
  );
}
