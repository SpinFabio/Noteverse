import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../hex_coordinate.dart';
import '../../hex_grid_geometry.dart';
import '../../theme/noteverse_graph_style.dart';
import '../models/graph_data.dart';
import '../models/graph_node.dart';
import 'hex_layout_snapper.dart';

/// Explicit editing modes available in the graph arrangement modal.
enum GraphLayoutMode { forces, hexGrid }

/// User-adjustable values controlling one force-directed simulation run.
class ForceGraphLayoutParameters {
  const ForceGraphLayoutParameters({
    this.repulsion = 1,
    this.attraction = 1,
    this.linkDistance = 92,
    this.centering = 1,
    this.damping = 0.16,
    this.speed = 1,
  });

  final double repulsion;
  final double attraction;
  final double linkDistance;
  final double centering;
  final double damping;
  final double speed;

  ForceGraphLayoutParameters copyWith({
    double? repulsion,
    double? attraction,
    double? linkDistance,
    double? centering,
    double? damping,
    double? speed,
  }) => ForceGraphLayoutParameters(
    repulsion: repulsion ?? this.repulsion,
    attraction: attraction ?? this.attraction,
    linkDistance: linkDistance ?? this.linkDistance,
    centering: centering ?? this.centering,
    damping: damping ?? this.damping,
    speed: speed ?? this.speed,
  );
}

/// Mutable, disposable state used only inside the graph-arrangement modal.
class ForceGraphLayout extends ChangeNotifier {
  ForceGraphLayout({
    required this.graph,
    required this.geometry,
    this.parameters = const ForceGraphLayoutParameters(),
  }) : _positions = {
         for (var index = 0; index < graph.nodes.length; index++)
           graph.nodes[index].id: _initialPosition(index),
       },
       _velocities = {for (final node in graph.nodes) node.id: Offset.zero},
       _nodeIndexes = {
         for (var index = 0; index < graph.nodes.length; index++)
           graph.nodes[index].id: index,
       };

  static const _spawnIntervalSeconds = 0.025;
  static const _baseRepulsionStrength = 420.0;
  static const _baseSpringStrength = 0.004;
  static const _baseCenteringStrength = 0.0005;
  static const _maximumSpeed = 12.0;

  final GraphData graph;
  final HexGridGeometry geometry;
  ForceGraphLayoutParameters parameters;
  final Map<String, Offset> _positions;
  final Map<String, Offset> _velocities;
  final Map<String, int> _nodeIndexes;

  Map<String, HexCoordinate> _snappedCells = const {};
  GraphLayoutMode _mode = GraphLayoutMode.forces;
  bool _isRunning = true;
  int _visibleNodeCount = 0;
  double _spawnAccumulator = 0;
  String? _draggedNodeId;

  GraphLayoutMode get mode => _mode;
  bool get isRunning => _isRunning;
  bool get isSpawning => _visibleNodeCount < graph.nodes.length;
  int get visibleNodeCount => _visibleNodeCount;
  bool get canSnap =>
      _mode == GraphLayoutMode.forces && !isSpawning && _draggedNodeId == null;
  bool get canApply => _mode == GraphLayoutMode.hexGrid;
  Iterable<GraphNode> get visibleNodes => graph.nodes.take(_visibleNodeCount);

  /// Returns the current modal-space position for [nodeId].
  Offset positionOf(String nodeId) => _positions[nodeId]!;

  /// Whether both endpoints of an edge have already appeared.
  bool isVisible(String nodeId) => _nodeIndexes[nodeId]! < _visibleNodeCount;

  /// Advances spawning and force integration by one rendered frame.
  void advance(double elapsedSeconds) {
    if (!_isRunning || _mode != GraphLayoutMode.forces || graph.nodes.isEmpty) {
      return;
    }

    final safeElapsed = elapsedSeconds.clamp(0, 1 / 20).toDouble();
    if (isSpawning) {
      _spawnAccumulator += safeElapsed;
      while (_visibleNodeCount < graph.nodes.length &&
          _spawnAccumulator >= _spawnIntervalSeconds) {
        _spawnAccumulator -= _spawnIntervalSeconds;
        _visibleNodeCount++;
      }
    }

    var remainingFrameScale = safeElapsed * 60 * parameters.speed;
    while (_visibleNodeCount > 1 && remainingFrameScale > 0) {
      final step = math.min(1.0, remainingFrameScale);
      _integrateForces(step);
      remainingFrameScale -= step;
    }

    notifyListeners();
  }

  /// Applies parameter changes immediately without resetting the current run.
  void updateParameters(ForceGraphLayoutParameters nextParameters) {
    parameters = nextParameters;
    notifyListeners();
  }

  /// Stops physical forces while preserving manual drag.
  void stop() {
    if (_mode != GraphLayoutMode.forces || !_isRunning) {
      return;
    }
    _isRunning = false;
    notifyListeners();
  }

  /// Continues physical forces from the current continuous positions.
  void start() {
    if (_mode != GraphLayoutMode.forces || _isRunning) {
      return;
    }
    _isRunning = true;
    notifyListeners();
  }

  /// Restores deterministic initial positions with physical forces stopped.
  void reset() {
    for (var index = 0; index < graph.nodes.length; index++) {
      final nodeId = graph.nodes[index].id;
      _positions[nodeId] = _initialPosition(index);
      _velocities[nodeId] = Offset.zero;
    }
    _snappedCells = const {};
    _visibleNodeCount = graph.nodes.length;
    _spawnAccumulator = 0;
    _draggedNodeId = null;
    _mode = GraphLayoutMode.forces;
    _isRunning = false;
    notifyListeners();
  }

  /// Converts the current continuous layout into editable grid positions.
  void snapToGrid() {
    if (!canSnap) {
      return;
    }
    _snapAll();
    _mode = GraphLayoutMode.hexGrid;
    _isRunning = false;
    notifyListeners();
  }

  /// Returns to continuous editing from the current snapped positions.
  void returnToForces() {
    if (_mode != GraphLayoutMode.hexGrid) {
      return;
    }
    _snappedCells = const {};
    _draggedNodeId = null;
    _mode = GraphLayoutMode.forces;
    _isRunning = false;
    notifyListeners();
  }

  /// Starts manually positioning the selected node.
  void beginDrag(String nodeId) {
    _draggedNodeId = nodeId;
    _velocities[nodeId] = Offset.zero;
  }

  /// Moves the currently selected node to a continuous modal position.
  void updateDraggedNode(Offset position) {
    final nodeId = _draggedNodeId;
    if (nodeId == null) {
      return;
    }
    _positions[nodeId] = position;
    _velocities[nodeId] = Offset.zero;
    notifyListeners();
  }

  /// Releases a node and, after snapping, assigns its nearest free cell.
  void endDrag() {
    final nodeId = _draggedNodeId;
    if (nodeId == null) {
      return;
    }
    if (_mode == GraphLayoutMode.hexGrid) {
      final occupied = _snappedCells.entries
          .where((entry) => entry.key != nodeId)
          .map((entry) => entry.value)
          .toSet();
      final desired = HexLayoutSnapper.coordinateForLayoutPosition(
        _positions[nodeId]!,
        geometry,
      );
      final cell = HexLayoutSnapper.nearestFreeCell(desired, occupied);
      _snappedCells = {..._snappedCells, nodeId: cell};
      _positions[nodeId] = HexLayoutSnapper.layoutPositionForCell(
        cell,
        geometry,
      );
    }
    _draggedNodeId = null;
    notifyListeners();
  }

  /// Finds the topmost visible node using a uniform invisible hit target.
  String? hitTestNode(Offset position) {
    final radius = NoteverseGraphStyle.nodeHitRadius(
      baseRadius: NoteverseGraphStyle.layoutNodeRadius,
    );
    for (var index = _visibleNodeCount - 1; index >= 0; index--) {
      final nodeId = graph.nodes[index].id;
      if ((_positions[nodeId]! - position).distance <= radius) {
        return nodeId;
      }
    }
    return null;
  }

  /// Builds the immutable graph returned by the modal's Apply action.
  GraphData buildGraph() {
    if (!canApply) {
      throw StateError('The force-directed layout has not been snapped yet.');
    }
    return GraphData(
      graphId: graph.graphId,
      nodes: graph.nodes
          .map(
            (node) => GraphNode(
              id: node.id,
              title: node.title,
              sourcePath: node.sourcePath,
              cell: _snappedCells[node.id]!,
              markdownContent: node.markdownContent,
            ),
          )
          .toList(growable: false),
      edges: graph.edges,
    );
  }

  void _integrateForces(double frameScale) {
    final activeNodes = graph.nodes
        .take(_visibleNodeCount)
        .toList(growable: false);
    final forces = {for (final node in activeNodes) node.id: Offset.zero};

    for (var firstIndex = 0; firstIndex < activeNodes.length; firstIndex++) {
      final firstId = activeNodes[firstIndex].id;
      for (
        var secondIndex = firstIndex + 1;
        secondIndex < activeNodes.length;
        secondIndex++
      ) {
        final secondId = activeNodes[secondIndex].id;
        var delta = _positions[firstId]! - _positions[secondId]!;
        var distanceSquared = delta.distanceSquared;
        if (distanceSquared < 1) {
          final angle = (firstIndex + secondIndex + 1) * 2.399963;
          delta = Offset(math.cos(angle), math.sin(angle));
          distanceSquared = 1;
        }
        final distance = math.sqrt(distanceSquared);
        final force =
            delta /
            distance *
            (_baseRepulsionStrength * parameters.repulsion / distanceSquared);
        forces[firstId] = forces[firstId]! + force;
        forces[secondId] = forces[secondId]! - force;
      }
    }

    for (final edge in graph.edges) {
      if (!isVisible(edge.sourceNodeId) || !isVisible(edge.targetNodeId)) {
        continue;
      }
      final delta =
          _positions[edge.targetNodeId]! - _positions[edge.sourceNodeId]!;
      final distance = math.max(1.0, delta.distance);
      final force =
          delta /
          distance *
          ((distance - parameters.linkDistance) *
              _baseSpringStrength *
              parameters.attraction);
      forces[edge.sourceNodeId] = forces[edge.sourceNodeId]! + force;
      forces[edge.targetNodeId] = forces[edge.targetNodeId]! - force;
    }

    final retainedVelocity = (1 - parameters.damping).clamp(0.01, 0.99);
    final damping = math.pow(retainedVelocity, frameScale).toDouble();
    for (final node in activeNodes) {
      if (node.id == _draggedNodeId) {
        continue;
      }
      final position = _positions[node.id]!;
      final acceleration =
          forces[node.id]! -
          position * _baseCenteringStrength * parameters.centering;
      var velocity =
          (_velocities[node.id]! + acceleration * frameScale) * damping;
      if (velocity.distance > _maximumSpeed) {
        velocity = velocity / velocity.distance * _maximumSpeed;
      }
      _velocities[node.id] = velocity;
      _positions[node.id] = position + velocity * frameScale;
    }
  }

  void _snapAll() {
    final snapped = HexLayoutSnapper.snapAll(
      positions: _positions,
      geometry: geometry,
    );
    _snappedCells = snapped.cellsByNodeId;
    _positions
      ..clear()
      ..addAll(snapped.positionsByNodeId);
    for (final nodeId in _velocities.keys) {
      _velocities[nodeId] = Offset.zero;
    }
  }

  static Offset _initialPosition(int index) {
    final angle = index * 2.399963;
    final radius = 10 * math.sqrt(index + 1);
    return Offset(math.cos(angle) * radius, math.sin(angle) * radius);
  }
}
