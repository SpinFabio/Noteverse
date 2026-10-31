import 'package:flutter/widgets.dart';

import 'hex_coordinate.dart';

/// Converts flat-top axial cell coordinates to and from Cartesian world space.
class HexGridGeometry {
  const HexGridGeometry({required this.radius}) : assert(radius > 0);

  static const _sqrt3 = 1.7320508075688772;

  /// Circumradius, and therefore side length, of a hexagon at zoom `1`.
  final double radius;

  /// Returns the Cartesian world-space center of [coordinate].
  Offset centerOf(HexCoordinate coordinate) =>
      Offset(centerXOf(coordinate.q), centerYOf(coordinate.q, coordinate.r));

  /// Returns the Cartesian X center without allocating an [Offset].
  double centerXOf(int q) => radius * 1.5 * q;

  /// Returns the Cartesian Y center without allocating an [Offset].
  double centerYOf(int q, int r) => radius * _sqrt3 * (r + q / 2);

  /// Returns the fractional axial Q coordinate for a Cartesian X coordinate.
  double qAtX(double worldX) => (2 / 3) * worldX / radius;

  /// Returns the fractional axial R coordinate for a Cartesian position.
  double rAt(double worldX, double worldY) =>
      ((-1 / 3) * worldX + (_sqrt3 / 3) * worldY) / radius;

  /// Height of one flat-top hexagon at zoom `1`.
  double get height => radius * _sqrt3;

  /// Returns fractional axial coordinates for a Cartesian world position.
  ///
  /// Fractional coordinates are useful for viewport bounds and pointer input;
  /// persistent cell identities remain integer [HexCoordinate] values.
  Offset fractionalCoordinateAt(Offset worldPosition) {
    return Offset(
      qAtX(worldPosition.dx),
      rAt(worldPosition.dx, worldPosition.dy),
    );
  }

  /// Returns the nearest integer cell to a Cartesian world position.
  HexCoordinate coordinateAt(Offset worldPosition) {
    final fractional = fractionalCoordinateAt(worldPosition);
    var q = fractional.dx.round();
    var r = fractional.dy.round();
    final s = (-fractional.dx - fractional.dy).round();

    final qDifference = (q - fractional.dx).abs();
    final rDifference = (r - fractional.dy).abs();
    final sDifference = (s + fractional.dx + fractional.dy).abs();

    if (qDifference > rDifference && qDifference > sDifference) {
      q = -r - s;
    } else if (rDifference > sDifference) {
      r = -q - s;
    }

    return HexCoordinate(q, r);
  }
}
