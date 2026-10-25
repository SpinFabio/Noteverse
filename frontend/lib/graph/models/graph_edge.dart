/// A directed Markdown link between two graph nodes.
class GraphEdge {
  const GraphEdge({
    required this.id,
    required this.sourceNodeId,
    required this.targetNodeId,
    this.relationship,
  });

  /// Stable identifier for this directed edge.
  final String id;

  /// Identifier of the note containing the Markdown link.
  final String sourceNodeId;

  /// Identifier of the note targeted by the Markdown link.
  final String targetNodeId;

  /// Optional semantic meaning assigned to the connection.
  final String? relationship;

  /// Creates an edge from the backend JSON representation.
  factory GraphEdge.fromJson(Map<String, Object?> json) {
    final relationship = json['relationship'];
    if (relationship != null &&
        (relationship is! String || relationship.isEmpty)) {
      throw const FormatException(
        'relationship must be a non-empty string when provided.',
      );
    }

    return GraphEdge(
      id: _requiredString(json, 'id'),
      sourceNodeId: _requiredString(json, 'sourceNodeId'),
      targetNodeId: _requiredString(json, 'targetNodeId'),
      relationship: relationship as String?,
    );
  }

  /// Converts this edge to its backend JSON representation.
  Map<String, Object?> toJson() => {
    'id': id,
    'sourceNodeId': sourceNodeId,
    'targetNodeId': targetNodeId,
    if (relationship != null) 'relationship': relationship,
  };
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }
  return value;
}
