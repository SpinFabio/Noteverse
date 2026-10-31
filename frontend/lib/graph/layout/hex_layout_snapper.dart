import 'dart:collection';
import 'dart:ui';

import '../../hex_coordinate.dart';
import '../../hex_grid_geometry.dart';

/// Result of assigning continuous node positions to unique hexagonal cells.
class SnappedGraphLayout {
  const SnappedGraphLayout({
    required this.cellsByNodeId,
    required this.positionsByNodeId,
  });

  final Map<String, HexCoordinate> cellsByNodeId;
  final Map<String, Offset> positionsByNodeId;
}

/// Converts a continuous force-directed layout into collision-free grid cells.
abstract final class HexLayoutSnapper {
  static const _directions = <HexCoordinate>[
    HexCoordinate(1, 0),
    HexCoordinate(1, -1),
    HexCoordinate(0, -1),
    HexCoordinate(-1, 0),
    HexCoordinate(-1, 1),
    HexCoordinate(0, 1),
  ];

  /// Centers [positions] on their centroid and assigns the nearest free cells.
  static SnappedGraphLayout snapAll({
    required Map<String, Offset> positions,
    required HexGridGeometry geometry,
  }) {
    if (positions.isEmpty) {
      return const SnappedGraphLayout(cellsByNodeId: {}, positionsByNodeId: {});
    }

    final centroid = _centroid(positions.values);
    final centeredEntries =
        positions.entries
            .map((entry) => MapEntry(entry.key, entry.value - centroid))
            .toList()
          ..sort((a, b) {
            final distanceOrder = a.value.distanceSquared.compareTo(
              b.value.distanceSquared,
            );
            return distanceOrder != 0 ? distanceOrder : a.key.compareTo(b.key);
          });

    final occupied = <HexCoordinate>{};
    final cells = <String, HexCoordinate>{};
    for (final entry in centeredEntries) {
      final desired = _coordinateForLayoutPosition(entry.value, geometry);
      final cell = nearestFreeCell(desired, occupied);
      occupied.add(cell);
      cells[entry.key] = cell;
    }

    final qMean =
        cells.values.fold<int>(0, (sum, cell) => sum + cell.q) / cells.length;
    final rMean =
        cells.values.fold<int>(0, (sum, cell) => sum + cell.r) / cells.length;
    final centerCell = _roundAxial(qMean, rMean);
    final centeredCells = <String, HexCoordinate>{
      for (final entry in cells.entries)
        entry.key: HexCoordinate(
          entry.value.q - centerCell.q,
          entry.value.r - centerCell.r,
        ),
    };

    return SnappedGraphLayout(
      cellsByNodeId: Map.unmodifiable(centeredCells),
      positionsByNodeId: Map.unmodifiable({
        for (final entry in centeredCells.entries)
          entry.key: layoutPositionForCell(entry.value, geometry),
      }),
    );
  }

  /// Finds the nearest unoccupied cell using a breadth-first hex search.
  static HexCoordinate nearestFreeCell(
    HexCoordinate desired,
    Set<HexCoordinate> occupied,
  ) {
    if (!occupied.contains(desired)) {
      return desired;
    }

    final queue = Queue<HexCoordinate>()..add(desired);
    final visited = <HexCoordinate>{desired};
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      for (final direction in _directions) {
        final candidate = HexCoordinate(
          current.q + direction.q,
          current.r + direction.r,
        );
        if (!visited.add(candidate)) {
          continue;
        }
        if (!occupied.contains(candidate)) {
          return candidate;
        }
        queue.add(candidate);
      }
    }

    throw StateError('Unable to find a free hexagonal cell.');
  }

  /// Converts a modal layout position to the nearest hexagonal cell.
  static HexCoordinate coordinateForLayoutPosition(
    Offset position,
    HexGridGeometry geometry,
  ) => _coordinateForLayoutPosition(position, geometry);

  /// Converts a grid cell to the modal's downward-positive Y coordinates.
  static Offset layoutPositionForCell(
    HexCoordinate cell,
    HexGridGeometry geometry,
  ) {
    final world = geometry.centerOf(cell);
    return Offset(world.dx, -world.dy);
  }

  static Offset _centroid(Iterable<Offset> positions) {
    var sum = Offset.zero;
    var count = 0;
    for (final position in positions) {
      sum += position;
      count++;
    }
    return sum / count.toDouble();
  }

  static HexCoordinate _coordinateForLayoutPosition(
    Offset position,
    HexGridGeometry geometry,
  ) => geometry.coordinateAt(Offset(position.dx, -position.dy));

  static HexCoordinate _roundAxial(double qValue, double rValue) {
    var q = qValue.round();
    var r = rValue.round();
    final s = (-qValue - rValue).round();
    final qDifference = (q - qValue).abs();
    final rDifference = (r - rValue).abs();
    final sDifference = (s + qValue + rValue).abs();

    if (qDifference > rDifference && qDifference > sDifference) {
      q = -r - s;
    } else if (rDifference > sDifference) {
      r = -q - s;
    }
    return HexCoordinate(q, r);
  }
}
