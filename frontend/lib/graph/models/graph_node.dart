import '../../hex_coordinate.dart';

/// A Markdown note placed on one cell of the hexagonal graph.
class GraphNode {
  const GraphNode({
    required this.id,
    required this.title,
    required this.sourcePath,
    required this.cell,
  });

  /// Stable note identifier, independent from its mutable file path.
  final String id;

  /// Human-readable note title.
  final String title;

  /// Path of the Markdown file represented by this node.
  final String sourcePath;

  /// Integer axial coordinate occupied by this node.
  final HexCoordinate cell;

  /// Creates a node from the backend JSON representation.
  factory GraphNode.fromJson(Map<String, Object?> json) {
    return GraphNode(
      id: _requiredString(json, 'id'),
      title: _requiredString(json, 'title'),
      sourcePath: _requiredString(json, 'sourcePath'),
      cell: HexCoordinate.fromJson(_requiredMap(json, 'cell')),
    );
  }

  /// Converts this node to its backend JSON representation.
  Map<String, Object> toJson() => {
    'id': id,
    'title': title,
    'sourcePath': sourcePath,
    'cell': cell.toJson(),
  };
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }
  return value;
}

Map<String, Object?> _requiredMap(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! Map<String, Object?>) {
    throw FormatException('$key must be a JSON object.');
  }
  return value;
}
