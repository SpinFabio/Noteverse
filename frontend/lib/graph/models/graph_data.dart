import '../../hex_coordinate.dart';
import 'graph_edge.dart';
import 'graph_node.dart';

/// An immutable, positioned note graph with indexes for frequent lookups.
class GraphData {
  GraphData._({
    required this.graphId,
    required List<GraphNode> nodes,
    required List<GraphEdge> edges,
  }) : nodes = List.unmodifiable(nodes),
       edges = List.unmodifiable(edges),
       nodesById = Map.unmodifiable({for (final node in nodes) node.id: node}),
       nodeIdByCell = Map.unmodifiable({
         for (final node in nodes) node.cell: node.id,
       }),
       outgoingEdgesByNodeId = _indexEdges(nodes, edges, outgoing: true),
       incomingEdgesByNodeId = _indexEdges(nodes, edges, outgoing: false),
       neighborCountsByNodeId = _countNeighbors(nodes, edges);

  /// Creates and validates a positioned graph.
  factory GraphData({
    required String graphId,
    required List<GraphNode> nodes,
    required List<GraphEdge> edges,
  }) {
    if (graphId.isEmpty) {
      throw const FormatException('graphId must be a non-empty string.');
    }

    _validate(nodes, edges);
    return GraphData._(graphId: graphId, nodes: nodes, edges: edges);
  }

  /// Creates and validates a graph from the backend JSON representation.
  factory GraphData.fromJson(Map<String, Object?> json) {
    final graphId = json['graphId'];
    final nodeValues = json['nodes'];
    final edgeValues = json['edges'];

    if (graphId is! String || graphId.isEmpty) {
      throw const FormatException('graphId must be a non-empty string.');
    }
    if (nodeValues is! List<Object?>) {
      throw const FormatException('nodes must be a JSON array.');
    }
    if (edgeValues is! List<Object?>) {
      throw const FormatException('edges must be a JSON array.');
    }

    return GraphData(
      graphId: graphId,
      nodes: nodeValues
          .map((value) => GraphNode.fromJson(_jsonObject(value, 'node')))
          .toList(growable: false),
      edges: edgeValues
          .map((value) => GraphEdge.fromJson(_jsonObject(value, 'edge')))
          .toList(growable: false),
    );
  }

  /// Stable identifier of this graph.
  final String graphId;

  /// Nodes in transport order.
  final List<GraphNode> nodes;

  /// Directed edges in transport order.
  final List<GraphEdge> edges;

  /// Nodes keyed by their stable identifier.
  final Map<String, GraphNode> nodesById;

  /// Node identifiers keyed by occupied hexagonal cell.
  final Map<HexCoordinate, String> nodeIdByCell;

  /// Directed edges keyed by their source node identifier.
  final Map<String, List<GraphEdge>> outgoingEdgesByNodeId;

  /// Directed edges keyed by their target node identifier.
  final Map<String, List<GraphEdge>> incomingEdgesByNodeId;

  /// Distinct neighbors across incoming and outgoing edges.
  ///
  /// Reciprocal directed links to the same note count as one neighbor.
  final Map<String, int> neighborCountsByNodeId;

  /// Converts this graph to its backend JSON representation.
  Map<String, Object> toJson() => {
    'graphId': graphId,
    'nodes': nodes.map((node) => node.toJson()).toList(growable: false),
    'edges': edges.map((edge) => edge.toJson()).toList(growable: false),
  };
}

Map<String, int> _countNeighbors(List<GraphNode> nodes, List<GraphEdge> edges) {
  final neighbors = {for (final node in nodes) node.id: <String>{}};
  for (final edge in edges) {
    neighbors[edge.sourceNodeId]!.add(edge.targetNodeId);
    neighbors[edge.targetNodeId]!.add(edge.sourceNodeId);
  }
  return Map.unmodifiable({
    for (final entry in neighbors.entries) entry.key: entry.value.length,
  });
}

void _validate(List<GraphNode> nodes, List<GraphEdge> edges) {
  final nodeIds = <String>{};
  final occupiedCells = <HexCoordinate>{};
  for (final node in nodes) {
    if (!nodeIds.add(node.id)) {
      throw FormatException('Duplicate node id: ${node.id}.');
    }
    if (!occupiedCells.add(node.cell)) {
      throw FormatException(
        'Multiple nodes occupy cell (${node.cell.q}, ${node.cell.r}).',
      );
    }
  }

  final edgeIds = <String>{};
  final directedConnections = <(String, String)>{};
  for (final edge in edges) {
    if (!edgeIds.add(edge.id)) {
      throw FormatException('Duplicate edge id: ${edge.id}.');
    }
    if (!nodeIds.contains(edge.sourceNodeId)) {
      throw FormatException(
        'Edge ${edge.id} has unknown source ${edge.sourceNodeId}.',
      );
    }
    if (!nodeIds.contains(edge.targetNodeId)) {
      throw FormatException(
        'Edge ${edge.id} has unknown target ${edge.targetNodeId}.',
      );
    }
    if (edge.sourceNodeId == edge.targetNodeId) {
      throw FormatException('Edge ${edge.id} cannot connect a node to itself.');
    }
    if (!directedConnections.add((edge.sourceNodeId, edge.targetNodeId))) {
      throw FormatException(
        'Duplicate directed connection: '
        '${edge.sourceNodeId} -> ${edge.targetNodeId}.',
      );
    }
  }
}

Map<String, List<GraphEdge>> _indexEdges(
  List<GraphNode> nodes,
  List<GraphEdge> edges, {
  required bool outgoing,
}) {
  final index = {for (final node in nodes) node.id: <GraphEdge>[]};
  for (final edge in edges) {
    final nodeId = outgoing ? edge.sourceNodeId : edge.targetNodeId;
    index[nodeId]!.add(edge);
  }
  return Map.unmodifiable({
    for (final entry in index.entries)
      entry.key: List<GraphEdge>.unmodifiable(entry.value),
  });
}

Map<String, Object?> _jsonObject(Object? value, String name) {
  if (value is! Map<String, Object?>) {
    throw FormatException('Each $name must be a JSON object.');
  }
  return value;
}
