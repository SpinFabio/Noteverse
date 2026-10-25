import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/graph_data.dart';

/// Loads positioned graph data bundled with the Flutter application.
abstract final class GraphAssetLoader {
  /// Decodes and validates a graph stored at [assetPath].
  static Future<GraphData> load(String assetPath) async {
    final source = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException(
        'The graph asset must contain a JSON object.',
      );
    }
    return GraphData.fromJson(decoded);
  }
}
